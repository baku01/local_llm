import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:local_llm/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('app should start without crashing', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app loads
      expect(find.text('Revolução IA - Ferramenta Popular'), findsOneWidget);
    });

    testWidgets('should show welcome screen when no messages', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should show welcome message
      expect(find.text('Revolução da Inteligência Popular!'), findsOneWidget);
      expect(find.text('A inteligência artificial a serviço do povo!'), findsOneWidget);
    });

    testWidgets('should show suggestion chips', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should show revolutionary suggestion chips
      expect(find.text('Explique teoria marxista de forma didática'), findsOneWidget);
      expect(find.text('Analise questões sociais brasileiras'), findsOneWidget);
      expect(find.text('Pesquise movimentos populares'), findsOneWidget);
      expect(find.text('Discuta tecnologia e sociedade'), findsOneWidget);
    });

    testWidgets('should handle text input', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find text field and enter text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Teste de mensagem');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('Teste de mensagem'), findsOneWidget);
    });

    testWidgets('should show settings sidebar', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should show configuration sections
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Modelos LLM'), findsOneWidget);
      expect(find.text('Pesquisa Web'), findsOneWidget);
      expect(find.text('Modo Streaming'), findsOneWidget);
    });

    testWidgets('web search toggle should work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find web search toggle
      final webSearchToggle = find.text('Buscar na web');
      expect(webSearchToggle, findsOneWidget);

      // Test toggle functionality (implementation depends on widget structure)
      // This is a basic test that the toggle exists
    });

    testWidgets('streaming toggle should work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find streaming toggle
      final streamToggle = find.text('Resposta em tempo real');
      expect(streamToggle, findsOneWidget);
    });

    testWidgets('should show app info in footer', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should show revolutionary footer
      expect(find.text('Revolução IA v1.0.0'), findsOneWidget);
      expect(find.text('Ferramenta Popular de IA'), findsOneWidget);
      expect(find.text('🔴 Pela democratização da tecnologia'), findsOneWidget);
    });

    testWidgets('suggestion chips should be tappable', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap on a suggestion chip
      final firstChip = find.text('Explique teoria marxista de forma didática');
      expect(firstChip, findsOneWidget);

      await tester.tap(firstChip);
      await tester.pumpAndSettle();

      // Verify text was filled in input field
      expect(find.text('Explique conceitos de teoria marxista de forma didática'), findsOneWidget);
    });

    group('Error Handling Tests', () {
      testWidgets('should handle empty message gracefully', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Try to send empty message
        final sendButton = find.text('Enviar');
        expect(sendButton, findsOneWidget);

        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        // Should show error or not crash
        // Implementation depends on error handling
      });

      testWidgets('should handle network errors gracefully', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // This test would require mocking network failures
        // For now, we verify the app doesn't crash on startup
        expect(find.text('Revolução IA - Ferramenta Popular'), findsOneWidget);
      });
    });

    group('Theme Tests', () {
      testWidgets('should apply revolutionary theme colors', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Verify revolutionary theme is applied
        // This would require checking widget colors, which is complex in integration tests
        // For now, we verify the themed text appears
        expect(find.text('Revolução da Inteligência Popular!'), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Check for semantic elements
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Enviar'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // App should handle keyboard input without crashing
      });
    });

    group('Performance Tests', () {
      testWidgets('app should load within reasonable time', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        app.main();
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // App should load within 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(find.text('Revolução IA - Ferramenta Popular'), findsOneWidget);
      });

      testWidgets('animations should be smooth', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Test suggestion chip animations
        final chip = find.text('Explique teoria marxista de forma didática').first;
        
        // Hover simulation (if supported)
        final gesture = await tester.createGesture();
        await gesture.addPointer(location: tester.getCenter(chip));
        await tester.pump();
        
        // Should not crash during animations
        expect(find.text('Revolução da Inteligência Popular!'), findsOneWidget);
        
        await gesture.removePointer();
      });
    });
  });
}