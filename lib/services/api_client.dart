import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'prompt_builder.dart';

class ApiConfiguration {
  const ApiConfiguration({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  final String apiKey;
  final String baseUrl;
  final String model;
}

abstract class AIClient {
  Future<String> complete(
    List<ApiMessage> messages, {
    double temperature = 0.8,
  });

  Future<Map<String, dynamic>> completeJson(List<ApiMessage> messages);
}

class HttpAIClient implements AIClient {
  HttpAIClient(this.configuration, {http.Client? client})
    : _client = client ?? http.Client();

  final ApiConfiguration configuration;
  final http.Client _client;

  @override
  Future<String> complete(
    List<ApiMessage> messages, {
    double temperature = 0.8,
  }) => _request(messages, temperature: temperature, jsonMode: false);

  @override
  Future<Map<String, dynamic>> completeJson(List<ApiMessage> messages) async {
    final text = await _request(messages, temperature: 0, jsonMode: true);
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    final candidate = start >= 0 && end > start
        ? text.substring(start, end + 1)
        : text;
    final decoded = jsonDecode(candidate);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('模型返回的 JSON 不是对象');
    }
    return decoded;
  }

  Future<String> _request(
    List<ApiMessage> messages, {
    required double temperature,
    required bool jsonMode,
  }) async {
    final base = configuration.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/chat/completions');
    final body = <String, dynamic>{
      'model': configuration.model,
      'messages': messages,
      'temperature': temperature,
      if (jsonMode) 'response_format': {'type': 'json_object'},
    };

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer ${configuration.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw Exception('API 请求超时');
    } catch (error) {
      throw Exception('网络请求失败：$error');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw Exception('服务器返回了无法解析的内容（HTTP ${response.statusCode}）');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Object? message;
      if (decoded is Map) {
        final errorBody = decoded['error'];
        if (errorBody is Map) message = errorBody['message'];
      }
      throw Exception(
        'API 错误 ${response.statusCode}：${message ?? decoded.toString()}',
      );
    }

    String? content;
    if (decoded is Map) {
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty && choices.first is Map) {
        final message = (choices.first as Map)['message'];
        if (message is Map && message['content'] is String) {
          content = message['content'] as String;
        }
      }
    }
    if (content is! String || content.trim().isEmpty) {
      throw Exception('模型返回了空内容');
    }
    return content.trim();
  }
}
