import 'package:flutter_test/flutter_test.dart';

import 'package:roleplay_chat/main.dart';

void main() {
  testWidgets('启动错误页显示可读信息', (tester) async {
    await tester.pumpWidget(const StartupErrorApp(message: '测试错误'));

    expect(find.text('启动失败\n测试错误'), findsOneWidget);
  });
}
