import '../models/chat_models.dart';
import '../models/persona.dart';

typedef ApiMessage = Map<String, String>;

class PromptBuilder {
  static String liveState([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour < 5) return '正在睡觉，若被叫醒会带着朦胧睡意回应';
    if (hour < 7) return '刚醒来，正在慢慢整理思绪';
    if (hour < 9) return '正在吃早餐并为一天做准备';
    if (hour < 12) return '正在专注处理上午的工作或学习';
    if (hour < 14) return '正在吃午饭或短暂休息';
    if (hour < 18) return '正在处理下午的工作或学习';
    if (hour < 20) return '正在吃晚饭，逐渐放松下来';
    if (hour < 23) return '正在享受晚间的私人时间';
    return '准备休息，说话比白天更轻、更慢';
  }

  static String system({
    required Persona persona,
    required RelationshipState relationship,
    required String memory,
  }) =>
      '''你正在扮演一个虚构角色，并与用户进行沉浸式对话。

【角色设定】
名字：${persona.name}
性格：${persona.personality}
说话风格：${persona.speakingStyle}
背景故事：${persona.background}

【当前关系】
${relationshipText(relationship)}
这些数值只用于调整亲疏、戒备和语气。除非用户明确询问，否则不要直接报出数值。

【长期记忆】
${memory.isEmpty ? '暂无长期记忆。' : memory}

【实时状态】
${liveState()}

始终保持角色一致性，自然回应用户。可以用简短动作描写增强氛围，但不要替用户决定行动、想法或感受。
长期记忆和关系状态是背景信息，不要生硬复述。若历史信息与用户当前明确纠正的内容冲突，以用户最新说法为准。''';

  static List<ApiMessage> relationshipEvaluation({
    required Persona persona,
    required RelationshipState state,
    required String user,
    required String assistant,
  }) => [
    {
      'role': 'system',
      'content':
          '你是角色关系变化评估器。根据一轮真实互动判断四项关系值变化。每项必须是 -5 到 5 的整数；普通闲聊通常变化 0 或 1，只有明显事件才使用较大幅度。熟悉度通常不会因负面互动下降；信任、好感可升降；冲突、欺骗或冒犯会提高芥蒂，真诚道歉和修复会降低芥蒂。只输出 JSON，不要输出解释。',
    },
    {
      'role': 'user',
      'content':
          '角色：${persona.name}\n性格：${persona.personality}\n当前数值：${relationshipText(state)}\n用户：$user\n${persona.name}：$assistant\n\n返回格式：{"familiarity":0,"trust":0,"affection":0,"grudge":0}',
    },
  ];

  static List<ApiMessage> memorySummary({
    required String existing,
    required List<ChatMessage> messages,
    required String personaName,
  }) {
    final transcript = messages
        .map(
          (message) =>
              '${message.role == MessageRole.user ? '用户' : personaName}：${message.content}',
        )
        .join('\n');
    return [
      {
        'role': 'system',
        'content':
            '你是长期记忆整理器。把已有记忆与新增对话合并为一段约 200 个中文字符的摘要。保留身份、偏好、承诺、重要事件、关系变化及未解决事项；删掉寒暄和重复信息。用第三人称、信息密集的客观文字，只输出摘要正文。不要编造。',
      },
      {
        'role': 'user',
        'content':
            '已有记忆：\n${existing.isEmpty ? '无' : existing}\n\n需要吸收的对话：\n$transcript',
      },
    ];
  }

  static String relationshipText(RelationshipState state) =>
      '熟悉度 ${state.familiarity}/100，信任感 ${state.trust}/100，好感度 ${state.affection}/100，芥蒂感 ${state.grudge}/100。';
}
