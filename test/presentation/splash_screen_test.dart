import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/presentation/pages/splash_screen.dart';

void main() {
  testWidgets('renders splash screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SplashScreen(),
    ));
    
    // Check if SplashScreen widget is rendered
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
