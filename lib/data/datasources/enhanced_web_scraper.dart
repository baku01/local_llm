import 'dart:convert';
import 'dart:collection';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:beautiful_soup_dart/beautiful_soup.dart';

class EnhancedWebScraper {
  final Dio _dio;
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  EnhancedWebScraper() : _dio = Dio() {
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/118.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
      followRedirects: true,
      maxRedirects: 5,
    );

    // Add interceptors for better error handling and retries
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Log error for debugging
          handler.next(error);
        },
        onRequest: (options, handler) {
          // Log request for debugging
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response for debugging
          handler.next(response);
        },
      ),
    );
  }

  /// Enhanced web scraping with multiple parsing strategies
  Future<List<ScrapedContent>> scrapeMultipleUrls(
    List<String> urls, {
    int maxResults = 10,
    Duration? timeout,
    Map<String, String>? customHeaders,
  }) async {
    final results = <ScrapedContent>[];
    final semaphore = Semaphore(3); // Limit concurrent requests

    final futures = urls.take(maxResults).map((url) async {
      await semaphore.acquire();
      try {
        final content = await scrapeUrl(
          url,
          timeout: timeout,
          customHeaders: customHeaders,
        );
        if (content != null) {
          results.add(content);
        }
      } finally {
        semaphore.release();
      }
    });

    await Future.wait(futures);
    return results;
  }

  /// Advanced single URL scraping with multiple extraction methods
  Future<ScrapedContent?> scrapeUrl(
    String url, {
    Duration? timeout,
    Map<String, String>? customHeaders,
    int retryCount = 0,
  }) async {
    if (retryCount >= _maxRetries) {
      return null;
    }

    try {
      // Add custom headers if provided
      if (customHeaders != null) {
        _dio.options.headers.addAll(customHeaders);
      }

      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: timeout ?? _timeout,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return _extractContentFromHtml(url, response.data);
      }
    } on DioException catch (e) {
      // Retry on timeout or connection errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return scrapeUrl(url, timeout: timeout, customHeaders: customHeaders, retryCount: retryCount + 1);
      }
    } catch (e) {
      // Handle unexpected errors
    }

    return null;
  }

  /// Extract content using multiple parsing strategies
  ScrapedContent _extractContentFromHtml(String url, String html) {
    final document = html_parser.parse(html);
    final beautifulSoup = BeautifulSoup(html);
    
    // Strategy 1: Use Beautiful Soup for robust extraction
    final title = _extractTitle(beautifulSoup, document);
    final description = _extractDescription(beautifulSoup, document);
    final mainContent = _extractMainContent(beautifulSoup, document);
    final metadata = _extractMetadata(beautifulSoup, document);
    final links = _extractLinks(beautifulSoup, document, url);
    final images = _extractImages(beautifulSoup, document, url);

    return ScrapedContent(
      url: url,
      title: title,
      description: description,
      content: mainContent,
      metadata: metadata,
      links: links,
      images: images,
      scrapedAt: DateTime.now(),
    );
  }

  String _extractTitle(BeautifulSoup soup, html_dom.Document document) {
    // Try multiple selectors for title
    final titleSelectors = [
      'title',
      'h1',
      '[property="og:title"]',
      '[name="twitter:title"]',
      '.title',
      '.headline',
      '.post-title',
    ];

    for (final selector in titleSelectors) {
      try {
        final element = soup.find(selector);
        if (element != null) {
          final title = element.getText().trim();
          if (title.isNotEmpty) {
            return _cleanText(title);
          }
        }
      } catch (e) {
        continue;
      }
    }

    // Fallback to document title
    final titleElement = document.querySelector('title');
    return titleElement?.text.trim() ?? 'Sem título';
  }

  String _extractDescription(BeautifulSoup soup, html_dom.Document document) {
    final descriptionSelectors = [
      '[name="description"]',
      '[property="og:description"]',
      '[name="twitter:description"]',
      '.description',
      '.excerpt',
      '.summary',
    ];

    for (final selector in descriptionSelectors) {
      try {
        final element = soup.find(selector);
        if (element != null) {
          final content = element.attributes['content'] ?? element.getText();
          if (content.trim().isNotEmpty) {
            return _cleanText(content.trim());
          }
        }
      } catch (e) {
        continue;
      }
    }

    return '';
  }

  String _extractMainContent(BeautifulSoup soup, html_dom.Document document) {
    // Content extraction strategies in order of preference
    final contentSelectors = [
      'main',
      'article',
      '.content',
      '.post-content',
      '.entry-content',
      '.article-content',
      '.main-content',
      '#content',
      '.container',
    ];

    for (final selector in contentSelectors) {
      try {
        final element = soup.find(selector);
        if (element != null) {
          final content = _extractTextContent(element);
          if (content.length > 100) { // Minimum content length
            return content;
          }
        }
      } catch (e) {
        continue;
      }
    }

    // Fallback: extract from body but remove common non-content elements
    try {
      final body = soup.find('body');
      if (body != null) {
        // Remove navigation, ads, footer, etc.
        final elementsToRemove = [
          'nav', 'header', 'footer', '.nav', '.navigation',
          '.menu', '.sidebar', '.ads', '.advertisement',
          '.social', '.share', '.comments', 'script', 'style'
        ];

        for (final selectorToRemove in elementsToRemove) {
          final elements = body.findAll(selectorToRemove);
          for (final element in elements) {
            element.extract();
          }
        }

        return _extractTextContent(body);
      }
    } catch (e) {
      // Handle error extracting body content
    }

    return '';
  }

  String _extractTextContent(dynamic element) {
    if (element == null) return '';
    
    try {
      // Get text and clean it
      final text = element.getText() as String? ?? '';
      return _cleanText(text);
    } catch (e) {
      return '';
    }
  }

  Map<String, String> _extractMetadata(BeautifulSoup soup, html_dom.Document document) {
    final metadata = <String, String>{};

    // Extract meta tags
    final metaTags = soup.findAll('meta');
    for (final meta in metaTags) {
      final name = meta.attributes['name'] ?? meta.attributes['property'] ?? '';
      final content = meta.attributes['content'] ?? '';
      
      if (name.isNotEmpty && content.isNotEmpty) {
        metadata[name] = content;
      }
    }

    return metadata;
  }

  List<String> _extractLinks(BeautifulSoup soup, html_dom.Document document, String baseUrl) {
    final links = <String>{};
    
    try {
      final linkElements = soup.findAll('a');
      for (final link in linkElements) {
        final href = link.attributes['href'];
        if (href != null && href.isNotEmpty) {
          final absoluteUrl = _makeAbsoluteUrl(href, baseUrl);
          if (absoluteUrl != null) {
            links.add(absoluteUrl);
          }
        }
      }
    } catch (e) {
      // Handle error extracting links
    }

    return links.toList();
  }

  List<String> _extractImages(BeautifulSoup soup, html_dom.Document document, String baseUrl) {
    final images = <String>{};
    
    try {
      final imgElements = soup.findAll('img');
      for (final img in imgElements) {
        final src = img.attributes['src'] ?? img.attributes['data-src'];
        if (src != null && src.isNotEmpty) {
          final absoluteUrl = _makeAbsoluteUrl(src, baseUrl);
          if (absoluteUrl != null) {
            images.add(absoluteUrl);
          }
        }
      }
    } catch (e) {
      // Handle error extracting images
    }

    return images.toList();
  }

  String? _makeAbsoluteUrl(String url, String baseUrl) {
    try {
      final base = Uri.parse(baseUrl);
      final resolved = base.resolve(url);
      return resolved.toString();
    } catch (e) {
      return null;
    }
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }

  void dispose() {
    _dio.close();
  }
}

class ScrapedContent {
  final String url;
  final String title;
  final String description;
  final String content;
  final Map<String, String> metadata;
  final List<String> links;
  final List<String> images;
  final DateTime scrapedAt;

  const ScrapedContent({
    required this.url,
    required this.title,
    required this.description,
    required this.content,
    required this.metadata,
    required this.links,
    required this.images,
    required this.scrapedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'description': description,
      'content': content,
      'metadata': metadata,
      'links': links,
      'images': images,
      'scrapedAt': scrapedAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'ScrapedContent(url: $url, title: $title, contentLength: ${content.length})';
  }
}

class Semaphore {
  int _currentCount;
  final int _maxCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(int maxCount) : _maxCount = maxCount, _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}

