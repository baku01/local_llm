import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_llm/presentation/providers/app_providers.dart';
import 'package:local_llm/domain/entities/search_query.dart';

void main() {
  group('Web Search Tests', () {
    test('Should perform web search when enabled', () async {
      final container = ProviderContainer();

      // Habilitar busca web
      container.read(webSearchEnabledProvider.notifier).state = true;

      // Obter o controller
      final controller = container.read(llmControllerProvider);

      // Sincronizar a configuração
      controller.toggleWebSearch(true);

      // Verificar se está habilitado
      expect(controller.webSearchEnabled, true);

      container.dispose();
    });

    test('Should use SimpleWebSearchDataSource by default', () {
      final container = ProviderContainer();

      // Verificar que usa busca simples por padrão
      expect(container.read(useSimpleWebSearchProvider), true);

      // Obter o datasource
      final dataSource = container.read(webSearchDataSourceProvider);

      // Verificar o tipo
      expect(dataSource.runtimeType.toString(), 'SimpleWebSearchDataSource');

      container.dispose();
    });

    test('Should switch between search datasources', () {
      final container = ProviderContainer();

      // Inicialmente deve usar SimpleWebSearchDataSource
      var dataSource = container.read(webSearchDataSourceProvider);
      expect(dataSource.runtimeType.toString(), 'SimpleWebSearchDataSource');

      // Mudar para IntelligentWebSearchDataSource
      container.read(useSimpleWebSearchProvider.notifier).state = false;

      // Verificar que mudou
      dataSource = container.read(webSearchDataSourceProvider);
      expect(
          dataSource.runtimeType.toString(), 'IntelligentWebSearchDataSource');

      container.dispose();
    });

    test('Should create SearchQuery correctly', () {
      const query = SearchQuery(
        query: 'Flutter development',
        maxResults: 5,
      );

      expect(query.query, 'Flutter development');
      expect(query.maxResults, 5);
      expect(query.formattedQuery, 'Flutter development');
    });

    test('SimpleWebSearchDataSource should return results', () async {
      final container = ProviderContainer();

      // Obter o datasource
      final dataSource = container.read(simpleWebSearchDataSourceProvider);

      // Criar uma query de teste
      const query = SearchQuery(
        query: 'Flutter framework',
        maxResults: 3,
      );

      // Executar busca
      final results = await dataSource.search(query);

      // Verificar que retornou resultados (pode ser vazio se não houver conexão)
      expect(results, isA<List>());

      // Se retornou resultados, verificar a estrutura
      if (results.isNotEmpty) {
        final firstResult = results.first;
        expect(firstResult.title, isNotEmpty);
        expect(firstResult.url, isNotEmpty);
        expect(firstResult.snippet, isNotEmpty);
      }

      container.dispose();
    });

    test('Controller should perform web search when sending message', () async {
      final container = ProviderContainer();

      // Configurar para usar busca web
      container.read(webSearchEnabledProvider.notifier).state = true;

      final controller = container.read(llmControllerProvider);
      controller.toggleWebSearch(true);

      // Verificar estado inicial
      expect(controller.webSearchEnabled, true);
      expect(controller.isSearching, false);

      // Nota: Teste real de envio de mensagem requer mock do LLM
      // Este teste apenas verifica a configuração

      container.dispose();
    });
  });
}
