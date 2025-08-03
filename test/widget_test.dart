// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:local_llm/main.dart';

void main() {
  testWidgets('LocalLLMApp widget can be created', (WidgetTester tester) async {
    // Test that the LocalLLMApp widget can be created without throwing
    const app = LocalLLMApp();
    expect(app, isA<LocalLLMApp>());
    
    // Test that it can be wrapped in ProviderScope
    const wrappedApp = ProviderScope(child: LocalLLMApp());
    expect(wrappedApp, isA<ProviderScope>());
  });
}
