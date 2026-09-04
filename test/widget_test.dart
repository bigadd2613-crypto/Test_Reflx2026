import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_login_app1/main.dart';

void main() {
  testWidgets('App opens the login screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('TIME TEST'), findsOneWidget);
    expect(find.text('เริ่มทดสอบ'), findsOneWidget);
  });
}
