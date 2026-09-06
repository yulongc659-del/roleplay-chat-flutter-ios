import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

enum ApiProvider {
  openAI('OpenAI', 'https://api.openai.com/v1', 'gpt-4.1-mini'),
  deepSeek('DeepSeek', 'https://api.deepseek.com', 'deepseek-chat'),
  custom('自定义', '', '');

  const ApiProvider(this.label, this.defaultBaseUrl, this.defaultModel);
  final String label;
  final String defaultBaseUrl;
  final String defaultModel;
}

class SettingsController extends ChangeNotifier {
  SettingsController._(
    this._preferences,
    this._secureStorage, {
    required this.provider,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  final SharedPreferences _preferences;
  final FlutterSecureStorage _secureStorage;

  ApiProvider provider;
  String baseUrl;
  String model;
  String apiKey;

  static Future<SettingsController> load({
    SharedPreferences? preferences,
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final savedName = prefs.getString('api_provider');
    final provider =
        ApiProvider.values
            .where((item) => item.name == savedName)
            .firstOrNull ??
        ApiProvider.openAI;
    return SettingsController._(
      prefs,
      secureStorage,
      provider: provider,
      baseUrl: prefs.getString('api_base_url') ?? provider.defaultBaseUrl,
      model: prefs.getString('api_model') ?? provider.defaultModel,
      apiKey: await secureStorage.read(key: 'ai_api_key') ?? '',
    );
  }

  void useDefaults(ApiProvider value) {
    provider = value;
    baseUrl = value.defaultBaseUrl;
    model = value.defaultModel;
    notifyListeners();
  }

  Future<void> save({
    required ApiProvider newProvider,
    required String newBaseUrl,
    required String newModel,
    required String newApiKey,
  }) async {
    final cleanUrl = newBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final cleanModel = newModel.trim();
    final cleanKey = newApiKey.trim();
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('服务地址必须是有效的 HTTPS 地址');
    }
    if (cleanModel.isEmpty) throw const FormatException('模型名称不能为空');
    if (cleanKey.isEmpty) throw const FormatException('API Key 不能为空');

    provider = newProvider;
    baseUrl = cleanUrl;
    model = cleanModel;
    apiKey = cleanKey;
    await _preferences.setString('api_provider', provider.name);
    await _preferences.setString('api_base_url', baseUrl);
    await _preferences.setString('api_model', model);
    await _secureStorage.write(key: 'ai_api_key', value: apiKey);
    notifyListeners();
  }

  ApiConfiguration configuration() {
    if (apiKey.isEmpty) throw const FormatException('请先在设置中填写 API Key');
    return ApiConfiguration(apiKey: apiKey, baseUrl: baseUrl, model: model);
  }
}
