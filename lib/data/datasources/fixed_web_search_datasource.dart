/// DataSource corrigido para pesquisas web com seletores atualizados.
/// 
/// Corrige o problema de zero resultados com:
/// - Seletores CSS atualizados para Google/Bing/DuckDuckGo
/// - Headers mais realísticos para evitar bloqueios
/// - Parsing mais robusto com fallbacks
/// - Debug logging para diagnóstico
library;

import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/foundation.dart';
import '../../domain/entities/search_result.dart';
import 'web_search_datasource.dart';

/// DataSource corrigido para pesquisas web funcionais
class FixedWebSearchDataSource implements WebSearchDataSource {
  final http.Client client;
  final List<String> _userAgents;
  final Map<String, DateTime> _requestHistory = {};
  final Random _random = Random();

  FixedWebSearchDataSource({required this.client})
    : _userAgents = [
        // User agents mais recentes e realísticos
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1.2 Safari/605.1.15',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
      ];

  String get _randomUserAgent =>
      _userAgents[_random.nextInt(_userAgents.length)];

  Map<String, String> get _realisticHeaders => {
    'User-Agent': _randomUserAgent,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept-Encoding': 'identity', // Evita compressão gzip que causa FormatException
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Cache-Control': 'max-age=0',
  };

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    debugPrint('🔍 Iniciando busca para: "${query.query}"');
    
    final results = <SearchResult>[];
    final seenUrls = <String>{};

    // Tentar múltiplas fontes
    final searchFunctions = [
      () => _searchGoogle(query),
      () => _searchBing(query),
      () => _searchDuckDuckGo(query),
    ];

    for (int i = 0; i < searchFunctions.length; i++) {
      try {
        final sourceResults = await searchFunctions[i]();
        debugPrint('📊 Fonte ${i + 1} retornou ${sourceResults.length} resultados');
        
        for (final result in sourceResults) {
          if (!seenUrls.contains(result.url) && _isValidUrl(result.url)) {
            seenUrls.add(result.url);
            results.add(result);
            
            if (results.length >= query.maxResults) break;
          }
        }
        
        if (results.length >= query.maxResults) break;
      } catch (e) {
        debugPrint('❌ Erro na fonte ${i + 1}: $e');
        continue;
      }
    }

    debugPrint('✅ Total de resultados únicos: ${results.length}');
    return results.take(query.maxResults).toList();
  }

  Future<List<SearchResult>> _searchGoogle(SearchQuery query) async {
    await _respectRateLimit('google.com');
    
    try {
      final encodedQuery = Uri.encodeComponent(query.query);
      final url = 'https://www.google.com/search?q=$encodedQuery&num=10&hl=pt-BR';
      
      debugPrint('🌐 Buscando no Google: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: _realisticHeaders,
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('📡 Google respondeu com status: ${response.statusCode}');
      
      if (response.statusCode == 429) {
        debugPrint('⚠️ Google rate limit atingido');
        await Future.delayed(Duration(seconds: 2 + _random.nextInt(3)));
        return [];
      }
      
      if (response.statusCode != 200) {
        debugPrint('❌ Google retornou status ${response.statusCode}');
        return [];
      }
      
      // Verificar se temos conteúdo válido
      String bodyContent;
      try {
        bodyContent = response.body;
        if (bodyContent.isEmpty) {
          debugPrint('⚠️ Google retornou corpo vazio');
          return [];
        }
      } catch (e) {
        debugPrint('💥 Erro no Google: $e');
        return [];
      }
      
      final results = _parseGoogleResults(bodyContent);
      debugPrint('🔍 Google: ${results.length} resultados parseados');
      return results;
      
    } catch (e) {
      debugPrint('💥 Erro no Google: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchBing(SearchQuery query) async {
    await _respectRateLimit('bing.com');
    
    try {
      final encodedQuery = Uri.encodeComponent(query.query);
      final url = 'https://www.bing.com/search?q=$encodedQuery&count=10&mkt=pt-BR';
      
      debugPrint('🌐 Buscando no Bing: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: _realisticHeaders,
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('📡 Bing respondeu com status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        debugPrint('❌ Bing retornou status ${response.statusCode}');
        return [];
      }
      
      // Verificar se temos conteúdo válido
      String bodyContent;
      try {
        bodyContent = response.body;
        if (bodyContent.isEmpty) {
          debugPrint('⚠️ Bing retornou corpo vazio');
          return [];
        }
      } catch (e) {
        debugPrint('💥 Erro no Bing: $e');
        return [];
      }
      
      final results = _parseBingResults(bodyContent);
      debugPrint('🔍 Bing: ${results.length} resultados parseados');
      return results;
      
    } catch (e) {
      debugPrint('💥 Erro no Bing: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchDuckDuckGo(SearchQuery query) async {
    await _respectRateLimit('duckduckgo.com');
    
    try {
      final encodedQuery = Uri.encodeComponent(query.query);
      final url = 'https://html.duckduckgo.com/html/?q=$encodedQuery&kl=br-pt';
      
      debugPrint('🌐 Buscando no DuckDuckGo: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: _realisticHeaders,
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('📡 DuckDuckGo respondeu com status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        debugPrint('❌ DuckDuckGo retornou status ${response.statusCode}');
        return [];
      }
      
      // Verificar se temos conteúdo válido
      String bodyContent;
      try {
        bodyContent = response.body;
        if (bodyContent.isEmpty) {
          debugPrint('⚠️ DuckDuckGo retornou corpo vazio');
          return [];
        }
      } catch (e) {
        debugPrint('💥 Erro no DuckDuckGo: $e');
        return [];
      }
      
      final results = _parseDuckDuckGoResults(bodyContent);
      debugPrint('🔍 DuckDuckGo: ${results.length} resultados parseados');
      return results;
      
    } catch (e) {
      debugPrint('💥 Erro no DuckDuckGo: $e');
      return [];
    }
  }

  List<SearchResult> _parseGoogleResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];
    
    // Seletores atualizados para o Google (2024)
    final possibleSelectors = [
      'div.g:not(.g-blk)',
      'div.tF2Cxc', 
      'div.MjjYud',
      'div.kvH3mc',
      'div.yuRUbf',
      'div[data-ved]',
      '.rc',
    ];
    
    for (final selector in possibleSelectors) {
      final elements = document.querySelectorAll(selector);
      debugPrint('🎯 Testando seletor "$selector": ${elements.length} elementos');
      
      if (elements.isNotEmpty) {
        for (final element in elements) {
          try {
            final result = _extractGoogleResult(element);
            if (result != null) {
              results.add(result);
            }
          } catch (e) {
            debugPrint('⚠️ Erro ao processar elemento: $e');
            continue;
          }
        }
        
        if (results.isNotEmpty) {
          debugPrint('✅ Seletor "$selector" funcionou! ${results.length} resultados');
          break;
        }
      }
    }
    
    return results;
  }

  SearchResult? _extractGoogleResult(element) {
    // Múltiplas tentativas para encontrar título
    final titleSelectors = [
      'h3',
      'a h3', 
      '[role="heading"] h3',
      '.LC20lb',
      '.DKV0Md',
    ];
    
    dynamic titleElement;
    for (final selector in titleSelectors) {
      titleElement = element.querySelector(selector);
      if (titleElement != null) break;
    }
    
    // Múltiplas tentativas para encontrar link
    final linkSelectors = [
      'a[href^="http"]',
      'a[href^="/url"]',
      'a[jsname]',
      'h3 a',
      '.yuRUbf a',
    ];
    
    dynamic linkElement;
    for (final selector in linkSelectors) {
      linkElement = element.querySelector(selector);
      if (linkElement != null) break;
    }
    
    // Múltiplas tentativas para encontrar snippet
    final snippetSelectors = [
      '.VwiC3b',
      '.s3v9rd', 
      '.hgKElc',
      '[data-sncf]',
      '.IsZvec',
      '.lEBKkf',
    ];
    
    dynamic snippetElement;
    for (final selector in snippetSelectors) {
      snippetElement = element.querySelector(selector);
      if (snippetElement != null) break;
    }
    
    if (titleElement != null && linkElement != null) {
      String url = linkElement.attributes['href'] ?? '';
      
      // Limpar URLs do Google
      if (url.startsWith('/url?')) {
        final uri = Uri.parse('https://google.com$url');
        url = uri.queryParameters['url'] ?? url;
      }
      
      if (_isValidUrl(url)) {
        final title = _cleanText(titleElement.text);
        final snippet = _cleanText(snippetElement?.text ?? '');
        
        debugPrint('🎯 Resultado encontrado: $title');
        
        return SearchResult(
          title: title,
          url: url,
          snippet: snippet,
          timestamp: DateTime.now(),
        );
      }
    }
    
    return null;
  }

  List<SearchResult> _parseBingResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];
    
    final searchResults = document.querySelectorAll('.b_algo, .b_algo_group, .b_algoheader');
    debugPrint('🎯 Bing: ${searchResults.length} elementos .b_algo encontrados');
    
    for (final element in searchResults) {
      try {
        final titleElement = element.querySelector('h2 a') ?? 
                           element.querySelector('.b_title a') ??
                           element.querySelector('a[href^="http"]');
        
        final snippetElement = element.querySelector('.b_caption p') ?? 
                             element.querySelector('.b_snippet') ??
                             element.querySelector('.b_descript');
        
        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';
          
          if (_isValidUrl(url)) {
            final title = _cleanText(titleElement.text);
            final snippet = _cleanText(snippetElement?.text ?? '');
            
            debugPrint('🎯 Bing resultado: $title');
            
            results.add(SearchResult(
              title: title,
              url: url,
              snippet: snippet,
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
    
    final searchResults = document.querySelectorAll('.result, .web-result, .result--web');
    debugPrint('🎯 DuckDuckGo: ${searchResults.length} elementos .result encontrados');
    
    for (final element in searchResults) {
      try {
        final titleElement = element.querySelector('.result__title a') ?? 
                           element.querySelector('.result__a') ??
                           element.querySelector('h2 a');
        
        final snippetElement = element.querySelector('.result__snippet') ?? 
                             element.querySelector('.result__body');
        
        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';
          
          if (_isValidUrl(url)) {
            final title = _cleanText(titleElement.text);
            final snippet = _cleanText(snippetElement?.text ?? '');
            
            debugPrint('🎯 DuckDuckGo resultado: $title');
            
            results.add(SearchResult(
              title: title,
              url: url,
              snippet: snippet,
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

  bool _isValidUrl(String url) {
    if (url.isEmpty || !url.startsWith('http')) return false;
    
    final blockedDomains = [
      'google.com', 'bing.com', 'duckduckgo.com', 'yandex.com',
      'facebook.com', 'twitter.com', 'instagram.com', 'linkedin.com'
    ];
    
    return !blockedDomains.any((domain) => url.contains(domain));
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\-.,!?():/àáâãéêíóôõúç]'), '')
        .trim();
  }

  Future<void> _respectRateLimit(String domain) async {
    final lastRequest = _requestHistory[domain];
    if (lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequest);
      const minDelay = Duration(milliseconds: 500);
      
      if (timeSinceLastRequest < minDelay) {
        final delay = minDelay - timeSinceLastRequest;
        debugPrint('⏳ Rate limit: aguardando ${delay.inMilliseconds}ms para $domain');
        await Future.delayed(delay);
      }
    }
    _requestHistory[domain] = DateTime.now();
  }

  @override
  Future<String> fetchPageContent(String url) async {
    try {
      await _respectRateLimit(Uri.parse(url).host);
      
      final response = await client.get(
        Uri.parse(url),
        headers: {..._realisticHeaders, 'Referer': 'https://www.google.com/'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
      
      final document = html_parser.parse(response.body);
      
      // Remover elementos indesejados
      document.querySelectorAll(
        'script, style, nav, header, footer, .ads, .advertisement, .sidebar'
      ).forEach((element) => element.remove());
      
      // Extrair conteúdo principal
      final mainContent = document.querySelector('main, article, .content, #content') ??
                         document.querySelector('body');
      
      final textContent = mainContent?.text ?? '';
      
      // Limitar tamanho
      const maxLength = 3000;
      if (textContent.length > maxLength) {
        return '${textContent.substring(0, maxLength)}...';
      }
      
      return _cleanText(textContent);
    } catch (e) {
      throw Exception('Error fetching page content: $e');
    }
  }
}