import 'dart:convert';

class Persona {
  const Persona({
    required this.name,
    required this.personality,
    required this.speakingStyle,
    required this.background,
  });

  final String name;
  final String personality;
  final String speakingStyle;
  final String background;

  factory Persona.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    String requiredText(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('persona.json 缺少有效字段：$key');
      }
      return value.trim();
    }

    return Persona(
      name: requiredText('name'),
      personality: requiredText('personality'),
      speakingStyle: requiredText('speaking_style'),
      background: requiredText('background'),
    );
  }
}
