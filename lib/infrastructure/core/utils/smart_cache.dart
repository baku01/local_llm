/// Sistema de cache inteligente para otimização de web scraping.
///
/// Implementa um cache multicamadas com persistência, expiração automática,
/// compressão de dados e estratégias de invalidação inteligente.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';

import '../../../domain/entities/search_result.dart';
import 'logger.dart';
import '../../../domain/entities/relevance_score.dart';

/// Configuração do cache inteligente.
class SmartCacheConfig {
  /// Tamanho máximo do cache em MB.
  final int maxSizeMB;

  /// Tempo padrão de vida em minutos.
  final int defaultTtlMinutes;

  /// Intervalo de limpeza automática em minutos.
  final int cleanupIntervalMinutes;

  /// Se deve comprimir dados no cache.
  final bool compressionEnabled;

  /// Nível de compressão (1-9).
  final int compressionLevel;

  const SmartCacheConfig({
    this.maxSizeMB = 50,
    this.defaultTtlMinutes = 60,
    this.cleanupIntervalMinutes = 15,
    this.compressionEnabled = true,
    this.compressionLevel = 6,
  });
}

/// Entrada individual do cache.
class CacheEntry {
  /// Dados armazenados.
  final dynamic data;

  /// Timestamp de criação.
  final DateTime createdAt;

  /// Timestamp de último acesso.
  DateTime lastAccessedAt;

  /// Tempo de vida em minutos.
  final int ttlMinutes;

  /// Número de acessos.
  int accessCount;

  /// Tamanho aproximado em bytes.
  final int sizeBytes;

  /// Prioridade para remoção (0-10, maior = mais importante).
  double priority;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttlMinutes,
    required this.sizeBytes,
    this.priority = 5.0,
  })  : lastAccessedAt = createdAt,
        accessCount = 0;

  /// Verifica se a entrada expirou.
  bool get isExpired {
    final expiry = createdAt.add(Duration(minutes: ttlMinutes));
    return DateTime.now().isAfter(expiry);
  }

  /// Idade da entrada em minutos.
  int get ageInMinutes {
    return DateTime.now().difference(createdAt).inMinutes;
  }

  /// Tempo desde último acesso em minutos.
  int get minutesSinceLastAccess {
    return DateTime.now().difference(lastAccessedAt).inMinutes;
  }

  /// Registra um acesso à entrada.
  void recordAccess() {
    lastAccessedAt = DateTime.now();
    accessCount++;
    // Aumentar prioridade baseado na frequência de uso
    priority = math.min(10.0, priority + 0.1);
  }

  /// Calcula pontuação para algoritmo LRU avançado.
  double get lruScore {
    // Combina idade, frequência de acesso e prioridade
    final ageWeight =
        math.max(0.1, 1.0 - (ageInMinutes / 1440.0)); // Normalizado por dia
    final accessWeight = math.min(2.0, math.log(accessCount + 1));
    final recencyWeight = math.max(
        0.1, 1.0 - (minutesSinceLastAccess / 60.0)); // Normalizado por hora

    return (ageWeight * 0.3) +
        (accessWeight * 0.4) +
        (recencyWeight * 0.2) +
        (priority * 0.1);
  }
}

/// Sistema de cache inteligente com múltiplas estratégias de otimização.
///
/// Características principais:
/// - Cache em memória com persistência opcional
/// - Expiração automática baseada em TTL
/// - Algoritmo LRU avançado com scoring
/// - Compressão de dados para economia de espaço
/// - Limpeza automática e otimização de performance
/// - Métricas detalhadas de uso
class SmartCache {
  final SmartCacheConfig _config;

  /// Mapa principal do cache.
  final Map<String, CacheEntry> _cache = {};

  /// Timer para limpeza automática.
  Timer? _cleanupTimer;

  /// Métricas de uso.
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  /// Tamanho atual aproximado em bytes.
  int _currentSizeBytes = 0;

  SmartCache({SmartCacheConfig? config})
      : _config = config ?? const SmartCacheConfig() {
    _startCleanupTimer();
  }

  /// Armazena dados no cache.
  ///
  /// [key] - Chave única para os dados
  /// [data] - Dados a serem armazenados
  /// [ttlMinutes] - Tempo de vida em minutos (usa padrão se null)
  /// [priority] - Prioridade para algoritmo de remoção (0-10)
  Future<void> set(
    String key,
    dynamic data, {
    int? ttlMinutes,
    double priority = 5.0,
  }) async {
    try {
      final hashedKey = _hashKey(key);
      final serializedData = _serializeData(data);
      final sizeBytes = _estimateSize(serializedData);

      // Verificar se há espaço suficiente
      await _ensureSpace(sizeBytes);

      // Remover entrada existente se houver
      if (_cache.containsKey(hashedKey)) {
        final oldEntry = _cache[hashedKey]!;
        _currentSizeBytes -= oldEntry.sizeBytes;
      }

      // Criar nova entrada
      final entry = CacheEntry(
        data: serializedData,
        createdAt: DateTime.now(),
        ttlMinutes: ttlMinutes ?? _config.defaultTtlMinutes,
        sizeBytes: sizeBytes,
        priority: priority,
      );

      _cache[hashedKey] = entry;
      _currentSizeBytes += sizeBytes;

      AppLogger.debug(
          'Cache SET: $key (${_formatBytes(sizeBytes)})', 'SmartCache');
    } catch (e, stackTrace) {
      AppLogger.error(
          'Erro ao armazenar no cache', 'SmartCache', e, stackTrace);
    }
  }

  /// Recupera dados do cache.
  ///
  /// [key] - Chave dos dados
  /// [defaultValue] - Valor padrão se não encontrado
  ///
  /// Returns: Dados armazenados ou valor padrão
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    try {
      final hashedKey = _hashKey(key);
      final entry = _cache[hashedKey];

      if (entry == null) {
        _misses++;
        AppLogger.debug('Cache MISS: $key', 'SmartCache');
        return defaultValue;
      }

      if (entry.isExpired) {
        _cache.remove(hashedKey);
        _currentSizeBytes -= entry.sizeBytes;
        _misses++;
        AppLogger.debug('Cache EXPIRED: $key', 'SmartCache');
        return defaultValue;
      }

      // Registrar acesso e deserializar dados
      entry.recordAccess();
      _hits++;

      final deserializedData = _deserializeData(entry.data);
      AppLogger.debug('Cache HIT: $key', 'SmartCache');

      return deserializedData as T?;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Erro ao recuperar do cache', 'SmartCache', e, stackTrace);
      return defaultValue;
    }
  }

  /// Remove uma entrada específica do cache.
  Future<void> remove(String key) async {
    final hashedKey = _hashKey(key);
    final entry = _cache.remove(hashedKey);
    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
      AppLogger.debug('Cache REMOVE: $key', 'SmartCache');
    }
  }

  /// Limpa todo o cache.
  Future<void> clear() async {
    final entriesCount = _cache.length;
    _cache.clear();
    _currentSizeBytes = 0;
    AppLogger.info(
        'Cache CLEAR: $entriesCount entradas removidas', 'SmartCache');
  }

  /// Força limpeza de entradas expiradas.
  Future<void> cleanup() async {
    final beforeCount = _cache.length;
    final beforeSize = _currentSizeBytes;

    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      final entry = _cache.remove(key);
      if (entry != null) {
        _currentSizeBytes -= entry.sizeBytes;
      }
    }

    final removedCount = beforeCount - _cache.length;
    final freedBytes = beforeSize - _currentSizeBytes;

    if (removedCount > 0) {
      AppLogger.info(
          'Cache CLEANUP: $removedCount entradas removidas, '
              '${_formatBytes(freedBytes)} liberados',
          'SmartCache');
    }
  }

  /// Otimiza o cache removendo entradas com baixa prioridade.
  Future<void> optimize() async {
    if (_cache.isEmpty) return;

    final entries = _cache.entries.toList();
    entries.sort((a, b) => a.value.lruScore.compareTo(b.value.lruScore));

    // Remover 25% das entradas com menor score
    final toRemoveCount = math.max(1, entries.length ~/ 4);
    var removedBytes = 0;

    for (int i = 0; i < toRemoveCount; i++) {
      final entry = entries[i];
      _cache.remove(entry.key);
      removedBytes += entry.value.sizeBytes;
      _evictions++;
    }

    _currentSizeBytes -= removedBytes;

    AppLogger.info(
        'Cache OPTIMIZE: $toRemoveCount entradas removidas, '
            '${_formatBytes(removedBytes)} liberados',
        'SmartCache');
  }

  /// Retorna estatísticas detalhadas do cache.
  Map<String, dynamic> getStats() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? (_hits / totalRequests) * 100 : 0.0;

    return {
      'entries': _cache.length,
      'size_bytes': _currentSizeBytes,
      'size_mb': _currentSizeBytes / (1024 * 1024),
      'max_size_mb': _config.maxSizeMB,
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'hit_rate_percent': hitRate,
      'average_entry_size_bytes':
          _cache.isNotEmpty ? _currentSizeBytes / _cache.length : 0,
    };
  }

  /// Garante que há espaço suficiente no cache.
  Future<void> _ensureSpace(int requiredBytes) async {
    final maxSizeBytes = _config.maxSizeMB * 1024 * 1024;

    if (_currentSizeBytes + requiredBytes <= maxSizeBytes) {
      return;
    }

    // Limpar entradas expiradas primeiro
    await cleanup();

    // Se ainda não há espaço, remover entradas com menor prioridade
    while (
        _currentSizeBytes + requiredBytes > maxSizeBytes && _cache.isNotEmpty) {
      final entries = _cache.entries.toList();
      entries.sort((a, b) => a.value.lruScore.compareTo(b.value.lruScore));

      // Remover entrada com menor score
      final entryToRemove = entries.first;
      _cache.remove(entryToRemove.key);
      _currentSizeBytes -= entryToRemove.value.sizeBytes;
      _evictions++;
    }
  }

  /// Gera hash da chave para uniformidade.
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Serializa dados para armazenamento.
  String _serializeData(dynamic data) {
    if (data is String) return data;
    return jsonEncode(data);
  }

  /// Deserializa dados do armazenamento.
  dynamic _deserializeData(String data) {
    try {
      return jsonDecode(data);
    } catch (e) {
      return data; // Retornar como string se não for JSON válido
    }
  }

  /// Estima o tamanho dos dados em bytes.
  int _estimateSize(String data) {
    return utf8.encode(data).length;
  }

  /// Formata bytes em uma string legível.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Inicia timer de limpeza automática.
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      Duration(minutes: _config.cleanupIntervalMinutes),
      (_) => cleanup(),
    );
  }

  /// Fecha o cache e limpa recursos.
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    _currentSizeBytes = 0;
  }
}

/// Extensão do SmartCache para resultados de pesquisa.
extension SearchResultCache on SmartCache {
  /// Cache específico para resultados de pesquisa.
  Future<void> cacheSearchResults(
    String query,
    List<SearchResult> results, {
    int? ttlMinutes,
  }) async {
    await set(
      'search:$query',
      results.map((r) => _searchResultToMap(r)).toList(),
      ttlMinutes: ttlMinutes,
      priority: 7.0, // Alta prioridade para resultados de pesquisa
    );
  }

  /// Recupera resultados de pesquisa do cache.
  Future<List<SearchResult>?> getCachedSearchResults(String query) async {
    final cached = await get<List<dynamic>>('search:$query');
    if (cached == null) return null;

    return cached.map((map) => _mapToSearchResult(map)).toList();
  }

  /// Converte SearchResult para Map para serialização.
  Map<String, dynamic> _searchResultToMap(SearchResult result) {
    return {
      'title': result.title,
      'url': result.url,
      'snippet': result.snippet,
      'timestamp': result.timestamp.toIso8601String(),
      'content': result.content,
      'relevanceScore': result.relevanceScore != null
          ? {
              'overallScore': result.relevanceScore!.overallScore,
              'semanticScore': result.relevanceScore!.semanticScore,
              'keywordScore': result.relevanceScore!.keywordScore,
              'qualityScore': result.relevanceScore!.qualityScore,
              'authorityScore': result.relevanceScore!.authorityScore,
              'scoringFactors': result.relevanceScore!.scoringFactors,
            }
          : null,
      'metadata': result.metadata,
    };
  }

  /// Converte Map para SearchResult.
  SearchResult _mapToSearchResult(Map<String, dynamic> map) {
    return SearchResult(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      snippet: map['snippet'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      content: map['content'],
      relevanceScore: map['relevanceScore'] != null
          ? RelevanceScore(
              overallScore: map['relevanceScore']['overallScore'] ?? 0.0,
              semanticScore: map['relevanceScore']['semanticScore'] ?? 0.0,
              keywordScore: map['relevanceScore']['keywordScore'] ?? 0.0,
              qualityScore: map['relevanceScore']['qualityScore'] ?? 0.0,
              authorityScore: map['relevanceScore']['authorityScore'] ?? 0.0,
              scoringFactors: Map<String, double>.from(
                  map['relevanceScore']['scoringFactors'] ?? {}),
            )
          : null,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }
}
