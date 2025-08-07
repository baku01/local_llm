/// DataSource simples para pesquisas web usando APIs públicas.
///
/// Implementa busca web usando serviços que fornecem APIs públicas
/// sem necessidade de autenticação, como uma alternativa mais confiável
/// ao web scraping direto.
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_query.dart';
import 'web_search_datasource.dart';

/// Implementação simples de busca web usando APIs públicas.
class SimpleWebSearchDataSource implements WebSearchDataSource {
  final http.Client _client;

  /// Timeout padrão para requisições
  static const Duration _defaultTimeout = Duration(seconds: 10);

  SimpleWebSearchDataSource({
    required http.Client client,
  }) : _client = client;

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    print('[SimpleWebSearch] Iniciando busca para: "${query.query}"');

    final results = <SearchResult>[];

    try {
      // Tentar múltiplas fontes de busca
      final searxResults = await _searchWithSearx(query);
      results.addAll(searxResults);

      if (results.isEmpty) {
        print(
            '[SimpleWebSearch] Searx não retornou resultados, tentando Wikipedia...');
        final wikiResults = await _searchWikipedia(query);
        results.addAll(wikiResults);
      }

      // Limitar ao número máximo de resultados solicitados
      final limitedResults = results.take(query.maxResults).toList();

      print(
          '[SimpleWebSearch] Busca concluída: ${limitedResults.length} resultados');
      return limitedResults;
    } catch (e) {
      print('[SimpleWebSearch] Erro na busca: $e');
      return [];
    }
  }

  @override
  Future<String> fetchPageContent(String url) async {
    print('[SimpleWebSearch] Buscando conteúdo de: $url');

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
        },
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        print('[SimpleWebSearch] Conteúdo obtido com sucesso');
        return _extractTextContent(response.body);
      } else {
        print(
            '[SimpleWebSearch] Erro ao buscar conteúdo: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('[SimpleWebSearch] Erro ao buscar conteúdo: $e');
      return '';
    }
  }

  /// Busca usando instâncias públicas do Searx
  Future<List<SearchResult>> _searchWithSearx(SearchQuery query) async {
    // Lista de instâncias públicas do Searx que não requerem autenticação
    final searxInstances = [
      'https://searx.be',
      'https://searx.info',
      'https://searx.xyz',
    ];

    for (final instance in searxInstances) {
      try {
        final encodedQuery = Uri.encodeComponent(query.query);
        final url =
            '$instance/search?q=$encodedQuery&format=json&language=pt-BR';

        print('[SimpleWebSearch] Tentando Searx em: $instance');

        final response = await _client.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
            'Accept': 'application/json',
          },
        ).timeout(_defaultTimeout);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = <SearchResult>[];

          if (data['results'] != null) {
            for (final result in data['results']) {
              results.add(SearchResult(
                title: result['title'] ?? '',
                snippet: result['content'] ?? '',
                url: result['url'] ?? '',
                timestamp: DateTime.now(),
                metadata: {'source': 'Searx'},
              ));

              if (results.length >= query.maxResults) break;
            }
          }

          if (results.isNotEmpty) {
            print(
                '[SimpleWebSearch] Searx retornou ${results.length} resultados');
            return results;
          }
        }
      } catch (e) {
        print('[SimpleWebSearch] Erro com instância $instance: $e');
        continue;
      }
    }

    return [];
  }

  /// Busca na Wikipedia em português
  Future<List<SearchResult>> _searchWikipedia(SearchQuery query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.query);
      final url = 'https://pt.wikipedia.org/w/api.php'
          '?action=query'
          '&list=search'
          '&srsearch=$encodedQuery'
          '&format=json'
          '&srlimit=${query.maxResults}'
          '&srprop=snippet|titlesnippet|size|wordcount|timestamp|redirecttitle';

      print('[SimpleWebSearch] Buscando na Wikipedia...');

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
          'Accept': 'application/json',
        },
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = <SearchResult>[];

        if (data['query']?['search'] != null) {
          for (final result in data['query']['search']) {
            final title = _removeHtmlTags(result['title'] ?? '');
            final snippet = _removeHtmlTags(result['snippet'] ?? '');
            final pageId = result['pageid'];

            results.add(SearchResult(
              title: title,
              snippet: snippet,
              url: 'https://pt.wikipedia.org/?curid=$pageId',
              timestamp: DateTime.now(),
              metadata: {'source': 'Wikipedia'},
            ));
          }
        }

        print(
            '[SimpleWebSearch] Wikipedia retornou ${results.length} resultados');
        return results;
      }
    } catch (e) {
      print('[SimpleWebSearch] Erro ao buscar na Wikipedia: $e');
    }

    return [];
  }

  /// Remove tags HTML básicas de uma string
  String _removeHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extrai texto limpo do HTML
  String _extractTextContent(String html) {
    try {
      // Remover scripts e styles
      html = html.replaceAll(
          RegExp(r'<script[^>]*>.*?</script>',
              multiLine: true, caseSensitive: false),
          '');
      html = html.replaceAll(
          RegExp(r'<style[^>]*>.*?</style>',
              multiLine: true, caseSensitive: false),
          '');

      // Extrair texto do body se existir
      final bodyMatch = RegExp(r'<body[^>]*>(.*?)</body>',
              multiLine: true, caseSensitive: false)
          .firstMatch(html);
      if (bodyMatch != null) {
        html = bodyMatch.group(1) ?? html;
      }

      // Remover todas as tags HTML
      final text = _removeHtmlTags(html);

      // Limitar o tamanho do conteúdo
      const maxLength = 5000;
      if (text.length > maxLength) {
        return text.substring(0, maxLength) + '...';
      }

      return text;
    } catch (e) {
      print('[SimpleWebSearch] Erro ao extrair texto: $e');
      return '';
    }
  }
}
