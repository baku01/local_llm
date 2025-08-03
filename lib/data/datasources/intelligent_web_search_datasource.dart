/// DataSource inteligente para pesquisas web com análise de relevância.
/// 
/// Implementa pesquisas web adaptativas que analisam a qualidade e relevância
/// do conteúdo encontrado, continuando a busca até obter informações suficientes
/// e de qualidade para responder adequadamente à consulta do usuário.
library;

import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../../domain/entities/search_result.dart';
import 'web_search_datasource.dart';

/// DataSource que implementa busca web inteligente com análise de qualidade.
/// 
/// Características principais:
/// - Análise de relevância semântica do conteúdo
/// - Busca adaptativa até atingir threshold de qualidade
/// - Sistema de pontuação multi-critério
/// - Diversidade de fontes para evitar viés
/// - Rate limiting inteligente por domínio
/// - Cache de conteúdo com TTL
class IntelligentWebSearchDataSource implements WebSearchDataSource {
  final http.Client client;
  final List<String> _userAgents;
  final Map<String, DateTime> _requestHistory = {};
  final Map<String, CachedContent> _contentCache = {};
  final Random _random = Random();
  
  // Thresholds para análise de qualidade
  static const double _minRelevanceScore = 0.3;
  static const double _targetTotalScore = 2.0;
  static const int _maxResults = 15;
  static const int _minResults = 3;

  IntelligentWebSearchDataSource({required this.client})
    : _userAgents = [
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:123.0) Gecko/20100101 Firefox/123.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15',
      ];

  String get _randomUserAgent =>
      _userAgents[_random.nextInt(_userAgents.length)];

  Map<String, String> get _randomHeaders => {
    'User-Agent': _randomUserAgent,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept-Encoding': 'identity', // Remove gzip para evitar problemas de encoding
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'DNT': '1',
    'Sec-GPC': '1',
    'Cache-Control': 'max-age=0',
  };

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final searchContext = _analyzeQuery(query);
    final qualityResults = <QualifiedSearchResult>[];
    double totalQualityScore = 0.0;
    final seenUrls = <String>{};
    
    // Estratégias de busca ordenadas por prioridade
    final searchStrategies = [
      () => _searchGoogle(query, searchContext),
      () => _searchBing(query, searchContext),
      () => _searchDuckDuckGo(query, searchContext),
    ];

    // Executar buscas incrementalmente até obter qualidade suficiente
    for (int round = 0; round < 3 && totalQualityScore < _targetTotalScore; round++) {
      final roundResults = <QualifiedSearchResult>[];
      
      // Executar estratégias em paralelo para cada round
      final futures = searchStrategies.map((strategy) => 
        strategy().timeout(
          const Duration(seconds: 8),
          onTimeout: () => <SearchResult>[],
        )
      ).toList();

      try {
        final allResults = await Future.wait(futures, eagerError: false);
        
        // Processar resultados de cada fonte
        for (int sourceIndex = 0; sourceIndex < allResults.length; sourceIndex++) {
          final sourceResults = allResults[sourceIndex];
          final sourceWeight = 1.0 - (sourceIndex * 0.1); // Google > Bing > DuckDuckGo
          
          for (int resultIndex = 0; resultIndex < sourceResults.length; resultIndex++) {
            final result = sourceResults[resultIndex];
            
            if (seenUrls.contains(result.url) || !_isValidUrl(result.url)) {
              continue;
            }
            
            seenUrls.add(result.url);
            
            // Calcular score de qualidade
            final qualityScore = await _calculateQualityScore(
              result, 
              searchContext, 
              sourceWeight,
              resultIndex,
            );
            
            if (qualityScore.totalScore >= _minRelevanceScore) {
              roundResults.add(qualityScore);
            }
          }
        }
        
        // Ordenar por qualidade e adicionar os melhores
        roundResults.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        
        for (final qualifiedResult in roundResults) {
          if (qualityResults.length >= _maxResults) break;
          
          qualityResults.add(qualifiedResult);
          totalQualityScore += qualifiedResult.totalScore;
          
          // Verificar se já temos qualidade suficiente
          if (totalQualityScore >= _targetTotalScore && 
              qualityResults.length >= _minResults) {
            break;
          }
        }
        
      } catch (e) {
        // Continue para próxima estratégia em caso de erro
        continue;
      }
    }

    // Se ainda não temos qualidade suficiente, fazer buscas específicas
    if (totalQualityScore < _targetTotalScore && qualityResults.length < _minResults) {
      final supplementaryResults = await _performSupplementarySearch(
        query, 
        searchContext, 
        seenUrls,
      );
      qualityResults.addAll(supplementaryResults);
    }

    // Retornar resultados finais ordenados por qualidade
    qualityResults.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return qualityResults.take(query.maxResults).map((qr) => qr.result).toList();
  }

  SearchContext _analyzeQuery(SearchQuery query) {
    final keywords = _extractKeywords(query.query);
    final intent = _detectSearchIntent(query.query);
    final language = _detectLanguage(query.query);
    
    return SearchContext(
      keywords: keywords,
      intent: intent,
      language: language,
      originalQuery: query.query,
    );
  }

  List<String> _extractKeywords(String query) {
    // Palavras irrelevantes (stop words)
    final stopWords = {
      'o', 'os', 'as', 'um', 'uma', 'uns', 'umas', 'de', 'do', 'da', 'dos', 'das',
      'em', 'no', 'na', 'nos', 'nas', 'por', 'para', 'com', 'como', 'que', 'é', 'são',
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'from', 'up', 'about', 'into', 'through', 'during', 'before', 'after',
    };
    
    final words = query.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();
    
    // Ordenar por importância (palavras mais longas primeiro)
    words.sort((a, b) => b.length.compareTo(a.length));
    return words.take(10).toList();
  }

  SearchIntent _detectSearchIntent(String query) {
    final questionWords = ['como', 'quando', 'onde', 'por que', 'o que', 'qual', 'quem', 
                          'how', 'when', 'where', 'why', 'what', 'which', 'who'];
    final informationalWords = ['tutorial', 'guia', 'explicar', 'definição', 'conceito',
                               'tutorial', 'guide', 'explain', 'definition', 'concept'];
    final transactionalWords = ['comprar', 'preço', 'valor', 'download', 'instalar',
                               'buy', 'price', 'cost', 'download', 'install'];
    
    final lowerQuery = query.toLowerCase();
    
    if (questionWords.any((word) => lowerQuery.contains(word)) ||
        informationalWords.any((word) => lowerQuery.contains(word))) {
      return SearchIntent.informational;
    } else if (transactionalWords.any((word) => lowerQuery.contains(word))) {
      return SearchIntent.transactional;
    } else {
      return SearchIntent.navigational;
    }
  }

  String _detectLanguage(String query) {
    final portugueseWords = ['como', 'onde', 'quando', 'por', 'que', 'para', 'com', 'uma', 'dos'];
    final englishWords = ['how', 'where', 'when', 'why', 'what', 'with', 'the', 'and', 'for'];
    
    final lowerQuery = query.toLowerCase();
    final ptCount = portugueseWords.where((word) => lowerQuery.contains(word)).length;
    final enCount = englishWords.where((word) => lowerQuery.contains(word)).length;
    
    return ptCount > enCount ? 'pt' : 'en';
  }

  Future<QualifiedSearchResult> _calculateQualityScore(
    SearchResult result,
    SearchContext context,
    double sourceWeight,
    int position,
  ) async {
    double score = 0.0;
    final factors = <String, double>{};
    
    // 1. Relevância do título (peso: 0.3)
    final titleRelevance = _calculateTextRelevance(result.title, context);
    score += titleRelevance * 0.3;
    factors['title_relevance'] = titleRelevance;
    
    // 2. Relevância do snippet (peso: 0.2)
    final snippetRelevance = _calculateTextRelevance(result.snippet, context);
    score += snippetRelevance * 0.2;
    factors['snippet_relevance'] = snippetRelevance;
    
    // 3. Qualidade da URL (peso: 0.1)
    final urlQuality = _calculateUrlQuality(result.url);
    score += urlQuality * 0.1;
    factors['url_quality'] = urlQuality;
    
    // 4. Posição na fonte (peso: 0.1)
    final positionScore = 1.0 - (position * 0.05);
    score += positionScore * 0.1;
    factors['position_score'] = positionScore;
    
    // 5. Peso da fonte (peso: 0.1)
    score += sourceWeight * 0.1;
    factors['source_weight'] = sourceWeight;
    
    // 6. Análise de conteúdo (peso: 0.2) - se disponível
    try {
      final contentScore = await _analyzePageContent(result.url, context);
      score += contentScore * 0.2;
      factors['content_score'] = contentScore;
    } catch (e) {
      // Se não conseguir analisar o conteúdo, usar score neutro
      factors['content_score'] = 0.5;
    }
    
    return QualifiedSearchResult(
      result: result,
      totalScore: score,
      factors: factors,
    );
  }

  double _calculateTextRelevance(String text, SearchContext context) {
    if (text.isEmpty) return 0.0;
    
    final lowerText = text.toLowerCase();
    double relevance = 0.0;
    int keywordMatches = 0;
    
    // Verificar correspondência de palavras-chave
    for (final keyword in context.keywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        keywordMatches++;
        // Palavras-chave no início têm peso maior
        final index = lowerText.indexOf(keyword.toLowerCase());
        final positionBonus = index == 0 ? 0.2 : (index < 20 ? 0.1 : 0.0);
        relevance += (1.0 + positionBonus) / context.keywords.length;
      }
    }
    
    // Bonus por densidade de palavras-chave
    final keywordDensity = keywordMatches / context.keywords.length;
    relevance += keywordDensity * 0.3;
    
    return relevance.clamp(0.0, 1.0);
  }

  double _calculateUrlQuality(String url) {
    double quality = 0.5; // Base score
    
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();
      
      // Domínios de alta qualidade
      final highQualityDomains = [
        'wikipedia.org', 'github.com', 'stackoverflow.com', 'medium.com',
        'docs.google.com', 'developer.mozilla.org', 'w3schools.com',
        '.edu', '.gov', '.org'
      ];
      
      if (highQualityDomains.any((d) => domain.contains(d))) {
        quality += 0.3;
      }
      
      // Penalizar domínios suspeitos
      final lowQualityIndicators = [
        'blogspot.com', 'wordpress.com', 'wix.com', 'weebly.com'
      ];
      
      if (lowQualityIndicators.any((d) => domain.contains(d))) {
        quality -= 0.2;
      }
      
      // URLs com estrutura clara são melhores
      if (uri.pathSegments.length > 1 && uri.pathSegments.length < 6) {
        quality += 0.1;
      }
      
      // HTTPS é melhor
      if (uri.scheme == 'https') {
        quality += 0.1;
      }
      
    } catch (e) {
      quality = 0.2; // URL malformada
    }
    
    return quality.clamp(0.0, 1.0);
  }

  Future<double> _analyzePageContent(String url, SearchContext context) async {
    try {
      // Verificar cache primeiro
      final cached = _contentCache[url];
      if (cached != null && !cached.isExpired()) {
        return _scoreContent(cached.content, context);
      }
      
      // Rate limiting
      await _respectRateLimit(Uri.parse(url).host);
      
      final response = await client.get(
        Uri.parse(url),
        headers: _randomHeaders,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        return 0.3;
      }
      
      final content = _extractMainContent(response.body);
      
      // Cache o conteúdo
      _contentCache[url] = CachedContent(content, DateTime.now());
      _cleanupCache();
      
      return _scoreContent(content, context);
      
    } catch (e) {
      return 0.3; // Score neutro em caso de erro
    }
  }

  double _scoreContent(String content, SearchContext context) {
    if (content.isEmpty) return 0.0;
    
    final lowerContent = content.toLowerCase();
    double score = 0.0;
    
    // Verificar densidade de palavras-chave
    int totalMatches = 0;
    for (final keyword in context.keywords) {
      final matches = keyword.toLowerCase().allMatches(lowerContent).length;
      totalMatches += matches;
    }
    
    final contentLength = content.length;
    final keywordDensity = totalMatches / (contentLength / 100); // Por 100 caracteres
    
    // Score baseado na densidade (ideal entre 0.5% e 3%)
    if (keywordDensity >= 0.5 && keywordDensity <= 3.0) {
      score += 0.5;
    } else if (keywordDensity > 0.1) {
      score += 0.3;
    }
    
    // Bonus por comprimento adequado
    if (contentLength > 500 && contentLength < 5000) {
      score += 0.3;
    } else if (contentLength >= 200) {
      score += 0.1;
    }
    
    // Penalizar conteúdo muito repetitivo
    final uniqueWords = content.split(RegExp(r'\s+')).toSet().length;
    final totalWords = content.split(RegExp(r'\s+')).length;
    final diversity = uniqueWords / totalWords;
    
    if (diversity > 0.3) {
      score += 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }

  String _extractMainContent(String html) {
    final document = html_parser.parse(html);
    
    // Remover elementos indesejados
    document.querySelectorAll(
      'script, style, nav, header, footer, .ads, .advertisement, '
      '.sidebar, .comments, .social-share, .popup, .modal'
    ).forEach((element) => element.remove());
    
    // Tentar encontrar conteúdo principal
    final contentSelectors = [
      'article', 'main', '.content', '.post-content', '.entry-content',
      '#content', '.main-content', '.post', '.entry'
    ];
    
    for (final selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null && element.text.trim().length > 200) {
        return element.text.trim();
      }
    }
    
    // Fallback para body
    return document.querySelector('body')?.text.trim() ?? '';
  }

  Future<List<QualifiedSearchResult>> _performSupplementarySearch(
    SearchQuery query,
    SearchContext context,
    Set<String> seenUrls,
  ) async {
    final results = <QualifiedSearchResult>[];
    
    // Tentar buscas mais específicas
    final specificQueries = _generateSpecificQueries(context);
    
    for (final specificQuery in specificQueries.take(2)) {
      try {
        final searchResults = await _searchGoogle(
          SearchQuery(query: specificQuery, maxResults: 5),
          context,
        );
        
        for (final result in searchResults) {
          if (!seenUrls.contains(result.url) && _isValidUrl(result.url)) {
            seenUrls.add(result.url);
            
            final qualityScore = await _calculateQualityScore(
              result, 
              context, 
              0.8, // Peso um pouco menor para buscas supplementares
              0,
            );
            
            if (qualityScore.totalScore >= _minRelevanceScore) {
              results.add(qualityScore);
            }
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    return results;
  }

  List<String> _generateSpecificQueries(SearchContext context) {
    final queries = <String>[];
    
    // Combinar palavras-chave principais
    if (context.keywords.length >= 2) {
      queries.add('${context.keywords[0]} ${context.keywords[1]}');
    }
    
    // Adicionar contexto de intenção
    switch (context.intent) {
      case SearchIntent.informational:
        queries.add('${context.keywords.first} tutorial');
        queries.add('${context.keywords.first} explicação');
        break;
      case SearchIntent.transactional:
        queries.add('${context.keywords.first} como fazer');
        queries.add('${context.keywords.first} passo a passo');
        break;
      case SearchIntent.navigational:
        queries.add('${context.keywords.first} site oficial');
        break;
    }
    
    return queries;
  }

  Future<void> _respectRateLimit(String domain) async {
    final lastRequest = _requestHistory[domain];
    if (lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequest);
      const minDelay = Duration(milliseconds: 300);
      
      if (timeSinceLastRequest < minDelay) {
        await Future.delayed(minDelay - timeSinceLastRequest);
      }
    }
    _requestHistory[domain] = DateTime.now();
  }

  void _cleanupCache() {
    if (_contentCache.length > 100) {
      final expiredKeys = _contentCache.entries
          .where((entry) => entry.value.isExpired())
          .map((entry) => entry.key)
          .toList();
      
      for (final key in expiredKeys) {
        _contentCache.remove(key);
      }
      
      // Se ainda muito grande, remover os mais antigos
      if (_contentCache.length > 50) {
        final oldestKeys = _contentCache.keys.take(25).toList();
        for (final key in oldestKeys) {
          _contentCache.remove(key);
        }
      }
    }
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty || !url.startsWith('http')) return false;
    
    final blockedDomains = [
      'google.com', 'bing.com', 'duckduckgo.com', 'yandex.com',
      'facebook.com', 'twitter.com', 'instagram.com', 'linkedin.com'
    ];
    
    return !blockedDomains.any((domain) => url.contains(domain));
  }

  // Implementações dos métodos de busca específicos
  Future<List<SearchResult>> _searchGoogle(SearchQuery query, SearchContext context) async {
    await _respectRateLimit('google.com');
    
    try {
      final encodedQuery = Uri.encodeComponent(query.query);
      final url = 'https://www.google.com/search?q=$encodedQuery&num=10&hl=${context.language}';
      
      final response = await client.get(
        Uri.parse(url),
        headers: _randomHeaders,
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode != 200) return [];
      
      return _parseGoogleResults(response.body);
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchBing(SearchQuery query, SearchContext context) async {
    await _respectRateLimit('bing.com');
    
    try {
      final encodedQuery = Uri.encodeComponent(query.query);
      final market = context.language == 'pt' ? 'pt-BR' : 'en-US';
      final url = 'https://www.bing.com/search?q=$encodedQuery&count=10&mkt=$market';
      
      final response = await client.get(
        Uri.parse(url),
        headers: _randomHeaders,
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode != 200) return [];
      
      return _parseBingResults(response.body);
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchDuckDuckGo(SearchQuery query, SearchContext context) async {
    await _respectRateLimit('duckduckgo.com');
    
    try {
      final encodedQuery = Uri.encodeComponent(query.query);
      final region = context.language == 'pt' ? 'br-pt' : 'us-en';
      final url = 'https://html.duckduckgo.com/html/?q=$encodedQuery&kl=$region';
      
      final response = await client.get(
        Uri.parse(url),
        headers: _randomHeaders,
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode != 200) return [];
      
      return _parseDuckDuckGoResults(response.body);
    } catch (e) {
      return [];
    }
  }

  List<SearchResult> _parseGoogleResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];
    
    final searchResults = document.querySelectorAll('div.g, div.tF2Cxc, div.MjjYud');
    
    for (final element in searchResults) {
      try {
        final titleElement = element.querySelector('h3') ?? 
                           element.querySelector('a h3');
        final linkElement = element.querySelector('a[href^="http"]') ?? 
                          element.querySelector('a[href^="/url"]');
        final snippetElement = element.querySelector('.VwiC3b, .s3v9rd, .hgKElc, [data-sncf]');
        
        if (titleElement != null && linkElement != null) {
          String url = linkElement.attributes['href'] ?? '';
          
          if (url.startsWith('/url?')) {
            final uri = Uri.parse('https://google.com$url');
            url = uri.queryParameters['url'] ?? url;
          }
          
          if (_isValidUrl(url)) {
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
        final titleElement = element.querySelector('h2 a') ?? 
                           element.querySelector('.b_title a');
        final snippetElement = element.querySelector('.b_caption p') ?? 
                             element.querySelector('.b_snippet');
        
        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';
          
          if (_isValidUrl(url)) {
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
        final titleElement = element.querySelector('.result__title a') ?? 
                           element.querySelector('.result__a');
        final snippetElement = element.querySelector('.result__snippet') ?? 
                             element.querySelector('.result__body');
        
        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';
          
          if (_isValidUrl(url)) {
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
        .replaceAll(RegExp(r'[^\w\s\-.,!?():/]'), '')
        .trim();
  }

  @override
  Future<String> fetchPageContent(String url) async {
    try {
      final cached = _contentCache[url];
      if (cached != null && !cached.isExpired()) {
        return cached.content;
      }
      
      await _respectRateLimit(Uri.parse(url).host);
      
      final response = await client.get(
        Uri.parse(url),
        headers: {..._randomHeaders, 'Referer': 'https://www.google.com/'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
      
      final content = _extractMainContent(response.body);
      
      // Cache com TTL de 1 hora
      _contentCache[url] = CachedContent(content, DateTime.now());
      _cleanupCache();
      
      return content;
    } catch (e) {
      throw Exception('Error fetching page content: $e');
    }
  }
}

// Classes auxiliares
class SearchContext {
  final List<String> keywords;
  final SearchIntent intent;
  final String language;
  final String originalQuery;
  
  SearchContext({
    required this.keywords,
    required this.intent,
    required this.language,
    required this.originalQuery,
  });
}

enum SearchIntent { informational, transactional, navigational }

class QualifiedSearchResult {
  final SearchResult result;
  final double totalScore;
  final Map<String, double> factors;
  
  QualifiedSearchResult({
    required this.result,
    required this.totalScore,
    required this.factors,
  });
}

class CachedContent {
  final String content;
  final DateTime timestamp;
  static const Duration _ttl = Duration(hours: 1);
  
  CachedContent(this.content, this.timestamp);
  
  bool isExpired() {
    return DateTime.now().difference(timestamp) > _ttl;
  }
}