/// DataSource para pesquisas web usando diferentes provedores.
///
/// Implementa pesquisas web através de APIs públicas como DuckDuckGo,
/// com funcionalidades de scraping de conteúdo para enriquecer
/// as respostas dos modelos LLM com contexto web relevante.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_query.dart';

/// Interface abstrata para datasources de pesquisa web.
///
/// Define os contratos que devem ser implementados por qualquer
/// datasource que forneça funcionalidades de pesquisa web.
abstract class WebSearchDataSource {
  /// Realiza uma pesquisa web baseada na query fornecida.
  Future<List<SearchResult>> search(SearchQuery query);

  /// Busca e extrai o conteúdo de uma página web específica.
  Future<String> fetchPageContent(String url);
}

/// Implementação do datasource usando a API do DuckDuckGo.
///
/// Utiliza a API pública do DuckDuckGo para realizar pesquisas web
/// e extrai conteúdo de páginas usando web scraping avançado.
/// Inclui fallback para métodos mais simples quando necessário.
class DuckDuckGoSearchDataSource implements WebSearchDataSource {
  /// Cliente HTTP para realizar requisições.
  final http.Client client;

  /// Construtor que inicializa o cliente HTTP.
  DuckDuckGoSearchDataSource({required this.client});

  /// Realiza pesquisa web usando a API do DuckDuckGo.
  ///
  /// Utiliza a API Instant Answer do DuckDuckGo para obter resultados
  /// de pesquisa sem necessidade de API key. Processa tanto tópicos
  /// relacionados quanto definições diretas.
  ///
  /// [query] - Objeto de consulta com termo e parâmetros de busca
  ///
  /// Returns: Lista de [SearchResult] com os resultados encontrados
  ///
  /// Throws: Exception para falhas de rede ou parsing
  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    try {
      // Constrói URL da API DuckDuckGo Instant Answer
      final url = Uri.parse(
        'https://api.duckduckgo.com/?q=${Uri.encodeComponent(query.formattedQuery)}&format=json&no_html=1&skip_disambig=1',
      );

      final response = await client.get(url);

      if (response.statusCode != 200) {
        throw Exception('Falha na busca: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = <SearchResult>[];

      // Processar tópicos relacionados (resultados principais)
      if (data['RelatedTopics'] != null) {
        final topics = data['RelatedTopics'] as List;

        for (var topic in topics.take(query.maxResults)) {
          if (topic is Map<String, dynamic> && topic['Text'] != null) {
            results.add(
              SearchResult(
                title: _extractTitle(topic['Text'] as String),
                url: topic['FirstURL'] as String? ?? '',
                snippet: topic['Text'] as String,
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      }

      // Fallback: usar definição direta se não há tópicos relacionados
      if (results.isEmpty && data['Definition'] != null) {
        results.add(
          SearchResult(
            title: data['Heading'] as String? ?? query.query,
            url: data['DefinitionURL'] as String? ?? '',
            snippet: data['Definition'] as String,
            timestamp: DateTime.now(),
          ),
        );
      }

      return results;
    } catch (e) {
      throw Exception('Erro na pesquisa web: $e');
    }
  }

  /// Extrai o conteúdo de uma página web para enriquecer o contexto.
  ///
  /// Utiliza um scraper avançado como método principal, com fallback
  /// para parsing HTML simples em caso de falha. O conteúdo é formatado
  /// em markdown para melhor integração com os modelos LLM.
  ///
  /// [url] - URL da página a ser processada
  ///
  /// Returns: Conteúdo da página formatado em texto/markdown
  ///
  /// Throws: Exception para erros de rede ou parsing
  @override
  Future<String> fetchPageContent(String url) async {
    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar página: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);

      // Remover elementos não relacionados ao conteúdo principal
      document
          .querySelectorAll('script, style, nav, header, footer')
          .forEach((element) {
        element.remove();
      });

      final textContent = document.body?.text ?? '';

      // Limitar tamanho para o fallback (menor que o método principal)
      const maxLength = 2000;
      if (textContent.length > maxLength) {
        return '${textContent.substring(0, maxLength)}...';
      }

      return textContent;
    } catch (error) {
      throw Exception('Erro ao buscar conteúdo da página: $error');
    }
  }

  /// Extrai um título apropriado de um texto longo.
  ///
  /// Utiliza as primeiras palavras significativas do texto para
  /// criar um título conciso e representativo.
  ///
  /// [text] - Texto completo do qual extrair o título
  ///
  /// Returns: Título extraído, limitado a 8 palavras
  String _extractTitle(String text) {
    final words = text.split(' ');
    if (words.length <= 8) return text;
    return '${words.take(8).join(' ')}...';
  }
}
