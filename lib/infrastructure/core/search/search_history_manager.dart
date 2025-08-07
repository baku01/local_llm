import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/search_result.dart';

/// Manages search history, favorites, and user preferences
class SearchHistoryManager {
  static const String _historyKey = 'search_history';
  static const String _favoritesKey = 'search_favorites';
  static const String _preferencesKey = 'search_preferences';
  static const String _tagsKey = 'search_tags';
  static const String _collectionsKey = 'search_collections';

  static const int _maxHistoryItems = 1000;
  static const int _maxFavoriteItems = 500;

  late SharedPreferences _prefs;
  final List<SearchHistoryItem> _history = [];
  final List<FavoriteItem> _favorites = [];
  final Set<String> _tags = {};
  final List<SearchCollection> _collections = [];

  SearchPreferences _preferences = const SearchPreferences();

  bool _isInitialized = false;
  final StreamController<List<SearchHistoryItem>> _historyController =
      StreamController<List<SearchHistoryItem>>.broadcast();
  final StreamController<List<FavoriteItem>> _favoritesController =
      StreamController<List<FavoriteItem>>.broadcast();

  /// Stream of search history changes
  Stream<List<SearchHistoryItem>> get historyStream =>
      _historyController.stream;

  /// Stream of favorites changes
  Stream<List<FavoriteItem>> get favoritesStream => _favoritesController.stream;

  /// Initialize the manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadData();
    _isInitialized = true;
  }

  /// Add search query to history
  Future<void> addToHistory(
    String query, {
    int? resultCount,
    Duration? searchDuration,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();

    // Remove existing entry with same query
    _history
        .removeWhere((item) => item.query.toLowerCase() == query.toLowerCase());

    // Add new entry at the beginning
    final historyItem = SearchHistoryItem(
      id: _generateId(),
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      searchDuration: searchDuration,
      metadata: metadata ?? {},
    );

    _history.insert(0, historyItem);

    // Limit history size
    if (_history.length > _maxHistoryItems) {
      _history.removeRange(_maxHistoryItems, _history.length);
    }

    await _saveHistory();
    _historyController.add(List.from(_history));
  }

  /// Add search result to favorites
  Future<String> addToFavorites(
    SearchResult result, {
    String? note,
    List<String>? tags,
    String? collectionId,
  }) async {
    await _ensureInitialized();

    // Check if already exists
    final existingIndex = _favorites.indexWhere((fav) => fav.url == result.url);

    final favoriteItem = FavoriteItem(
      id: existingIndex >= 0 ? _favorites[existingIndex].id : _generateId(),
      title: result.title,
      url: result.url,
      snippet: result.snippet,
      timestamp: existingIndex >= 0
          ? _favorites[existingIndex].timestamp
          : DateTime.now(),
      addedAt: DateTime.now(),
      note: note,
      tags: tags ?? [],
      collectionId: collectionId,
      accessCount:
          existingIndex >= 0 ? _favorites[existingIndex].accessCount : 0,
      lastAccessedAt:
          existingIndex >= 0 ? _favorites[existingIndex].lastAccessedAt : null,
      originalSearchQuery: result.metadata?['originalQuery'] as String?,
      relevanceScore: result.relevanceScore?.overallScore,
    );

    if (existingIndex >= 0) {
      _favorites[existingIndex] = favoriteItem;
    } else {
      _favorites.insert(0, favoriteItem);

      // Limit favorites size
      if (_favorites.length > _maxFavoriteItems) {
        _favorites.removeRange(_maxFavoriteItems, _favorites.length);
      }
    }

    // Add tags to global tags set
    if (tags != null) {
      _tags.addAll(tags);
      await _saveTags();
    }

    await _saveFavorites();
    _favoritesController.add(List.from(_favorites));

    return favoriteItem.id;
  }

  /// Remove item from favorites
  Future<void> removeFromFavorites(String favoriteId) async {
    await _ensureInitialized();

    _favorites.removeWhere((fav) => fav.id == favoriteId);
    await _saveFavorites();
    _favoritesController.add(List.from(_favorites));
  }

  /// Update favorite item
  Future<void> updateFavorite(
    String favoriteId, {
    String? note,
    List<String>? tags,
    String? collectionId,
  }) async {
    await _ensureInitialized();

    final index = _favorites.indexWhere((fav) => fav.id == favoriteId);
    if (index >= 0) {
      final existing = _favorites[index];
      _favorites[index] = existing.copyWith(
        note: note,
        tags: tags,
        collectionId: collectionId,
      );

      if (tags != null) {
        _tags.addAll(tags);
        await _saveTags();
      }

      await _saveFavorites();
      _favoritesController.add(List.from(_favorites));
    }
  }

  /// Mark favorite as accessed
  Future<void> accessFavorite(String favoriteId) async {
    await _ensureInitialized();

    final index = _favorites.indexWhere((fav) => fav.id == favoriteId);
    if (index >= 0) {
      final existing = _favorites[index];
      _favorites[index] = existing.copyWith(
        accessCount: existing.accessCount + 1,
        lastAccessedAt: DateTime.now(),
      );

      await _saveFavorites();
      _favoritesController.add(List.from(_favorites));
    }
  }

  /// Check if result is in favorites
  bool isFavorite(String url) {
    return _favorites.any((fav) => fav.url == url);
  }

  /// Get favorite by URL
  FavoriteItem? getFavoriteByUrl(String url) {
    try {
      return _favorites.firstWhere((fav) => fav.url == url);
    } catch (e) {
      return null;
    }
  }

  /// Create a new collection
  Future<String> createCollection(
    String name, {
    String? description,
    List<String>? tags,
  }) async {
    await _ensureInitialized();

    final collection = SearchCollection(
      id: _generateId(),
      name: name,
      description: description,
      tags: tags ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _collections.add(collection);
    await _saveCollections();

    return collection.id;
  }

  /// Add favorite to collection
  Future<void> addFavoriteToCollection(
      String favoriteId, String collectionId) async {
    await updateFavorite(favoriteId, collectionId: collectionId);
  }

  /// Get search history
  List<SearchHistoryItem> getHistory({int? limit, String? query}) {
    var filtered = _history.where((item) {
      if (query == null || query.isEmpty) return true;
      return item.query.toLowerCase().contains(query.toLowerCase());
    });

    if (limit != null) {
      filtered = filtered.take(limit);
    }

    return filtered.toList();
  }

  /// Get recent searches
  List<String> getRecentSearches({int limit = 10}) {
    return _history.take(limit).map((item) => item.query).toList();
  }

  /// Get popular searches
  List<String> getPopularSearches({int limit = 10}) {
    final queryCount = <String, int>{};

    for (final item in _history) {
      final query = item.query.toLowerCase();
      queryCount[query] = (queryCount[query] ?? 0) + 1;
    }

    final sorted = queryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((entry) => entry.key).toList();
  }

  /// Get search suggestions based on history
  List<String> getSearchSuggestions(String input, {int limit = 5}) {
    if (input.isEmpty) return getRecentSearches(limit: limit);

    final suggestions = _history
        .where((item) => item.query.toLowerCase().contains(input.toLowerCase()))
        .take(limit)
        .map((item) => item.query)
        .toList();

    return suggestions;
  }

  /// Get favorites
  List<FavoriteItem> getFavorites({
    int? limit,
    String? tag,
    String? collectionId,
    FavoriteSortBy sortBy = FavoriteSortBy.addedDate,
  }) {
    var filtered = _favorites.where((fav) {
      if (tag != null && !fav.tags.contains(tag)) return false;
      if (collectionId != null && fav.collectionId != collectionId)
        return false;
      return true;
    });

    // Sort favorites
    final sortedList = filtered.toList();
    switch (sortBy) {
      case FavoriteSortBy.addedDate:
        sortedList.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case FavoriteSortBy.accessCount:
        sortedList.sort((a, b) => b.accessCount.compareTo(a.accessCount));
        break;
      case FavoriteSortBy.lastAccessed:
        sortedList.sort((a, b) => (b.lastAccessedAt ??
                DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(
                a.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
        break;
      case FavoriteSortBy.relevance:
        sortedList.sort((a, b) =>
            (b.relevanceScore ?? 0.0).compareTo(a.relevanceScore ?? 0.0));
        break;
      case FavoriteSortBy.alphabetical:
        sortedList.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    if (limit != null) {
      return sortedList.take(limit).toList();
    }

    return sortedList;
  }

  /// Get all available tags
  Set<String> getAllTags() {
    final allTags = Set<String>.from(_tags);

    // Add tags from favorites
    for (final favorite in _favorites) {
      allTags.addAll(favorite.tags);
    }

    return allTags;
  }

  /// Get collections
  List<SearchCollection> getCollections() {
    return List.from(_collections);
  }

  /// Get collection by ID
  SearchCollection? getCollection(String id) {
    try {
      return _collections.firstWhere((col) => col.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get favorites count in collection
  int getFavoritesCountInCollection(String collectionId) {
    return _favorites.where((fav) => fav.collectionId == collectionId).length;
  }

  /// Clear search history
  Future<void> clearHistory() async {
    await _ensureInitialized();

    _history.clear();
    await _saveHistory();
    _historyController.add(List.from(_history));
  }

  /// Clear favorites
  Future<void> clearFavorites() async {
    await _ensureInitialized();

    _favorites.clear();
    await _saveFavorites();
    _favoritesController.add(List.from(_favorites));
  }

  /// Remove old history items
  Future<void> cleanupHistory({Duration? olderThan}) async {
    await _ensureInitialized();

    final cutoffDate =
        DateTime.now().subtract(olderThan ?? const Duration(days: 30));

    _history.removeWhere((item) => item.timestamp.isBefore(cutoffDate));
    await _saveHistory();
    _historyController.add(List.from(_history));
  }

  /// Get search statistics
  SearchStatistics getSearchStatistics() {
    if (_history.isEmpty) {
      return const SearchStatistics(
        totalSearches: 0,
        uniqueQueries: 0,
        averageResultsPerSearch: 0.0,
        totalFavorites: 0,
        mostSearchedQuery: null,
        searchFrequency: {},
        dailySearchCounts: {},
      );
    }

    final uniqueQueries =
        _history.map((item) => item.query.toLowerCase()).toSet();
    final queryFrequency = <String, int>{};
    final dailyCounts = <String, int>{};

    int totalResults = 0;
    int searchesWithResults = 0;

    for (final item in _history) {
      final query = item.query.toLowerCase();
      queryFrequency[query] = (queryFrequency[query] ?? 0) + 1;

      final dateKey =
          '${item.timestamp.year}-${item.timestamp.month.toString().padLeft(2, '0')}-${item.timestamp.day.toString().padLeft(2, '0')}';
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;

      if (item.resultCount != null) {
        totalResults += item.resultCount!;
        searchesWithResults++;
      }
    }

    final mostSearched =
        queryFrequency.entries.reduce((a, b) => a.value > b.value ? a : b);

    return SearchStatistics(
      totalSearches: _history.length,
      uniqueQueries: uniqueQueries.length,
      averageResultsPerSearch:
          searchesWithResults > 0 ? totalResults / searchesWithResults : 0.0,
      totalFavorites: _favorites.length,
      mostSearchedQuery: mostSearched.key,
      searchFrequency: queryFrequency,
      dailySearchCounts: dailyCounts,
    );
  }

  /// Export data to JSON
  Future<String> exportData() async {
    await _ensureInitialized();

    final data = {
      'history': _history.map((item) => item.toMap()).toList(),
      'favorites': _favorites.map((item) => item.toMap()).toList(),
      'collections': _collections.map((item) => item.toMap()).toList(),
      'tags': _tags.toList(),
      'preferences': _preferences.toMap(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    return jsonEncode(data);
  }

  /// Import data from JSON
  Future<void> importData(String jsonData, {bool merge = false}) async {
    await _ensureInitialized();

    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (!merge) {
        _history.clear();
        _favorites.clear();
        _collections.clear();
        _tags.clear();
      }

      // Import history
      if (data['history'] != null) {
        final historyData = data['history'] as List;
        final importedHistory = historyData
            .map((item) =>
                SearchHistoryItem.fromMap(item as Map<String, dynamic>))
            .toList();

        if (merge) {
          // Merge without duplicates
          for (final item in importedHistory) {
            if (!_history.any((existing) =>
                existing.query.toLowerCase() == item.query.toLowerCase() &&
                existing.timestamp == item.timestamp)) {
              _history.add(item);
            }
          }
          _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        } else {
          _history.addAll(importedHistory);
        }
      }

      // Import favorites
      if (data['favorites'] != null) {
        final favoritesData = data['favorites'] as List;
        final importedFavorites = favoritesData
            .map((item) => FavoriteItem.fromMap(item as Map<String, dynamic>))
            .toList();

        if (merge) {
          for (final item in importedFavorites) {
            if (!_favorites.any((existing) => existing.url == item.url)) {
              _favorites.add(item);
            }
          }
        } else {
          _favorites.addAll(importedFavorites);
        }
      }

      // Import collections
      if (data['collections'] != null) {
        final collectionsData = data['collections'] as List;
        final importedCollections = collectionsData
            .map((item) =>
                SearchCollection.fromMap(item as Map<String, dynamic>))
            .toList();

        _collections.addAll(importedCollections);
      }

      // Import tags
      if (data['tags'] != null) {
        _tags.addAll((data['tags'] as List).cast<String>());
      }

      // Import preferences
      if (data['preferences'] != null) {
        _preferences = SearchPreferences.fromMap(
            data['preferences'] as Map<String, dynamic>);
      }

      await _saveAllData();
      _historyController.add(List.from(_history));
      _favoritesController.add(List.from(_favorites));
    } catch (e) {
      throw Exception('Erro ao importar dados: $e');
    }
  }

  // Private methods

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadHistory(),
      _loadFavorites(),
      _loadTags(),
      _loadCollections(),
      _loadPreferences(),
    ]);
  }

  Future<void> _saveAllData() async {
    await Future.wait([
      _saveHistory(),
      _saveFavorites(),
      _saveTags(),
      _saveCollections(),
      _savePreferences(),
    ]);
  }

  Future<void> _loadHistory() async {
    final historyJson = _prefs.getString(_historyKey);
    if (historyJson != null) {
      try {
        final historyList = jsonDecode(historyJson) as List;
        _history.clear();
        _history.addAll(historyList.map(
            (item) => SearchHistoryItem.fromMap(item as Map<String, dynamic>)));
      } catch (e) {
        // Handle corrupted data
        await _prefs.remove(_historyKey);
      }
    }
  }

  Future<void> _saveHistory() async {
    final historyJson =
        jsonEncode(_history.map((item) => item.toMap()).toList());
    await _prefs.setString(_historyKey, historyJson);
  }

  Future<void> _loadFavorites() async {
    final favoritesJson = _prefs.getString(_favoritesKey);
    if (favoritesJson != null) {
      try {
        final favoritesList = jsonDecode(favoritesJson) as List;
        _favorites.clear();
        _favorites.addAll(favoritesList
            .map((item) => FavoriteItem.fromMap(item as Map<String, dynamic>)));
      } catch (e) {
        await _prefs.remove(_favoritesKey);
      }
    }
  }

  Future<void> _saveFavorites() async {
    final favoritesJson =
        jsonEncode(_favorites.map((item) => item.toMap()).toList());
    await _prefs.setString(_favoritesKey, favoritesJson);
  }

  Future<void> _loadTags() async {
    final tags = _prefs.getStringList(_tagsKey);
    if (tags != null) {
      _tags.clear();
      _tags.addAll(tags);
    }
  }

  Future<void> _saveTags() async {
    await _prefs.setStringList(_tagsKey, _tags.toList());
  }

  Future<void> _loadCollections() async {
    final collectionsJson = _prefs.getString(_collectionsKey);
    if (collectionsJson != null) {
      try {
        final collectionsList = jsonDecode(collectionsJson) as List;
        _collections.clear();
        _collections.addAll(collectionsList.map(
            (item) => SearchCollection.fromMap(item as Map<String, dynamic>)));
      } catch (e) {
        await _prefs.remove(_collectionsKey);
      }
    }
  }

  Future<void> _saveCollections() async {
    final collectionsJson =
        jsonEncode(_collections.map((item) => item.toMap()).toList());
    await _prefs.setString(_collectionsKey, collectionsJson);
  }

  Future<void> _loadPreferences() async {
    final preferencesJson = _prefs.getString(_preferencesKey);
    if (preferencesJson != null) {
      try {
        final preferencesMap =
            jsonDecode(preferencesJson) as Map<String, dynamic>;
        _preferences = SearchPreferences.fromMap(preferencesMap);
      } catch (e) {
        await _prefs.remove(_preferencesKey);
      }
    }
  }

  Future<void> _savePreferences() async {
    final preferencesJson = jsonEncode(_preferences.toMap());
    await _prefs.setString(_preferencesKey, preferencesJson);
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(1000000);
    return '${timestamp}_$random';
  }

  void dispose() {
    _historyController.close();
    _favoritesController.close();
  }
}

// Data models

/// Search history item
class SearchHistoryItem {
  final String id;
  final String query;
  final DateTime timestamp;
  final int? resultCount;
  final Duration? searchDuration;
  final Map<String, dynamic> metadata;

  const SearchHistoryItem({
    required this.id,
    required this.query,
    required this.timestamp,
    this.resultCount,
    this.searchDuration,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
      'searchDuration': searchDuration?.inMilliseconds,
      'metadata': metadata,
    };
  }

  factory SearchHistoryItem.fromMap(Map<String, dynamic> map) {
    return SearchHistoryItem(
      id: map['id'] as String,
      query: map['query'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      resultCount: map['resultCount'] as int?,
      searchDuration: map['searchDuration'] != null
          ? Duration(milliseconds: map['searchDuration'] as int)
          : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Favorite item
class FavoriteItem {
  final String id;
  final String title;
  final String url;
  final String snippet;
  final DateTime timestamp;
  final DateTime addedAt;
  final String? note;
  final List<String> tags;
  final String? collectionId;
  final int accessCount;
  final DateTime? lastAccessedAt;
  final String? originalSearchQuery;
  final double? relevanceScore;

  const FavoriteItem({
    required this.id,
    required this.title,
    required this.url,
    required this.snippet,
    required this.timestamp,
    required this.addedAt,
    this.note,
    this.tags = const [],
    this.collectionId,
    this.accessCount = 0,
    this.lastAccessedAt,
    this.originalSearchQuery,
    this.relevanceScore,
  });

  FavoriteItem copyWith({
    String? note,
    List<String>? tags,
    String? collectionId,
    int? accessCount,
    DateTime? lastAccessedAt,
  }) {
    return FavoriteItem(
      id: id,
      title: title,
      url: url,
      snippet: snippet,
      timestamp: timestamp,
      addedAt: addedAt,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      collectionId: collectionId ?? this.collectionId,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      originalSearchQuery: originalSearchQuery,
      relevanceScore: relevanceScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'snippet': snippet,
      'timestamp': timestamp.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
      'note': note,
      'tags': tags,
      'collectionId': collectionId,
      'accessCount': accessCount,
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'originalSearchQuery': originalSearchQuery,
      'relevanceScore': relevanceScore,
    };
  }

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      snippet: map['snippet'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      addedAt: DateTime.parse(map['addedAt'] as String),
      note: map['note'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      collectionId: map['collectionId'] as String?,
      accessCount: map['accessCount'] as int? ?? 0,
      lastAccessedAt: map['lastAccessedAt'] != null
          ? DateTime.parse(map['lastAccessedAt'] as String)
          : null,
      originalSearchQuery: map['originalSearchQuery'] as String?,
      relevanceScore: map['relevanceScore'] as double?,
    );
  }
}

/// Search collection
class SearchCollection {
  final String id;
  final String name;
  final String? description;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SearchCollection({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SearchCollection.fromMap(Map<String, dynamic> map) {
    return SearchCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

/// Search preferences
class SearchPreferences {
  final int maxHistoryItems;
  final int maxSuggestions;
  final bool enableAutoComplete;
  final bool enableSemanticSearch;
  final bool enableFuzzySearch;
  final bool saveSearchHistory;
  final Duration autoCleanupAfter;

  const SearchPreferences({
    this.maxHistoryItems = 1000,
    this.maxSuggestions = 10,
    this.enableAutoComplete = true,
    this.enableSemanticSearch = true,
    this.enableFuzzySearch = true,
    this.saveSearchHistory = true,
    this.autoCleanupAfter = const Duration(days: 30),
  });

  Map<String, dynamic> toMap() {
    return {
      'maxHistoryItems': maxHistoryItems,
      'maxSuggestions': maxSuggestions,
      'enableAutoComplete': enableAutoComplete,
      'enableSemanticSearch': enableSemanticSearch,
      'enableFuzzySearch': enableFuzzySearch,
      'saveSearchHistory': saveSearchHistory,
      'autoCleanupAfter': autoCleanupAfter.inDays,
    };
  }

  factory SearchPreferences.fromMap(Map<String, dynamic> map) {
    return SearchPreferences(
      maxHistoryItems: map['maxHistoryItems'] as int? ?? 1000,
      maxSuggestions: map['maxSuggestions'] as int? ?? 10,
      enableAutoComplete: map['enableAutoComplete'] as bool? ?? true,
      enableSemanticSearch: map['enableSemanticSearch'] as bool? ?? true,
      enableFuzzySearch: map['enableFuzzySearch'] as bool? ?? true,
      saveSearchHistory: map['saveSearchHistory'] as bool? ?? true,
      autoCleanupAfter: Duration(days: map['autoCleanupAfter'] as int? ?? 30),
    );
  }
}

/// Search statistics
class SearchStatistics {
  final int totalSearches;
  final int uniqueQueries;
  final double averageResultsPerSearch;
  final int totalFavorites;
  final String? mostSearchedQuery;
  final Map<String, int> searchFrequency;
  final Map<String, int> dailySearchCounts;

  const SearchStatistics({
    required this.totalSearches,
    required this.uniqueQueries,
    required this.averageResultsPerSearch,
    required this.totalFavorites,
    this.mostSearchedQuery,
    required this.searchFrequency,
    required this.dailySearchCounts,
  });
}

// Enums

enum FavoriteSortBy {
  addedDate,
  accessCount,
  lastAccessed,
  relevance,
  alphabetical,
}
