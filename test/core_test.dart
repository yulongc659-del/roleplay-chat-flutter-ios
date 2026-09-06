import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:roleplay_chat/data/app_database.dart';
import 'package:roleplay_chat/models/chat_models.dart';
import 'package:roleplay_chat/models/persona.dart';
import 'package:roleplay_chat/services/api_client.dart';
import 'package:roleplay_chat/services/chat_service.dart';
import 'package:roleplay_chat/services/prompt_builder.dart';

const persona = Persona(
  name: '知夏',
  personality: '温和',
  speakingStyle: '简洁',
  background: '经营一家书店',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('关系变化限制单轮幅度和总值边界', () {
    const state = RelationshipState(
      familiarity: 99,
      trust: 1,
      affection: 50,
      grudge: 0,
    );
    final updated = state.apply(
      const RelationshipDelta(
        familiarity: 99,
        trust: -99,
        affection: 2,
        grudge: -2,
      ),
    );
    expect(updated.familiarity, 100);
    expect(updated.trust, 0);
    expect(updated.affection, 52);
    expect(updated.grudge, 0);
  });

  test('Live State 按小时返回状态', () {
    expect(PromptBuilder.liveState(DateTime(2026, 1, 1, 3)), contains('睡觉'));
    expect(PromptBuilder.liveState(DateTime(2026, 1, 1, 8)), contains('早餐'));
    expect(PromptBuilder.liveState(DateTime(2026, 1, 1, 21)), contains('晚间'));
  });

  test('超过20轮后压缩最早5轮并累积记忆', () async {
    final database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final fake = FakeAIClient();
    final service = ChatService(
      database: database,
      persona: persona,
      clientFactory: (_) => fake,
    );
    const configuration = ApiConfiguration(
      apiKey: 'test',
      baseUrl: 'https://example.invalid/v1',
      model: 'test-model',
    );

    for (var index = 0; index < 21; index++) {
      await service.send('消息 $index', configuration);
    }

    expect(await database.messageCount(), 32);
    expect(await database.memory(), contains('多轮交流'));
    final remaining = await database.allMessages();
    expect(remaining.first.content, '消息 5');
    expect((await database.relationship()).familiarity, 42);
    await database.close();
  });
}

class FakeAIClient implements AIClient {
  @override
  Future<String> complete(
    List<ApiMessage> messages, {
    double temperature = 0.8,
  }) async {
    if (messages.first['content']!.startsWith('你是长期记忆整理器')) {
      return '用户与角色已经进行过多轮交流，并逐渐熟悉彼此。';
    }
    return '你好，很高兴见到你。';
  }

  @override
  Future<Map<String, dynamic>> completeJson(List<ApiMessage> messages) async =>
      {'familiarity': 2, 'trust': 1, 'affection': 1, 'grudge': 0};
}
