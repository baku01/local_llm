import 'dart:async';
import 'dart:math' as math;
import '../../../domain/entities/search_result.dart';
import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/relevance_score.dart';

/// Advanced local search engine with indexing, fuzzy matching, and semantic analysis
class AdvancedLocalSearchEngine {
  static const int _maxIndexSize = 10000;
  static const double _fuzzyThreshold = 0.6;
  static const int _maxSuggestions = 10;

  final Map<String, SearchIndex> _indices = {};
  final Map<String, SearchableContent> _contentStore = {};
  final SearchHistory _history = SearchHistory();
  final SearchSuggestionEngine _suggestionEngine = SearchSuggestionEngine();
  final SemanticAnalyzer _semanticAnalyzer = SemanticAnalyzer();

  Timer? _indexOptimizationTimer;

  AdvancedLocalSearchEngine() {
    _startIndexOptimization();
  }

  /// Index content for searching
  Future<void> indexContent(List<SearchableContent> contents) async {
    final batch = IndexingBatch();

    for (final content in contents) {
      _contentStore[content.id] = content;
      await _indexContentItem(content, batch);
    }

    await _commitBatch(batch);
    _optimizeIndices();
  }

  /// Advanced search with multiple algorithms
  Future<SearchResults> search(AdvancedSearchQuery query) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Record search for history and suggestions
      _history.recordSearch(query.query);

      // Multiple search strategies
      final futures = <Future<List<SearchResult>>>[
        _exactSearch(query),
        _fuzzySearch(query),
        _semanticSearch(query),
        _contextualSearch(query),
      ];

      final results = await Future.wait(futures);
      final combined = _combineAndRankResults(results, query);
      final filtered = _applyFilters(combined, query);
      final sorted = _applySorting(filtered, query);
      final paginated = _applyPagination(sorted, query);

      stopwatch.stop();

      return SearchResults(
        results: paginated,
        totalCount: filtered.length,
        searchTime: stopwatch.elapsed,
        query: query,
        suggestions: await _generateSuggestions(query),
        facets: _generateFacets(filtered),
        metadata: _generateMetadata(query, filtered),
      );
    } catch (e) {
      stopwatch.stop();
      return SearchResults.error(
        query: query,
        error: 'Search failed: $e',
        searchTime: stopwatch.elapsed,
      );
    }
  }

  /// Get search suggestions based on input
  Future<List<SearchSuggestion>> getSuggestions(String input) async {
    if (input.isEmpty) {
      return _history.getRecentSearches().take(_maxSuggestions).toList();
    }

    final suggestions = <SearchSuggestion>[];

    // History-based suggestions
    suggestions.addAll(_history.getSuggestionsFor(input));

    // Content-based suggestions
    suggestions
        .addAll(await _suggestionEngine.generateSuggestions(input, _indices));

    // Semantic suggestions
    suggestions.addAll(await _semanticAnalyzer.generateSuggestions(input));

    return suggestions.toSet().take(_maxSuggestions).toList()
      ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
  }

  /// Get search filters based on content
  SearchFilters getAvailableFilters() {
    final contentTypes = <String>{};
    final sources = <String>{};
    final tags = <String>{};

    for (final content in _contentStore.values) {
      contentTypes.add(content.type);
      if (content.source != null) sources.add(content.source!);
      tags.addAll(content.tags);
    }

    return SearchFilters(
      contentTypes: contentTypes.toList()..sort(),
      sources: sources.toList()..sort(),
      tags: tags.toList()..sort(),
      dateRanges: _generateDateRanges(),
    );
  }

  /// Get search analytics
  SearchAnalytics getAnalytics() {
    return SearchAnalytics(
      totalSearches: _history.totalSearches,
      uniqueQueries: _history.uniqueQueries,
      averageResultCount: _calculateAverageResultCount(),
      topQueries: _history.getTopQueries(),
      searchTrends: _generateSearchTrends(),
      performanceMetrics: _getPerformanceMetrics(),
    );
  }

  // Private methods

  Future<void> _indexContentItem(
      SearchableContent content, IndexingBatch batch) async {
    final tokens = _tokenizeText(content.text);
    final nGrams = _generateNGrams(tokens);

    for (final token in tokens) {
      batch.addEntry(token, content.id, TokenType.word);
    }

    for (final nGram in nGrams) {
      batch.addEntry(nGram, content.id, TokenType.phrase);
    }

    // Index metadata
    if (content.title.isNotEmpty) {
      final titleTokens = _tokenizeText(content.title);
      for (final token in titleTokens) {
        batch.addEntry(token, content.id, TokenType.title, weight: 2.0);
      }
    }

    for (final tag in content.tags) {
      batch.addEntry(tag.toLowerCase(), content.id, TokenType.tag, weight: 1.5);
    }
  }

  Future<void> _commitBatch(IndexingBatch batch) async {
    for (final entry in batch.entries) {
      final index =
          _indices.putIfAbsent(entry.token, () => SearchIndex(entry.token));
      index.addDocument(entry.documentId, entry.type, entry.weight);
    }
  }

  Future<List<SearchResult>> _exactSearch(AdvancedSearchQuery query) async {
    final results = <SearchResult>[];
    final tokens = _tokenizeText(query.query);

    for (final token in tokens) {
      final index = _indices[token];
      if (index != null) {
        final documents = index.getDocuments();
        for (final docId in documents.keys) {
          final content = _contentStore[docId];
          if (content != null) {
            final score = _calculateExactScore(content, tokens);
            results.add(
                _createSearchResult(content, score, SearchResultType.exact));
          }
        }
      }
    }

    return results;
  }

  Future<List<SearchResult>> _fuzzySearch(AdvancedSearchQuery query) async {
    final results = <SearchResult>[];
    final queryTokens = _tokenizeText(query.query);

    for (final token in queryTokens) {
      for (final indexToken in _indices.keys) {
        final similarity = _calculateSimilarity(token, indexToken);
        if (similarity >= _fuzzyThreshold) {
          final index = _indices[indexToken]!;
          final documents = index.getDocuments();

          for (final docId in documents.keys) {
            final content = _contentStore[docId];
            if (content != null) {
              final score =
                  _calculateFuzzyScore(content, queryTokens, similarity);
              results.add(
                  _createSearchResult(content, score, SearchResultType.fuzzy));
            }
          }
        }
      }
    }

    return results;
  }

  Future<List<SearchResult>> _semanticSearch(AdvancedSearchQuery query) async {
    return await _semanticAnalyzer.search(query, _contentStore.values.toList());
  }

  Future<List<SearchResult>> _contextualSearch(
      AdvancedSearchQuery query) async {
    final results = <SearchResult>[];

    // Use search history for context
    final relatedQueries = _history.getRelatedQueries(query.query);

    for (final relatedQuery in relatedQueries) {
      final relatedResults = await _exactSearch(
        query.copyWithAdvanced(query: relatedQuery),
      );

      for (final result in relatedResults) {
        final contextualResult = result.copyWith(
          relevanceScore: result.relevanceScore?.copyWith(
            overallScore: (result.relevanceScore?.overallScore ?? 0) *
                0.7, // Lower weight for contextual
          ),
        );
        results.add(contextualResult);
      }
    }

    return results;
  }

  List<SearchResult> _combineAndRankResults(
    List<List<SearchResult>> resultSets,
    AdvancedSearchQuery query,
  ) {
    final combined = <String, SearchResult>{};

    for (final results in resultSets) {
      for (final result in results) {
        final key = '${result.url}_${result.title}';
        final existing = combined[key];

        if (existing == null) {
          combined[key] = result;
        } else {
          // Combine scores from multiple search methods
          final combinedScore = (existing.relevanceScore?.overallScore ?? 0) +
              (result.relevanceScore?.overallScore ?? 0) * 0.5;

          combined[key] = existing.copyWith(
            relevanceScore: existing.relevanceScore?.copyWith(
              overallScore: combinedScore,
            ),
          );
        }
      }
    }

    return combined.values.toList()
      ..sort((a, b) => (b.relevanceScore?.overallScore ?? 0)
          .compareTo(a.relevanceScore?.overallScore ?? 0));
  }

  List<SearchResult> _applyFilters(
      List<SearchResult> results, AdvancedSearchQuery query) {
    var filtered = results;

    if (query.contentTypes.isNotEmpty) {
      filtered = filtered.where((result) {
        final content =
            _getContentById(result.metadata?['contentId'] as String?);
        return content != null && query.contentTypes.contains(content.type);
      }).toList();
    }

    if (query.sources.isNotEmpty) {
      filtered = filtered.where((result) {
        final content =
            _getContentById(result.metadata?['contentId'] as String?);
        return content?.source != null &&
            query.sources.contains(content!.source);
      }).toList();
    }

    if (query.tags.isNotEmpty) {
      filtered = filtered.where((result) {
        final content =
            _getContentById(result.metadata?['contentId'] as String?);
        return content != null &&
            content.tags.any((tag) => query.tags.contains(tag));
      }).toList();
    }

    if (query.dateRange != null) {
      filtered = filtered.where((result) {
        final content =
            _getContentById(result.metadata?['contentId'] as String?);
        if (content?.timestamp == null) return true;

        final date = content!.timestamp!;
        return date.isAfter(query.dateRange!.start) &&
            date.isBefore(query.dateRange!.end);
      }).toList();
    }

    return filtered;
  }

  List<SearchResult> _applySorting(
      List<SearchResult> results, AdvancedSearchQuery query) {
    switch (query.sortBy) {
      case SearchSortBy.relevance:
        return results
          ..sort((a, b) => (b.relevanceScore?.overallScore ?? 0)
              .compareTo(a.relevanceScore?.overallScore ?? 0));

      case SearchSortBy.date:
        return results
          ..sort((a, b) {
            final aContent =
                _getContentById(a.metadata?['contentId'] as String?);
            final bContent =
                _getContentById(b.metadata?['contentId'] as String?);

            final aDate =
                aContent?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                bContent?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

            return query.sortOrder == SearchSortOrder.ascending
                ? aDate.compareTo(bDate)
                : bDate.compareTo(aDate);
          });

      case SearchSortBy.title:
        return results
          ..sort((a, b) {
            final comparison = a.title.compareTo(b.title);
            return query.sortOrder == SearchSortOrder.ascending
                ? comparison
                : -comparison;
          });

      case SearchSortBy.source:
        return results
          ..sort((a, b) {
            final aContent =
                _getContentById(a.metadata?['contentId'] as String?);
            final bContent =
                _getContentById(b.metadata?['contentId'] as String?);

            final aSource = aContent?.source ?? '';
            final bSource = bContent?.source ?? '';

            final comparison = aSource.compareTo(bSource);
            return query.sortOrder == SearchSortOrder.ascending
                ? comparison
                : -comparison;
          });
    }
  }

  List<SearchResult> _applyPagination(
      List<SearchResult> results, AdvancedSearchQuery query) {
    final start = (query.page - 1) * query.pageSize;
    final end = math.min(start + query.pageSize, results.length);

    if (start >= results.length) return [];
    return results.sublist(start, end);
  }

  Future<List<SearchSuggestion>> _generateSuggestions(
      AdvancedSearchQuery query) async {
    return await getSuggestions(query.query);
  }

  Map<String, List<FacetValue>> _generateFacets(List<SearchResult> results) {
    final facets = <String, Map<String, int>>{
      'content_type': {},
      'source': {},
      'tags': {},
    };

    for (final result in results) {
      final content = _getContentById(result.metadata?['contentId'] as String?);
      if (content == null) continue;

      // Content type facets
      facets['content_type']![content.type] =
          (facets['content_type']![content.type] ?? 0) + 1;

      // Source facets
      if (content.source != null) {
        facets['source']![content.source!] =
            (facets['source']![content.source!] ?? 0) + 1;
      }

      // Tag facets
      for (final tag in content.tags) {
        facets['tags']![tag] = (facets['tags']![tag] ?? 0) + 1;
      }
    }

    final result = <String, List<FacetValue>>{};
    for (final entry in facets.entries) {
      result[entry.key] = entry.value.entries
          .map((e) => FacetValue(value: e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));
    }

    return result;
  }

  Map<String, dynamic> _generateMetadata(
      AdvancedSearchQuery query, List<SearchResult> results) {
    return {
      'total_indexed_items': _contentStore.length,
      'index_size': _indices.length,
      'search_method_breakdown': _analyzeSearchMethods(results),
      'quality_score': _calculateQueryQuality(query),
      'performance_hints': _generatePerformanceHints(query, results),
    };
  }

  List<String> _tokenizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 1)
        .toList();
  }

  List<String> _generateNGrams(List<String> tokens, {int n = 2}) {
    final nGrams = <String>[];

    for (int i = 0; i <= tokens.length - n; i++) {
      final nGram = tokens.sublist(i, i + n).join(' ');
      nGrams.add(nGram);
    }

    return nGrams;
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;

    if (longer.isEmpty) return 1.0;

    final editDistance = _calculateLevenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  int _calculateLevenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(math.min);
      }
    }

    return matrix[a.length][b.length];
  }

  double _calculateExactScore(
      SearchableContent content, List<String> queryTokens) {
    double score = 0.0;
    final contentTokens = _tokenizeText(content.text);
    final titleTokens = _tokenizeText(content.title);

    for (final token in queryTokens) {
      // Title matches have higher weight
      if (titleTokens.contains(token)) {
        score += 2.0;
      }

      // Content matches
      final contentMatches = contentTokens.where((t) => t == token).length;
      score += contentMatches * 1.0;

      // Tag matches
      if (content.tags.any((tag) => tag.toLowerCase().contains(token))) {
        score += 1.5;
      }
    }

    return score / queryTokens.length;
  }

  double _calculateFuzzyScore(
      SearchableContent content, List<String> queryTokens, double similarity) {
    return _calculateExactScore(content, queryTokens) * similarity;
  }

  SearchResult _createSearchResult(
    SearchableContent content,
    double score,
    SearchResultType type,
  ) {
    return SearchResult(
      title: content.title.isEmpty ? 'Untitled' : content.title,
      url: content.url,
      snippet: _generateSnippet(content.text),
      timestamp: DateTime.now(),
      relevanceScore: RelevanceScore.calculate(
        titleRelevance: _calculateTitleRelevance(content.title),
        contentRelevance: score,
        urlRelevance: _calculateUrlRelevance(content.url),
        metadataRelevance: _calculateMetadataRelevance(content),
      ),
      metadata: {
        'contentId': content.id,
        'searchType': type.name,
        'originalScore': score,
        'contentType': content.type,
        'source': content.source,
        'tags': content.tags,
      },
    );
  }

  String _generateSnippet(String text, {int maxLength = 200}) {
    if (text.length <= maxLength) return text;

    final cutoff = text.lastIndexOf(' ', maxLength);
    return '${text.substring(0, cutoff > 0 ? cutoff : maxLength)}...';
  }

  double _calculateTitleRelevance(String title) {
    return title.isNotEmpty ? 1.0 : 0.0;
  }

  double _calculateUrlRelevance(String url) {
    return url.isNotEmpty ? 0.5 : 0.0;
  }

  double _calculateMetadataRelevance(SearchableContent content) {
    double score = 0.0;
    if (content.source != null) score += 0.2;
    score += content.tags.length * 0.1;
    return math.min(score, 1.0);
  }

  SearchableContent? _getContentById(String? id) {
    return id != null ? _contentStore[id] : null;
  }

  void _startIndexOptimization() {
    _indexOptimizationTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _optimizeIndices(),
    );
  }

  void _optimizeIndices() {
    // Remove indices for deleted content
    final validDocIds = _contentStore.keys.toSet();

    for (final index in _indices.values) {
      index.removeDeletedDocuments(validDocIds);
    }

    // Remove empty indices
    _indices.removeWhere((key, index) => index.isEmpty);

    // Limit index size
    if (_indices.length > _maxIndexSize) {
      final sortedIndices = _indices.entries.toList()
        ..sort(
            (a, b) => a.value.documentCount.compareTo(b.value.documentCount));

      final toRemove = _indices.length - _maxIndexSize;
      for (int i = 0; i < toRemove; i++) {
        _indices.remove(sortedIndices[i].key);
      }
    }
  }

  double _calculateAverageResultCount() {
    return _history.totalSearches > 0
        ? _history.totalResults / _history.totalSearches
        : 0.0;
  }

  List<DateRange> _generateDateRanges() {
    final now = DateTime.now();
    return [
      DateRange(
        label: 'Última hora',
        start: now.subtract(const Duration(hours: 1)),
        end: now,
      ),
      DateRange(
        label: 'Últimas 24 horas',
        start: now.subtract(const Duration(days: 1)),
        end: now,
      ),
      DateRange(
        label: 'Última semana',
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      DateRange(
        label: 'Último mês',
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    ];
  }

  List<SearchTrend> _generateSearchTrends() {
    return _history.generateTrends();
  }

  Map<String, double> _getPerformanceMetrics() {
    return {
      'average_search_time_ms':
          _history.averageSearchTime.inMilliseconds.toDouble(),
      'cache_hit_rate': _history.cacheHitRate,
      'index_efficiency': _calculateIndexEfficiency(),
    };
  }

  double _calculateIndexEfficiency() {
    if (_indices.isEmpty) return 0.0;

    final totalDocuments = _indices.values
        .map((index) => index.documentCount)
        .reduce((a, b) => a + b);

    return totalDocuments / _indices.length;
  }

  Map<String, int> _analyzeSearchMethods(List<SearchResult> results) {
    final methods = <String, int>{};

    for (final result in results) {
      final method = result.metadata?['searchType'] as String? ?? 'unknown';
      methods[method] = (methods[method] ?? 0) + 1;
    }

    return methods;
  }

  double _calculateQueryQuality(AdvancedSearchQuery query) {
    double score = 0.0;

    // Query length
    final words = query.query.split(' ');
    if (words.length >= 2 && words.length <= 6) score += 0.3;

    // Has filters
    if (query.contentTypes.isNotEmpty ||
        query.sources.isNotEmpty ||
        query.tags.isNotEmpty) {
      score += 0.2;
    }

    // Specific vs generic
    if (words.any((word) => word.length > 5)) score += 0.3;

    // Not all stop words
    final stopWords = {
      'the',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for'
    };
    if (words.any((word) => !stopWords.contains(word.toLowerCase()))) {
      score += 0.2;
    }

    return math.min(score, 1.0);
  }

  List<String> _generatePerformanceHints(
      AdvancedSearchQuery query, List<SearchResult> results) {
    final hints = <String>[];

    if (results.length > 1000) {
      hints.add('Consider adding filters to narrow down results');
    }

    if (query.query.split(' ').length == 1) {
      hints.add('Try adding more keywords for better results');
    }

    if (results.isEmpty) {
      hints.add('Try using different keywords or check spelling');
    }

    return hints;
  }

  void dispose() {
    _indexOptimizationTimer?.cancel();
  }
}

// Supporting classes and enums

/// Searchable content item
class SearchableContent {
  final String id;
  final String title;
  final String text;
  final String url;
  final String type;
  final String? source;
  final List<String> tags;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  const SearchableContent({
    required this.id,
    required this.title,
    required this.text,
    required this.url,
    required this.type,
    this.source,
    this.tags = const [],
    this.timestamp,
    this.metadata,
  });

  factory SearchableContent.fromChatMessage(ChatMessage message) {
    return SearchableContent(
      id: '${message.timestamp.millisecondsSinceEpoch}',
      title: message.isUser ? 'User Message' : 'AI Response',
      text: message.text,
      url: 'chat://message/${message.timestamp.millisecondsSinceEpoch}',
      type: message.isUser ? 'user_message' : 'ai_response',
      source: 'chat',
      tags: message.isUser ? ['user', 'question'] : ['ai', 'answer'],
      timestamp: message.timestamp,
      metadata: {'isUser': message.isUser},
    );
  }
}

/// Advanced search query with filters and sorting
class AdvancedSearchQuery extends SearchQuery {
  final List<String> contentTypes;
  final List<String> sources;
  final List<String> tags;
  final DateRange? dateRange;
  final SearchSortBy sortBy;
  final SearchSortOrder sortOrder;
  final int page;
  final int pageSize;
  final bool includeSnippets;
  final bool includeFacets;
  final bool enableFuzzySearch;
  final bool enableSemanticSearch;

  const AdvancedSearchQuery({
    required String query,
    SearchType type = SearchType.general,
    int maxResults = 50,
    this.contentTypes = const [],
    this.sources = const [],
    this.tags = const [],
    this.dateRange,
    this.sortBy = SearchSortBy.relevance,
    this.sortOrder = SearchSortOrder.descending,
    this.page = 1,
    this.pageSize = 20,
    this.includeSnippets = true,
    this.includeFacets = true,
    this.enableFuzzySearch = true,
    this.enableSemanticSearch = true,
  }) : super(query: query, type: type, maxResults: maxResults);

  @override
  SearchQuery copyWith({
    String? query,
    SearchType? type,
    int? maxResults,
    String? contentType,
    String? language,
    String? timeRange,
    List<String>? domains,
    List<String>? excludeTerms,
    List<String>? synonyms,
  }) {
    return AdvancedSearchQuery(
      query: query ?? this.query,
      type: type ?? this.type,
      maxResults: maxResults ?? this.maxResults,
      contentTypes: contentTypes,
      sources: sources,
      tags: tags,
      dateRange: dateRange,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      pageSize: pageSize,
      includeSnippets: includeSnippets,
      includeFacets: includeFacets,
      enableFuzzySearch: enableFuzzySearch,
      enableSemanticSearch: enableSemanticSearch,
    );
  }

  AdvancedSearchQuery copyWithAdvanced({
    String? query,
    SearchType? type,
    int? maxResults,
    List<String>? contentTypes,
    List<String>? sources,
    List<String>? tags,
    DateRange? dateRange,
    SearchSortBy? sortBy,
    SearchSortOrder? sortOrder,
    int? page,
    int? pageSize,
    bool? includeSnippets,
    bool? includeFacets,
    bool? enableFuzzySearch,
    bool? enableSemanticSearch,
  }) {
    return AdvancedSearchQuery(
      query: query ?? this.query,
      type: type ?? this.type,
      maxResults: maxResults ?? this.maxResults,
      contentTypes: contentTypes ?? this.contentTypes,
      sources: sources ?? this.sources,
      tags: tags ?? this.tags,
      dateRange: dateRange ?? this.dateRange,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      includeSnippets: includeSnippets ?? this.includeSnippets,
      includeFacets: includeFacets ?? this.includeFacets,
      enableFuzzySearch: enableFuzzySearch ?? this.enableFuzzySearch,
      enableSemanticSearch: enableSemanticSearch ?? this.enableSemanticSearch,
    );
  }
}

/// Search results container
class SearchResults {
  final List<SearchResult> results;
  final int totalCount;
  final Duration searchTime;
  final AdvancedSearchQuery query;
  final List<SearchSuggestion> suggestions;
  final Map<String, List<FacetValue>> facets;
  final Map<String, dynamic> metadata;
  final String? error;

  const SearchResults({
    required this.results,
    required this.totalCount,
    required this.searchTime,
    required this.query,
    this.suggestions = const [],
    this.facets = const {},
    this.metadata = const {},
    this.error,
  });

  factory SearchResults.error({
    required AdvancedSearchQuery query,
    required String error,
    required Duration searchTime,
  }) {
    return SearchResults(
      results: [],
      totalCount: 0,
      searchTime: searchTime,
      query: query,
      error: error,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
  int get pageCount => (totalCount / query.pageSize).ceil();
  bool get hasMorePages => query.page < pageCount;
}

/// Search suggestion
class SearchSuggestion {
  final String suggestion;
  final double relevanceScore;
  final SearchSuggestionType type;
  final Map<String, dynamic>? metadata;

  const SearchSuggestion({
    required this.suggestion,
    required this.relevanceScore,
    required this.type,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestion &&
          runtimeType == other.runtimeType &&
          suggestion == other.suggestion;

  @override
  int get hashCode => suggestion.hashCode;
}

/// Facet value for filtering
class FacetValue {
  final String value;
  final int count;

  const FacetValue({required this.value, required this.count});
}

/// Date range for filtering
class DateRange {
  final String label;
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.label,
    required this.start,
    required this.end,
  });
}

/// Search filters
class SearchFilters {
  final List<String> contentTypes;
  final List<String> sources;
  final List<String> tags;
  final List<DateRange> dateRanges;

  const SearchFilters({
    required this.contentTypes,
    required this.sources,
    required this.tags,
    required this.dateRanges,
  });
}

/// Search analytics
class SearchAnalytics {
  final int totalSearches;
  final int uniqueQueries;
  final double averageResultCount;
  final List<String> topQueries;
  final List<SearchTrend> searchTrends;
  final Map<String, double> performanceMetrics;

  const SearchAnalytics({
    required this.totalSearches,
    required this.uniqueQueries,
    required this.averageResultCount,
    required this.topQueries,
    required this.searchTrends,
    required this.performanceMetrics,
  });
}

/// Search trend data
class SearchTrend {
  final String query;
  final List<int> counts;
  final List<DateTime> timestamps;

  const SearchTrend({
    required this.query,
    required this.counts,
    required this.timestamps,
  });
}

// Enums

enum SearchSortBy { relevance, date, title, source }

enum SearchSortOrder { ascending, descending }

enum SearchResultType { exact, fuzzy, semantic, contextual }

enum SearchSuggestionType { history, content, semantic, trending }

enum TokenType { word, phrase, title, tag }

// Helper classes

class SearchIndex {
  final String token;
  final Map<String, DocumentEntry> _documents = {};

  SearchIndex(this.token);

  void addDocument(String docId, TokenType type, [double weight = 1.0]) {
    _documents[docId] = DocumentEntry(type, weight);
  }

  void removeDocument(String docId) {
    _documents.remove(docId);
  }

  void removeDeletedDocuments(Set<String> validDocIds) {
    _documents.removeWhere((docId, entry) => !validDocIds.contains(docId));
  }

  Map<String, DocumentEntry> getDocuments() => Map.from(_documents);
  int get documentCount => _documents.length;
  bool get isEmpty => _documents.isEmpty;
}

class DocumentEntry {
  final TokenType type;
  final double weight;

  const DocumentEntry(this.type, this.weight);
}

class IndexingBatch {
  final List<IndexEntry> entries = [];

  void addEntry(String token, String documentId, TokenType type,
      {double weight = 1.0}) {
    entries.add(IndexEntry(token, documentId, type, weight));
  }
}

class IndexEntry {
  final String token;
  final String documentId;
  final TokenType type;
  final double weight;

  const IndexEntry(this.token, this.documentId, this.type, this.weight);
}

class SearchHistory {
  final List<String> _queries = [];
  final Map<String, int> _queryCounts = {};
  final Map<String, DateTime> _lastSearched = {};

  int _totalResults = 0;
  Duration _totalSearchTime = Duration.zero;
  int _cacheHits = 0;

  void recordSearch(String query) {
    _queries.add(query);
    _queryCounts[query] = (_queryCounts[query] ?? 0) + 1;
    _lastSearched[query] = DateTime.now();

    // Keep only recent queries
    if (_queries.length > 1000) {
      _queries.removeAt(0);
    }
  }

  List<SearchSuggestion> getRecentSearches() {
    return _queries.reversed
        .take(10)
        .map((query) => SearchSuggestion(
              suggestion: query,
              relevanceScore: 1.0,
              type: SearchSuggestionType.history,
            ))
        .toList();
  }

  List<SearchSuggestion> getSuggestionsFor(String input) {
    final suggestions = <SearchSuggestion>[];

    for (final query in _queryCounts.keys) {
      if (query.toLowerCase().contains(input.toLowerCase())) {
        final score = (_queryCounts[query]! / _queries.length) *
            (query.length / input.length);

        suggestions.add(SearchSuggestion(
          suggestion: query,
          relevanceScore: score,
          type: SearchSuggestionType.history,
        ));
      }
    }

    return suggestions
      ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
  }

  List<String> getRelatedQueries(String query) {
    // Simple related query logic - could be made more sophisticated
    return _queryCounts.keys
        .where((q) => q != query && _hasCommonWords(q, query))
        .take(3)
        .toList();
  }

  List<String> getTopQueries() {
    final sorted = _queryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => e.key).toList();
  }

  List<SearchTrend> generateTrends() {
    // Simplified trend generation
    final topQueries = getTopQueries().take(5);

    return topQueries.map((query) {
      final count = _queryCounts[query] ?? 0;
      return SearchTrend(
        query: query,
        counts: [count],
        timestamps: [_lastSearched[query] ?? DateTime.now()],
      );
    }).toList();
  }

  bool _hasCommonWords(String query1, String query2) {
    final words1 = query1.toLowerCase().split(' ').toSet();
    final words2 = query2.toLowerCase().split(' ').toSet();

    return words1.intersection(words2).isNotEmpty;
  }

  int get totalSearches => _queries.length;
  int get uniqueQueries => _queryCounts.length;
  int get totalResults => _totalResults;
  Duration get averageSearchTime => totalSearches > 0
      ? Duration(milliseconds: _totalSearchTime.inMilliseconds ~/ totalSearches)
      : Duration.zero;
  double get cacheHitRate =>
      totalSearches > 0 ? _cacheHits / totalSearches : 0.0;
}

class SearchSuggestionEngine {
  Future<List<SearchSuggestion>> generateSuggestions(
    String input,
    Map<String, SearchIndex> indices,
  ) async {
    final suggestions = <SearchSuggestion>[];

    for (final token in indices.keys) {
      if (token.startsWith(input.toLowerCase()) &&
          token != input.toLowerCase()) {
        final documentCount = indices[token]!.documentCount;
        final score =
            documentCount / 100.0; // Normalize by typical document count

        suggestions.add(SearchSuggestion(
          suggestion: token,
          relevanceScore: score,
          type: SearchSuggestionType.content,
        ));
      }
    }

    return suggestions
      ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
  }
}

class SemanticAnalyzer {
  Future<List<SearchResult>> search(
    AdvancedSearchQuery query,
    List<SearchableContent> contents,
  ) async {
    final results = <SearchResult>[];

    // Simplified semantic analysis - could be enhanced with ML models
    final queryWords = query.query.toLowerCase().split(' ');
    final semanticWords = _generateSemanticWords(queryWords);

    for (final content in contents) {
      final contentWords = content.text.toLowerCase().split(' ');
      final score = _calculateSemanticScore(semanticWords, contentWords);

      if (score > 0.1) {
        results.add(SearchResult(
          title: content.title,
          url: content.url,
          snippet: content.text.length > 200
              ? '${content.text.substring(0, 200)}...'
              : content.text,
          timestamp: DateTime.now(),
          relevanceScore: RelevanceScore.calculate(
            titleRelevance: 0.5,
            contentRelevance: score,
            urlRelevance: 0.5,
            metadataRelevance: 0.0,
            semanticScore: score,
          ),
          metadata: {
            'contentId': content.id,
            'searchType': SearchResultType.semantic.name,
          },
        ));
      }
    }

    return results;
  }

  Future<List<SearchSuggestion>> generateSuggestions(String input) async {
    final semanticWords = _generateSemanticWords([input.toLowerCase()]);

    return semanticWords
        .where((word) => word != input.toLowerCase())
        .take(5)
        .map((word) => SearchSuggestion(
              suggestion: word,
              relevanceScore: 0.7,
              type: SearchSuggestionType.semantic,
            ))
        .toList();
  }

  List<String> _generateSemanticWords(List<String> words) {
    final semanticMap = {
      'error': ['bug', 'issue', 'problem', 'exception', 'failure'],
      'install': ['setup', 'configure', 'deploy', 'initialize'],
      'code': ['program', 'script', 'source', 'implementation'],
      'tutorial': ['guide', 'howto', 'manual', 'documentation'],
      'api': ['interface', 'service', 'endpoint', 'method'],
    };

    final result = words.toList();

    for (final word in words) {
      if (semanticMap.containsKey(word)) {
        result.addAll(semanticMap[word]!);
      }
    }

    return result.toSet().toList();
  }

  double _calculateSemanticScore(
      List<String> queryWords, List<String> contentWords) {
    final contentSet = contentWords.toSet();
    final matches =
        queryWords.where((word) => contentSet.contains(word)).length;

    return matches / queryWords.length;
  }
}
