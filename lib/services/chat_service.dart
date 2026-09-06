import '../data/app_database.dart';
import '../models/chat_models.dart';
import '../models/persona.dart';
import 'api_client.dart';
import 'prompt_builder.dart';

class ChatResult {
  const ChatResult({
    required this.reply,
    required this.relationship,
    this.warnings = const [],
  });

  final String reply;
  final RelationshipState relationship;
  final List<String> warnings;
}

class ChatService {
  ChatService({
    required this.database,
    required this.persona,
    AIClient Function(ApiConfiguration)? clientFactory,
  }) : _clientFactory = clientFactory ?? HttpAIClient.new;

  final AppDatabase database;
  final Persona persona;
  final AIClient Function(ApiConfiguration) _clientFactory;

  static const maxTurns = 20;
  static const compactTurns = 5;

  Future<ChatResult> send(
    String userText,
    ApiConfiguration configuration,
  ) async {
    final cleanText = userText.trim();
    if (cleanText.isEmpty) throw const FormatException('消息不能为空');

    final client = _clientFactory(configuration);
    final state = await database.relationship();
    final memory = await database.memory();
    final messages = <ApiMessage>[
      {
        'role': 'system',
        'content': PromptBuilder.system(
          persona: persona,
          relationship: state,
          memory: memory,
        ),
      },
      ...(await database.recentMessages(
        turns: maxTurns,
      )).map((message) => message.toApiMessage()),
      {'role': 'user', 'content': cleanText},
    ];

    final reply = await client.complete(messages);
    await database.addTurn(cleanText, reply);

    final warnings = <String>[];
    var updatedState = state;
    try {
      final evaluation = await client.completeJson(
        PromptBuilder.relationshipEvaluation(
          persona: persona,
          state: state,
          user: cleanText,
          assistant: reply,
        ),
      );
      updatedState = state.apply(RelationshipDelta.fromJson(evaluation));
      await database.setRelationship(updatedState);
    } catch (error) {
      warnings.add('关系评估暂未更新：$error');
    }

    try {
      await _compactIfNeeded(client);
    } catch (error) {
      warnings.add('长期记忆暂未压缩：$error');
    }
    return ChatResult(
      reply: reply,
      relationship: updatedState,
      warnings: warnings,
    );
  }

  Future<void> _compactIfNeeded(AIClient client) async {
    if (await database.messageCount() <= maxTurns * 2) return;
    final oldest = await database.oldestMessages(compactTurns * 2);
    if (oldest.length < 2) return;
    final summary = await client.complete(
      PromptBuilder.memorySummary(
        existing: await database.memory(),
        messages: oldest,
        personaName: persona.name,
      ),
      temperature: 0.2,
    );
    await database.replaceMemory(summary, oldest);
  }
}
