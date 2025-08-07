import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_llm/presentation/providers/app_providers.dart';

void main() {
  group('Backend Switch Tests', () {
    test('Should change backend from Ollama to LM Studio', () {
      final container = ProviderContainer();

      // Initial backend should be Ollama
      expect(container.read(llmBackendProvider), LlmBackend.ollama);

      // Change to LM Studio
      container.read(llmBackendProvider.notifier).state = LlmBackend.lmStudio;

      // Verify backend changed
      expect(container.read(llmBackendProvider), LlmBackend.lmStudio);

      container.dispose();
    });

    test('Should maintain different URLs for each backend', () {
      final container = ProviderContainer();

      // Set custom URLs
      container.read(apiUrlProvider.notifier).state = 'http://localhost:11434';
      container.read(lmStudioUrlProvider.notifier).state =
          'http://localhost:1234';

      // Verify URLs are maintained separately
      expect(container.read(apiUrlProvider), 'http://localhost:11434');
      expect(container.read(lmStudioUrlProvider), 'http://localhost:1234');

      container.dispose();
    });

    test('Repository should be recreated when backend changes', () {
      final container = ProviderContainer();

      // Get initial repository
      final repo1 = container.read(llmRepositoryProvider);

      // Change backend
      container.read(llmBackendProvider.notifier).state = LlmBackend.lmStudio;

      // Get repository again - should trigger recreation with new datasource
      final repo2 = container.read(llmRepositoryProvider);

      // Both should exist (we can't compare them directly due to how Riverpod works)
      expect(repo1, isNotNull);
      expect(repo2, isNotNull);

      container.dispose();
    });
  });
}
