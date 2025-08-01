import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../domain/entities/search_result.dart';
import 'web_search_datasource.dart';

/// Advanced Web Scraper com múltiplas estratégias e técnicas anti-detecção
class AdvancedWebScraper implements WebSearchDataSource {
  final http.Client client;
  final List<String> _rotatingUserAgents;
  final Map<String, DateTime> _requestHistory = {};
  final Map<String, String> _contentCache = {};
  final Random _random = Random();

  AdvancedWebScraper({required this.client})
    : _rotatingUserAgents = [
        // Chrome/Chromium variants
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',

        // Firefox variants
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:123.0) Gecko/20100101 Firefox/123.0',
        'Mozilla/5.0 (X11; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0',

        // Safari variants
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1',

        // Edge variants
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0',

        // Opera variants
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 OPR/108.0.0.0',
      ];

  String get _randomUserAgent =>
      _rotatingUserAgents[_random.nextInt(_rotatingUserAgents.length)];

  Map<String, String> get _randomHeaders => {
    'User-Agent': _randomUserAgent,
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': _getRandomLanguage(),
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Cache-Control': 'max-age=0',
    'DNT': '1',
    'Sec-GPC': '1',
  };

  String _getRandomLanguage() {
    final languages = [
      'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
      'en-US,en;q=0.9,pt;q=0.8',
      'pt-PT,pt;q=0.9,en;q=0.8',
      'es-ES,es;q=0.9,pt;q=0.8,en;q=0.7',
    ];
    return languages[_random.nextInt(languages.length)];
  }

  /// Rate limiting and anti-detection
  Future<void> _respectRateLimit(String domain) async {
    final lastRequest = _requestHistory[domain];
    if (lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequest);
      const minDelay = Duration(milliseconds: 500);
      const maxDelay = Duration(seconds: 2);

      if (timeSinceLastRequest < minDelay) {
        final randomDelay = Duration(
          milliseconds:
              minDelay.inMilliseconds +
              _random.nextInt(
                maxDelay.inMilliseconds - minDelay.inMilliseconds,
              ),
        );
        await Future.delayed(randomDelay);
      }
    }
    _requestHistory[domain] = DateTime.now();
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final results = <SearchResult>[];
    final seenUrls = <String>{};

    // Estratégia paralela com fallback em cadeia
    final searchStrategies = [
      () => _advancedGoogleSearch(query),
      () => _advancedBingSearch(query),
      () => _advancedDuckDuckGoSearch(query),
      () => _searchStartPage(query),
      () => _searchYandex(query),
    ];

    // Executar buscas em paralelo com timeout
    final futures = <Future<List<SearchResult>>>[];
    for (final strategy in searchStrategies) {
      futures.add(
        strategy().timeout(
          const Duration(seconds: 10),
          onTimeout: () => <SearchResult>[],
        ),
      );
    }

    try {
      final allResults = await Future.wait(futures, eagerError: false);

      // Consolidar resultados únicos com pontuação
      final scoredResults = <SearchResult, double>{};

      for (int i = 0; i < allResults.length; i++) {
        final searchResults = allResults[i];
        final sourceWeight =
            1.0 - (i * 0.1); // Peso baseado na qualidade da fonte

        for (int j = 0; j < searchResults.length; j++) {
          final result = searchResults[j];
          if (!seenUrls.contains(result.url) && _isValidUrl(result.url)) {
            seenUrls.add(result.url);

            // Calcular pontuação baseada em posição e fonte
            final positionScore = 1.0 - (j * 0.05);
            final finalScore = sourceWeight * positionScore;

            scoredResults[result] = finalScore;
          }
        }
      }

      // Ordenar por pontuação e retornar os melhores
      final sortedResults =
          scoredResults.entries
              .where((entry) => entry.value > 0.3) // Filtro de qualidade mínima
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      results.addAll(
        sortedResults.take(query.maxResults).map((entry) => entry.key),
      );
    } catch (e) {
      // Fallback para busca sequencial se paralela falhar
      for (final strategy in searchStrategies) {
        try {
          final strategyResults = await strategy();
          for (final result in strategyResults) {
            if (!seenUrls.contains(result.url) && _isValidUrl(result.url)) {
              seenUrls.add(result.url);
              results.add(result);
              if (results.length >= query.maxResults) break;
            }
          }
          if (results.length >= query.maxResults) break;
        } catch (_) {
          continue;
        }
      }
    }

    return results.take(query.maxResults).toList();
  }

  Future<List<SearchResult>> _advancedGoogleSearch(SearchQuery query) async {
    await _respectRateLimit('google.com');

    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final searchUrl =
          'https://www.google.com/search?q=$encodedQuery&num=20&hl=pt-BR&lr=lang_pt|lang_en';

      final response = await client
          .get(Uri.parse(searchUrl), headers: _randomHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 429) {
        // Rate limited - wait and retry once
        await Future.delayed(Duration(seconds: 2 + _random.nextInt(3)));
        return [];
      }

      if (response.statusCode != 200) {
        throw Exception('Google search failed: ${response.statusCode}');
      }

      return _parseGoogleResults(response.body, query.formattedQuery);
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> _advancedBingSearch(SearchQuery query) async {
    await _respectRateLimit('bing.com');

    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final searchUrl =
          'https://www.bing.com/search?q=$encodedQuery&count=20&mkt=pt-BR';

      final response = await client
          .get(Uri.parse(searchUrl), headers: _randomHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('Bing search failed: ${response.statusCode}');
      }

      return _parseBingResults(response.body, query.formattedQuery);
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> _advancedDuckDuckGoSearch(
    SearchQuery query,
  ) async {
    await _respectRateLimit('duckduckgo.com');

    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final searchUrl =
          'https://html.duckduckgo.com/html/?q=$encodedQuery&kl=br-pt';

      final response = await client
          .get(Uri.parse(searchUrl), headers: _randomHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('DuckDuckGo search failed: ${response.statusCode}');
      }

      return _parseDuckDuckGoResults(response.body, query.formattedQuery);
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchStartPage(SearchQuery query) async {
    await _respectRateLimit('startpage.com');

    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final searchUrl =
          'https://www.startpage.com/sp/search?query=$encodedQuery&language=portuguese&num=20';

      final response = await client
          .get(Uri.parse(searchUrl), headers: _randomHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('StartPage search failed: ${response.statusCode}');
      }

      return _parseStartPageResults(response.body, query.formattedQuery);
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchYandex(SearchQuery query) async {
    await _respectRateLimit('yandex.com');

    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final searchUrl =
          'https://yandex.com/search/?text=$encodedQuery&lr=21621'; // lr=21621 is Brazil region

      final response = await client
          .get(Uri.parse(searchUrl), headers: _randomHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('Yandex search failed: ${response.statusCode}');
      }

      return _parseYandexResults(response.body, query.formattedQuery);
    } catch (e) {
      return [];
    }
  }

  List<SearchResult> _parseGoogleResults(String html, String query) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    // Múltiplos seletores para capturar diferentes layouts do Google
    final selectors = [
      'div.g:not(.g-blk)',
      'div[data-ved]',
      '.rc',
      '.g .rc',
      'div.MjjYud',
      'div.kvH3mc',
      'div.tF2Cxc',
      'div.yuRUbf',
    ];

    dom.Element? searchContainer;
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        searchContainer = elements.first;
        break;
      }
    }

    if (searchContainer == null) return results;

    final searchResults = document.querySelectorAll(
      'div.g, div.tF2Cxc, div.MjjYud',
    );

    for (final element in searchResults) {
      try {
        final titleElement =
            element.querySelector('h3') ??
            element.querySelector('a h3') ??
            element.querySelector('[role="heading"] h3');

        final linkElement =
            element.querySelector('a[href^="http"]') ??
            element.querySelector('a[href^="/url"]') ??
            element.querySelector('a[jsname]');

        final snippetElement =
            element.querySelector('.VwiC3b') ??
            element.querySelector('.s3v9rd') ??
            element.querySelector('.hgKElc') ??
            element.querySelector('[data-sncf]') ??
            element.querySelector('.IsZvec');

        if (titleElement != null && linkElement != null) {
          String url = linkElement.attributes['href'] ?? '';

          // Decodificar URLs do Google
          if (url.startsWith('/url?')) {
            final uri = Uri.parse('https://google.com$url');
            url = uri.queryParameters['url'] ?? url;
          }

          if (_isValidUrl(url)) {
            final title = _cleanText(titleElement.text);
            final snippet = _cleanText(snippetElement?.text ?? '');

            if (title.isNotEmpty && _isRelevant('$title $snippet', query)) {
              results.add(
                SearchResult(
                  title: title,
                  url: url,
                  snippet: snippet,
                  timestamp: DateTime.now(),
                ),
              );
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  List<SearchResult> _parseBingResults(String html, String query) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    final searchResults = document.querySelectorAll(
      '.b_algo, .b_algoheader, .b_algo_group',
    );

    for (final element in searchResults) {
      try {
        final titleElement =
            element.querySelector('h2 a') ??
            element.querySelector('.b_title a') ??
            element.querySelector('a[href^="http"]');

        final snippetElement =
            element.querySelector('.b_caption p') ??
            element.querySelector('.b_snippet') ??
            element.querySelector('.b_descript');

        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';

          if (_isValidUrl(url)) {
            final title = _cleanText(titleElement.text);
            final snippet = _cleanText(snippetElement?.text ?? '');

            if (title.isNotEmpty && _isRelevant('$title $snippet', query)) {
              results.add(
                SearchResult(
                  title: title,
                  url: url,
                  snippet: snippet,
                  timestamp: DateTime.now(),
                ),
              );
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  List<SearchResult> _parseDuckDuckGoResults(String html, String query) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    final searchResults = document.querySelectorAll(
      '.result, .web-result, .result--web',
    );

    for (final element in searchResults) {
      try {
        final titleElement =
            element.querySelector('.result__title a') ??
            element.querySelector('.result__a') ??
            element.querySelector('h2 a');

        final snippetElement =
            element.querySelector('.result__snippet') ??
            element.querySelector('.result__body');

        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';

          if (_isValidUrl(url)) {
            final title = _cleanText(titleElement.text);
            final snippet = _cleanText(snippetElement?.text ?? '');

            if (title.isNotEmpty && _isRelevant('$title $snippet', query)) {
              results.add(
                SearchResult(
                  title: title,
                  url: url,
                  snippet: snippet,
                  timestamp: DateTime.now(),
                ),
              );
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  List<SearchResult> _parseStartPageResults(String html, String query) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    final searchResults = document.querySelectorAll('.w-gl__result, .result');

    for (final element in searchResults) {
      try {
        final titleElement =
            element.querySelector('.w-gl__result-title a') ??
            element.querySelector('h3 a') ??
            element.querySelector('a[href^="http"]');

        final snippetElement =
            element.querySelector('.w-gl__description') ??
            element.querySelector('.result-desc');

        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';

          if (_isValidUrl(url)) {
            final title = _cleanText(titleElement.text);
            final snippet = _cleanText(snippetElement?.text ?? '');

            if (title.isNotEmpty && _isRelevant('$title $snippet', query)) {
              results.add(
                SearchResult(
                  title: title,
                  url: url,
                  snippet: snippet,
                  timestamp: DateTime.now(),
                ),
              );
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  List<SearchResult> _parseYandexResults(String html, String query) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    final searchResults = document.querySelectorAll('.serp-item, .organic');

    for (final element in searchResults) {
      try {
        final titleElement =
            element.querySelector('.organic__title a') ??
            element.querySelector('h2 a') ??
            element.querySelector('a[href^="http"]');

        final snippetElement =
            element.querySelector('.organic__text') ??
            element.querySelector('.text-container');

        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';

          if (_isValidUrl(url)) {
            final title = _cleanText(titleElement.text);
            final snippet = _cleanText(snippetElement?.text ?? '');

            if (title.isNotEmpty && _isRelevant('$title $snippet', query)) {
              results.add(
                SearchResult(
                  title: title,
                  url: url,
                  snippet: snippet,
                  timestamp: DateTime.now(),
                ),
              );
            }
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
      'google.com',
      'bing.com',
      'duckduckgo.com',
      'yandex.com',
      'facebook.com',
      'twitter.com',
      'instagram.com',
      'linkedin.com',
      'pinterest.com',
      'reddit.com',
    ];

    return !blockedDomains.any((domain) => url.contains(domain));
  }

  bool _isRelevant(String content, String query) {
    final queryWords = query.toLowerCase().split(' ');
    final contentLower = content.toLowerCase();

    var relevanceScore = 0;
    for (final word in queryWords) {
      if (word.length > 2 && contentLower.contains(word)) {
        relevanceScore++;
      }
    }

    return relevanceScore >= (queryWords.length * 0.3).ceil();
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\-.,!?():/]'), '')
        .trim();
  }

  @override
  Future<String> fetchPageContent(String url) async {
    // Cache check
    if (_contentCache.containsKey(url)) {
      return _contentCache[url]!;
    }

    try {
      final domain = Uri.parse(url).host;
      await _respectRateLimit(domain);

      final response = await client
          .get(
            Uri.parse(url),
            headers: {..._randomHeaders, 'Referer': 'https://www.google.com/'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to load page: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);

      // Remove unwanted elements more aggressively
      document
          .querySelectorAll(
            'script, style, nav, header, footer, .ads, .advertisement, '
            '.sidebar, .comments, .social-share, .popup, .modal, '
            '.newsletter, .subscription, .related-posts, .author-bio',
          )
          .forEach((element) => element.remove());

      // Smart content extraction
      dom.Element? mainContent;

      // Try various content selectors in order of preference
      final contentSelectors = [
        'article[role="main"]',
        'main article',
        '[role="main"]',
        'article',
        '.post-content',
        '.entry-content',
        '.content',
        '.main-content',
        '#content',
        '.post',
        '.entry',
        'main',
        '.container .row .col',
      ];

      for (final selector in contentSelectors) {
        mainContent = document.querySelector(selector);
        if (mainContent != null && mainContent.text.trim().length > 200) {
          break;
        }
      }

      mainContent ??= document.querySelector('body');

      String textContent = mainContent?.text ?? '';
      textContent = _cleanText(textContent);

      // Smart truncation - try to end at sentence boundaries
      const maxLength = 4000;
      if (textContent.length > maxLength) {
        final truncated = textContent.substring(0, maxLength);
        final lastSentence = truncated.lastIndexOf('.');
        if (lastSentence > maxLength * 0.8) {
          textContent = truncated.substring(0, lastSentence + 1);
        } else {
          textContent = '$truncated...';
        }
      }

      // Cache the result
      _contentCache[url] = textContent;

      // Limit cache size
      if (_contentCache.length > 50) {
        final oldestKey = _contentCache.keys.first;
        _contentCache.remove(oldestKey);
      }

      return textContent;
    } catch (e) {
      throw Exception('Error fetching page content: $e');
    }
  }

  /// Clear internal caches
  void clearCaches() {
    _contentCache.clear();
    _requestHistory.clear();
  }
}
