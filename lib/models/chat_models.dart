class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
  });

  final int id;
  final MessageRole role;
  final String content;

  Map<String, String> toApiMessage() => {'role': role.name, 'content': content};
}

enum MessageRole { user, assistant }

class RelationshipState {
  const RelationshipState({
    this.familiarity = 0,
    this.trust = 0,
    this.affection = 0,
    this.grudge = 0,
  });

  final int familiarity;
  final int trust;
  final int affection;
  final int grudge;

  RelationshipState apply(RelationshipDelta delta) {
    int adjusted(int current, int change) =>
        (current + change.clamp(-5, 5)).clamp(0, 100);
    return RelationshipState(
      familiarity: adjusted(familiarity, delta.familiarity),
      trust: adjusted(trust, delta.trust),
      affection: adjusted(affection, delta.affection),
      grudge: adjusted(grudge, delta.grudge),
    );
  }
}

class RelationshipDelta {
  const RelationshipDelta({
    required this.familiarity,
    required this.trust,
    required this.affection,
    required this.grudge,
  });

  final int familiarity;
  final int trust;
  final int affection;
  final int grudge;

  factory RelationshipDelta.fromJson(Map<String, dynamic> json) {
    int value(String key) {
      final raw = json[key];
      if (raw is! num) throw FormatException('$key 不是数字');
      return raw.toInt().clamp(-5, 5);
    }

    return RelationshipDelta(
      familiarity: value('familiarity'),
      trust: value('trust'),
      affection: value('affection'),
      grudge: value('grudge'),
    );
  }
}
