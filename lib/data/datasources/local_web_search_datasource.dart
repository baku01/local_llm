import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../domain/entities/search_result.dart';
import 'web_search_datasource.dart';

class LocalWebSearchDataSource implements WebSearchDataSource {
  final http.Client client;
  final List<String> _userAgents = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1.2 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
  ];

  LocalWebSearchDataSource({required this.client});

  String get _randomUserAgent => _userAgents[Random().nextInt(_userAgents.length)];

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final results = <SearchResult>[];
    
    try {
      // Tentar múltiplas fontes de pesquisa
      final futures = [
        _searchGoogle(query),
        _searchBing(query),
        _searchDuckDuckGo(query),
      ];
      
      final allResults = await Future.wait(futures, eagerError: false);
      
      // Combinar resultados únicos
      final seenUrls = <String>{};
      for (final searchResults in allResults) {
        for (final result in searchResults) {
          if (!seenUrls.contains(result.url) && result.url.isNotEmpty) {
            seenUrls.add(result.url);
            results.add(result);
            if (results.length >= query.maxResults) break;
          }
        }
        if (results.length >= query.maxResults) break;
      }
      
      return results.take(query.maxResults).toList();
    } catch (e) {
      // print('Erro na pesquisa web local: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchGoogle(SearchQuery query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final url = 'https://www.google.com/search?q=$encodedQuery&num=10';
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _randomUserAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Google search failed: ${response.statusCode}');
      }

      return _parseGoogleResults(response.body);
    } catch (e) {
      // print('Erro no Google search: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchBing(SearchQuery query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final url = 'https://www.bing.com/search?q=$encodedQuery&count=10';
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _randomUserAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Bing search failed: ${response.statusCode}');
      }

      return _parseBingResults(response.body);
    } catch (e) {
      // print('Erro no Bing search: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchDuckDuckGo(SearchQuery query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final url = 'https://html.duckduckgo.com/html/?q=$encodedQuery';
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _randomUserAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('DuckDuckGo search failed: ${response.statusCode}');
      }

      return _parseDuckDuckGoResults(response.body);
    } catch (e) {
      // print('Erro no DuckDuckGo search: $e');
      return [];
    }
  }

  List<SearchResult> _parseGoogleResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    // Seletores para resultados do Google
    final searchResults = document.querySelectorAll('div.g, div[data-ved]');
    
    for (final element in searchResults) {
      try {
        final titleElement = element.querySelector('h3') ?? element.querySelector('a h3');
        final linkElement = element.querySelector('a[href^="http"]') ?? element.querySelector('a[href^="/url"]');
        final snippetElement = element.querySelector('div[data-sncf], .VwiC3b, .s3v9rd, .hgKElc');

        if (titleElement != null && linkElement != null) {
          String url = linkElement.attributes['href'] ?? '';
          
          // Limpar URLs do Google
          if (url.startsWith('/url?')) {
            final uri = Uri.parse('https://google.com$url');
            url = uri.queryParameters['url'] ?? url;
          }
          
          if (url.startsWith('http') && !url.contains('google.com')) {
            results.add(SearchResult(
              title: _cleanText(titleElement.text),
              url: url,
              snippet: _cleanText(snippetElement?.text ?? ''),
              timestamp: DateTime.now(),
            ));
          }
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  List<SearchResult> _parseBingResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    final searchResults = document.querySelectorAll('.b_algo, .b_algo_group');
    
    for (final element in searchResults) {
      try {
        final titleElement = element.querySelector('h2 a, .b_title a');
        final snippetElement = element.querySelector('.b_caption p, .b_snippet');

        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';
          
          if (url.startsWith('http') && !url.contains('bing.com')) {
            results.add(SearchResult(
              title: _cleanText(titleElement.text),
              url: url,
              snippet: _cleanText(snippetElement?.text ?? ''),
              timestamp: DateTime.now(),
            ));
          }
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  List<SearchResult> _parseDuckDuckGoResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    final searchResults = document.querySelectorAll('.result, .web-result');
    
    for (final element in searchResults) {
      try {
        final titleElement = element.querySelector('.result__title a, .result__a');
        final snippetElement = element.querySelector('.result__snippet, .result__body');

        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';
          
          if (url.startsWith('http')) {
            results.add(SearchResult(
              title: _cleanText(titleElement.text),
              url: url,
              snippet: _cleanText(snippetElement?.text ?? ''),
              timestamp: DateTime.now(),
            ));
          }
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\-.,!?()]'), '')
        .trim();
  }

  @override
  Future<String> fetchPageContent(String url) async {
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _randomUserAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar página: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);
      
      // Remover elementos desnecessários
      document.querySelectorAll('script, style, nav, header, footer, .ads, .advertisement, .sidebar').forEach((element) {
        element.remove();
      });

      // Tentar extrair conteúdo principal
      dom.Element? mainContent = document.querySelector('main, article, .content, .post, .entry');
      mainContent ??= document.querySelector('body');

      final textContent = mainContent?.text ?? '';
      
      // Limitar o tamanho do conteúdo
      const maxLength = 3000;
      if (textContent.length > maxLength) {
        return '${textContent.substring(0, maxLength)}...';
      }
      
      return _cleanText(textContent);
    } catch (e) {
      throw Exception('Erro ao buscar conteúdo da página: $e');
    }
  }
}