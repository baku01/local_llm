import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/presentation/pages/splash_screen.dart';

void main() {
  testWidgets('renders progress indicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
