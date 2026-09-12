import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_database.dart';
import 'models/persona.dart';
import 'screens/chat_screen.dart';
import 'services/chat_service.dart';
import 'services/settings_controller.dart';
import 'ui/app_theme.dart';
import 'ui/glass_components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final persona = Persona.fromJsonString(
      await rootBundle.loadString('assets/persona.json'),
    );
    final database = await AppDatabase.open();
    final settings = await SettingsController.load();
    runApp(
      RoleplayApp(persona: persona, database: database, settings: settings),
    );
  } catch (error) {
    runApp(StartupErrorApp(message: error.toString()));
  }
}

class RoleplayApp extends StatelessWidget {
  const RoleplayApp({
    super.key,
    required this.persona,
    required this.database,
    required this.settings,
  });

  final Persona persona;
  final AppDatabase database;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roleplay Chat',
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: ChatScreen(
        persona: persona,
        database: database,
        settings: settings,
        service: ChatService(database: database, persona: persona),
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackdrop(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    borderRadius: 26,
                    child: Text(
                      '启动失败\n$message',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
