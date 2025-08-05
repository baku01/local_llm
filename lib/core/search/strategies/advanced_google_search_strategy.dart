/// Estratégia de busca avançada para o Google.
///
/// Implementa busca no Google com recursos avançados:
/// - Rotação de User-Agents
/// - Tratamento de bloqueios e CAPTCHAs
/// - Retry com backoff exponencial
/// - Cache de resultados
/// - Análise de relevância
library;

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

import '../../../domain/entities/search_result.dart';
import '../../../domain/entities/search_query.dart';
import '../../utils/logger.dart';
import 'advanced_search_strategy.dart';

/// Implementação da estratégia de busca avançada para o Google.
class AdvancedGoogleSearchStrategy extends AdvancedSearchStrategy {
  /// Domínio base do Google para pesquisas.
  final String _searchDomain;

  /// Construtor da estratégia de busca avançada do Google.
  ///
  /// Permite configurar domínio específico, prioridade e outros parâmetros.
  AdvancedGoogleSearchStrategy({
    required http.Client client,
    String searchDomain = 'www.google.com',
    int priority = 10,
    List<String>? userAgents,
    Map<String, String>? extraHeaders,
    Duration? timeout,
    Duration? minBackoff,
    Duration? circuitOpenTime,
    int? maxRetries,
    int? maxRequestsPerMinute,
  })  : _searchDomain = searchDomain,
        super(
          client: client,
          name: 'Google',
          priority: priority,
          userAgents: userAgents,
          extraHeaders: extraHeaders,
          timeout: timeout,
          minBackoff: minBackoff,
          circuitOpenTime: circuitOpenTime,
          maxRetries: maxRetries,
          maxRequestsPerMinute: maxRequestsPerMinute,
        );

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final encodedQuery = Uri.encodeComponent(query.formattedQuery);
    final countParam = query.maxResults < 10 ? 10 : query.maxResults;
    final searchType = _getSearchTypeParam(query.type);

    final url =
        'https://$_searchDomain/search?q=$encodedQuery&num=$countParam$searchType&hl=pt-BR';

    AppLogger.debug(
        'Realizando busca no Google: $url', 'AdvancedGoogleSearchStrategy');

    final response = await makeRequest(url);
    final results = _parseGoogleResults(response.body, query);

    // Enriquecer resultados com análise de relevância
    return results.map((result) {
      final relevance = analyzeRelevance(result, query.query);
      return result.copyWith(relevanceScore: relevance);
    }).toList();
  }

  /// Obtém o parâmetro de tipo de busca para a URL
  String _getSearchTypeParam(SearchType type) {
    switch (type) {
      case SearchType.news:
        return '&tbm=nws';
      case SearchType.images:
        return '&tbm=isch';
      case SearchType.academic:
        return '&tbm=schol';
      case SearchType.general:
        return '';
    }
  }

  /// Faz parsing dos resultados do Google
  List<SearchResult> _parseGoogleResults(
      String htmlContent, SearchQuery query) {
    final document = html.parse(htmlContent);
    final results = <SearchResult>[];
    final maxResults = query.maxResults;

    // Tentativa primária - seletores principais
    final resultElements = document.querySelectorAll('div.g, div[data-ved]');

    for (final element in resultElements) {
      if (results.length >= maxResults) break;

      try {
        final result = _extractMainResult(element);
        if (result != null && !_isDuplicate(result, results)) {
          results.add(result);
        }
      } catch (e) {
        AppLogger.debug('Erro ao extrair resultado principal: $e',
            'AdvancedGoogleSearchStrategy');
        continue;
      }
    }

    // Tentativa secundária - seletores alternativos
    if (results.length < maxResults) {
      final fallbackElements =
          document.querySelectorAll('div.yuRUbf, div.kCrYT, div.ZINbbc');

      for (final element in fallbackElements) {
        if (results.length >= maxResults) break;

        try {
          final result = _extractFallbackResult(element);
          if (result != null && !_isDuplicate(result, results)) {
            results.add(result);
          }
        } catch (e) {
          AppLogger.debug('Erro ao extrair resultado alternativo: $e',
              'AdvancedGoogleSearchStrategy');
          continue;
        }
      }
    }

    // Terceira tentativa - busca genérica por tags <a> e seus containers
    if (results.length < maxResults / 2) {
      _extractGenericResults(document, results, maxResults);
    }

    return results;
  }

  /// Extrai resultado usando os seletores principais
  SearchResult? _extractMainResult(dom.Element element) {
    // Extrair link
    final linkElement = element.querySelector('a[href]');
    if (linkElement == null) return null;

    final href = linkElement.attributes['href'];
    if (href == null || !href.startsWith('http') || _isAdUrl(href)) return null;

    // Extrair título
    final titleElement = element.querySelector('h3') ??
        linkElement.querySelector('h3') ??
        linkElement;
    final title = extractCleanText(titleElement);
    if (title.isEmpty) return null;

    // Extrair snippet
    final snippetElement =
        element.querySelector('div.VwiC3b, .lyLwlc, .s3v9rd, .st');
    final snippet = extractCleanText(snippetElement);

    // Extrair data (opcional)
    final dateElement = element.querySelector('span.MUxGbd.wuQ4Ob.WZ8Tjf');
    final dateText = extractCleanText(dateElement);

    // Montar resultado
    return SearchResult(
      title: title,
      url: _cleanGoogleUrl(href),
      snippet: snippet.isNotEmpty ? snippet : 'Sem descrição disponível',
      timestamp: DateTime.now(),
      metadata: dateText.isNotEmpty ? {'published_date': dateText} : null,
    );
  }

  /// Extrai resultado usando seletores alternativos
  SearchResult? _extractFallbackResult(dom.Element element) {
    // Tentar extrair o link
    final linkElement = element.querySelector('a');
    if (linkElement == null) return null;

    final href = linkElement.attributes['href'];
    if (href == null) return null;

    // Processar URL do Google
    String url = href;
    if (href.startsWith('/url?')) {
      final uri = Uri.parse('https://google.com$href');
      url = uri.queryParameters['q'] ?? href;
    }

    if (!url.startsWith('http') || _isAdUrl(url)) return null;

    // Extrair título
    String title = extractCleanText(linkElement);
    if (title.isEmpty) {
      final titleElement = element.querySelector('div.vvjwJb, .BNeawe');
      title = extractCleanText(titleElement);
    }
    if (title.isEmpty) return null;

    // Extrair snippet
    final snippetElement =
        element.querySelector('.s3v9rd, .BNeawe, .s3v9rd.AP7Wnd');
    final snippet = extractCleanText(snippetElement);

    return SearchResult(
      title: title,
      url: _cleanGoogleUrl(url),
      snippet: snippet.isNotEmpty ? snippet : 'Sem descrição disponível',
      timestamp: DateTime.now(),
    );
  }

  /// Extrai resultados genéricos quando os métodos específicos falham
  void _extractGenericResults(
      dom.Document document, List<SearchResult> results, int maxResults) {
    final links = document.querySelectorAll('a[href^="http"]');

    for (final link in links) {
      if (results.length >= maxResults) break;

      try {
        final href = link.attributes['href'];
        if (href == null || !href.startsWith('http') || _isAdUrl(href)) {
          continue;
        }

        final url = _cleanGoogleUrl(href);

        // Ignorar URLs já adicionadas e URLs de imagens/recursos
        if (_isDuplicateUrl(url, results) ||
            url.endsWith('.jpg') ||
            url.endsWith('.png') ||
            url.contains('google.com/search')) {
          continue;
        }

        final title = extractCleanText(link);
        if (title.isEmpty || title.length < 4 || title == url) continue;

        // Tentar encontrar um snippet próximo ao link
        final parent = link.parent;
        final grandparent = parent?.parent;
        final parentSnippet =
            extractCleanText(parent?.querySelector('div, span:not(:has(a))'));
        final grandparentSnippet = extractCleanText(
            grandparent?.querySelector('div, span:not(:has(a))'));
        final snippet = parentSnippet.isNotEmpty
            ? parentSnippet
            : grandparentSnippet.isNotEmpty
                ? grandparentSnippet
                : 'Sem descrição disponível';

        final result = SearchResult(
          title: title,
          url: url,
          snippet: snippet,
          timestamp: DateTime.now(),
          metadata: {'source': 'generic_extractor'},
        );

        if (!_isDuplicate(result, results)) {
          results.add(result);
        }
      } catch (e) {
        continue;
      }
    }
  }

  /// Limpa URLs do Google, removendo parâmetros de rastreamento
  String _cleanGoogleUrl(String url) {
    try {
      // Se for uma URL de redirecionamento do Google
      if (url.contains('/url?') || url.contains('&url=')) {
        final uri = Uri.parse(url);
        final redirectUrl =
            uri.queryParameters['q'] ?? uri.queryParameters['url'];
        if (redirectUrl != null) url = redirectUrl;
      }

      // Remover parâmetros de rastreamento comuns
      final uri = Uri.parse(url);
      final params = <String>{...uri.queryParametersAll.keys};
      final trackingParams = {
        'utm_source',
        'utm_medium',
        'utm_campaign',
        'gclid',
        'fbclid',
        'ref'
      };

      // Se não houver parâmetros de rastreamento, retorna a URL original
      if (params.intersection(trackingParams).isEmpty) return url;

      // Remove os parâmetros de rastreamento
      final cleanParams = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((key, _) => trackingParams.contains(key));

      // Reconstrói a URL sem os parâmetros de rastreamento
      final cleanUri = uri.replace(queryParameters: cleanParams);
      return cleanUri.toString();
    } catch (e) {
      return url; // Em caso de erro, retorna a URL original
    }
  }

  /// Verifica se um resultado é duplicado na lista de resultados
  bool _isDuplicate(SearchResult result, List<SearchResult> results) {
    return results.any((existing) =>
        existing.url == result.url ||
        _normalizeTitle(existing.title) == _normalizeTitle(result.title));
  }

  /// Verifica se uma URL já existe na lista de resultados
  bool _isDuplicateUrl(String url, List<SearchResult> results) {
    return results.any((existing) => existing.url == url);
  }

  /// Normaliza um título para comparação de duplicatas
  String _normalizeTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  /// Verifica se uma URL é de anúncio
  bool _isAdUrl(String url) {
    return url.contains('/aclk?') ||
        url.contains('doubleclick.net') ||
        url.contains('googleadservices') ||
        url.contains('/pagead/');
  }
}
