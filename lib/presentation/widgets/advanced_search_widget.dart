import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../infrastructure/core/search/advanced_search_engine.dart';

/// Advanced search widget with modern UI and animations
class AdvancedSearchWidget extends ConsumerStatefulWidget {
  final Function(SearchResults)? onResults;
  final Function(String)? onSearchChanged;
  final bool showFilters;
  final bool showSuggestions;
  final String? initialQuery;

  const AdvancedSearchWidget({
    super.key,
    this.onResults,
    this.onSearchChanged,
    this.showFilters = true,
    this.showSuggestions = true,
    this.initialQuery,
  });

  @override
  ConsumerState<AdvancedSearchWidget> createState() =>
      _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends ConsumerState<AdvancedSearchWidget>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late AnimationController _searchAnimationController;
  late AnimationController _filtersAnimationController;
  late AnimationController _loadingController;

  late Animation<double> _searchScaleAnimation;
  late Animation<double> _filtersHeightAnimation;
  late Animation<double> _searchGlowAnimation;

  final AdvancedLocalSearchEngine _searchEngine = AdvancedLocalSearchEngine();

  bool _isSearching = false;
  bool _showFilters = false;
  bool _showSuggestions = false;

  List<SearchSuggestion> _suggestions = [];
  SearchResults? _lastResults;
  Timer? _searchDebounceTimer;

  // Filter state
  final Set<String> _selectedContentTypes = {};
  final Set<String> _selectedSources = {};
  final Set<String> _selectedTags = {};
  DateRange? _selectedDateRange;
  SearchSortBy _sortBy = SearchSortBy.relevance;
  SearchSortOrder _sortOrder = SearchSortOrder.descending;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(text: widget.initialQuery);
    _searchFocusNode = FocusNode();

    _setupAnimations();
    _setupListeners();

    if (widget.initialQuery?.isNotEmpty ?? false) {
      _performSearch();
    }
  }

  void _setupAnimations() {
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _filtersAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _searchScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));

    _filtersHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filtersAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _searchGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupListeners() {
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchTextChanged() {
    widget.onSearchChanged?.call(_searchController.text);

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _updateSuggestions();
      } else {
        setState(() {
          _suggestions.clear();
          _showSuggestions = false;
        });
      }
    });
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _searchAnimationController.forward();
      if (_searchController.text.isNotEmpty && widget.showSuggestions) {
        _updateSuggestions();
      }
    } else {
      _searchAnimationController.reverse();
      setState(() => _showSuggestions = false);
    }
  }

  Future<void> _updateSuggestions() async {
    if (!widget.showSuggestions) return;

    final suggestions =
        await _searchEngine.getSuggestions(_searchController.text);

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty && _searchFocusNode.hasFocus;
      });
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isSearching = true);
    _loadingController.repeat();

    HapticFeedback.lightImpact();

    try {
      final query = AdvancedSearchQuery(
        query: _searchController.text.trim(),
        contentTypes: _selectedContentTypes.toList(),
        sources: _selectedSources.toList(),
        tags: _selectedTags.toList(),
        dateRange: _selectedDateRange,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        includeSnippets: true,
        includeFacets: widget.showFilters,
      );

      final results = await _searchEngine.search(query);

      setState(() {
        _lastResults = results;
        _isSearching = false;
        _showSuggestions = false;
      });

      widget.onResults?.call(results);

      if (results.hasError) {
        _showErrorSnackBar(results.error!);
      } else {
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      setState(() => _isSearching = false);
      _showErrorSnackBar('Erro na busca: $e');
    } finally {
      _loadingController.stop();
    }
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);

    if (_showFilters) {
      _filtersAnimationController.forward();
    } else {
      _filtersAnimationController.reverse();
    }

    HapticFeedback.lightImpact();
  }

  void _clearFilters() {
    setState(() {
      _selectedContentTypes.clear();
      _selectedSources.clear();
      _selectedTags.clear();
      _selectedDateRange = null;
      _sortBy = SearchSortBy.relevance;
      _sortOrder = SearchSortOrder.descending;
    });

    HapticFeedback.lightImpact();

    if (_searchController.text.isNotEmpty) {
      _performSearch();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Tentar novamente',
          textColor: Colors.white,
          onPressed: _performSearch,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    _filtersAnimationController.dispose();
    _loadingController.dispose();
    _searchEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildSearchBar(theme),
        if (_showSuggestions) _buildSuggestions(theme),
        if (widget.showFilters) _buildFiltersSection(theme),
        if (_lastResults != null) _buildResultsHeader(theme),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _searchScaleAnimation,
        _searchGlowAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _searchScaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(
                    0.1 + (_searchGlowAnimation.value * 0.2),
                  ),
                  blurRadius: 20 + (_searchGlowAnimation.value * 10),
                  offset: const Offset(0, 4),
                  spreadRadius: _searchGlowAnimation.value * 2,
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1 + (_searchGlowAnimation.value * 1),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: theme.colorScheme.primary,
                      size: 24,
                    )
                        .animate(
                          onPlay: (controller) => _isSearching
                              ? controller.repeat(reverse: true)
                              : controller.stop(),
                        )
                        .scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.2, 1.2),
                          duration: 500.ms,
                        ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar mensagens, conteúdo...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.bodyLarge,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    if (_isSearching) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                    if (_searchController.text.isNotEmpty && !_isSearching) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions.clear();
                            _showSuggestions = false;
                            _lastResults = null;
                          });
                        },
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    if (widget.showFilters) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _toggleFilters,
                        icon: AnimatedRotation(
                          turns: _showFilters ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.filter_list,
                            color: _hasActiveFilters()
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 8,
        shadowColor: theme.colorScheme.primary.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sugestões',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_suggestions.length, (index) {
              final suggestion = _suggestions[index];

              return ListTile(
                dense: true,
                leading: Icon(
                  _getSuggestionIcon(suggestion.type),
                  size: 18,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
                title: Text(
                  suggestion.suggestion,
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: suggestion.type != SearchSuggestionType.history
                    ? Text(
                        _getSuggestionTypeLabel(suggestion.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      )
                    : null,
                onTap: () {
                  _searchController.text = suggestion.suggestion;
                  _searchFocusNode.unfocus();
                  _performSearch();
                },
              )
                  .animate()
                  .fadeIn(
                    duration: 200.ms,
                    delay: Duration(milliseconds: index * 50),
                  )
                  .slideX(
                    begin: -0.2,
                    end: 0.0,
                    duration: 300.ms,
                    delay: Duration(milliseconds: index * 50),
                  );
            }).take(5),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return AnimatedBuilder(
      animation: _filtersHeightAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _filtersHeightAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFiltersHeader(theme),
                      const SizedBox(height: 16),
                      _buildContentTypeFilters(theme),
                      const SizedBox(height: 12),
                      _buildSortingOptions(theme),
                      const SizedBox(height: 12),
                      _buildDateRangeFilter(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filtros de Busca',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_hasActiveFilters())
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Limpar'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }

  Widget _buildContentTypeFilters(ThemeData theme) {
    final availableFilters = _searchEngine.getAvailableFilters();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Conteúdo',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: availableFilters.contentTypes.map((type) {
            final isSelected = _selectedContentTypes.contains(type);

            return FilterChip(
              label: Text(_formatContentType(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedContentTypes.add(type);
                  } else {
                    _selectedContentTypes.remove(type);
                  }
                });

                if (_searchController.text.isNotEmpty) {
                  _performSearch();
                }
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
            ).animate().scale(
                  duration: 200.ms,
                  curve: Curves.elasticOut,
                );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortingOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ordenação',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<SearchSortBy>(
                value: _sortBy,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: SearchSortBy.values.map((sortBy) {
                  return DropdownMenuItem(
                    value: sortBy,
                    child: Text(_formatSortBy(sortBy)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                    if (_searchController.text.isNotEmpty) {
                      _performSearch();
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                setState(() {
                  _sortOrder = _sortOrder == SearchSortOrder.ascending
                      ? SearchSortOrder.descending
                      : SearchSortOrder.ascending;
                });

                if (_searchController.text.isNotEmpty) {
                  _performSearch();
                }
              },
              icon: AnimatedRotation(
                turns: _sortOrder == SearchSortOrder.ascending ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.sort,
                  color: theme.colorScheme.primary,
                ),
              ),
              tooltip: _sortOrder == SearchSortOrder.ascending
                  ? 'Crescente'
                  : 'Decrescente',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(ThemeData theme) {
    final availableFilters = _searchEngine.getAvailableFilters();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...availableFilters.dateRanges.map((range) {
              final isSelected = _selectedDateRange == range;

              return FilterChip(
                label: Text(range.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedDateRange = selected ? range : null;
                  });

                  if (_searchController.text.isNotEmpty) {
                    _performSearch();
                  }
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                checkmarkColor: theme.colorScheme.primary,
              );
            }),
            if (_selectedDateRange != null)
              ActionChip(
                label: const Text('Personalizar'),
                onPressed: _showDateRangePicker,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsHeader(ThemeData theme) {
    final results = _lastResults!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          results.hasError
                              ? 'Erro na busca'
                              : '${results.totalCount} resultado${results.totalCount != 1 ? 's' : ''} encontrado${results.totalCount != 1 ? 's' : ''}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          results.hasError
                              ? results.error!
                              : 'Busca realizada em ${results.searchTime.inMilliseconds}ms',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: results.hasError
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!results.hasError && results.metadata.isNotEmpty)
                    IconButton(
                      onPressed: () => _showSearchMetadata(results),
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Detalhes da busca',
                    ),
                ],
              ),
              if (results.facets.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFacets(theme, results.facets),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacets(ThemeData theme, Map<String, List<FacetValue>> facets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refinar por:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...facets.entries.take(2).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFacetName(entry.key),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entry.value.take(5).map((facet) {
                    return Chip(
                      label: Text('${facet.value} (${facet.count})'),
                      labelStyle: theme.textTheme.bodySmall,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                      backgroundColor: Colors.transparent,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Helper methods

  bool _hasActiveFilters() {
    return _selectedContentTypes.isNotEmpty ||
        _selectedSources.isNotEmpty ||
        _selectedTags.isNotEmpty ||
        _selectedDateRange != null ||
        _sortBy != SearchSortBy.relevance;
  }

  IconData _getSuggestionIcon(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.history:
        return Icons.history;
      case SearchSuggestionType.content:
        return Icons.article;
      case SearchSuggestionType.semantic:
        return Icons.psychology;
      case SearchSuggestionType.trending:
        return Icons.trending_up;
    }
  }

  String _getSuggestionTypeLabel(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.history:
        return 'Histórico';
      case SearchSuggestionType.content:
        return 'Conteúdo';
      case SearchSuggestionType.semantic:
        return 'Semântico';
      case SearchSuggestionType.trending:
        return 'Tendência';
    }
  }

  String _formatContentType(String type) {
    final formatted = {
      'user_message': 'Perguntas',
      'ai_response': 'Respostas IA',
      'chat': 'Conversa',
      'document': 'Documento',
      'image': 'Imagem',
      'code': 'Código',
    };

    return formatted[type] ?? type;
  }

  String _formatSortBy(SearchSortBy sortBy) {
    switch (sortBy) {
      case SearchSortBy.relevance:
        return 'Relevância';
      case SearchSortBy.date:
        return 'Data';
      case SearchSortBy.title:
        return 'Título';
      case SearchSortBy.source:
        return 'Fonte';
    }
  }

  String _formatFacetName(String facetName) {
    final formatted = {
      'content_type': 'Tipo de Conteúdo',
      'source': 'Fonte',
      'tags': 'Tags',
    };

    return formatted[facetName] ?? facetName;
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange != null
          ? DateTimeRange(
              start: _selectedDateRange!.start,
              end: _selectedDateRange!.end,
            )
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = DateRange(
          label: 'Personalizado',
          start: picked.start,
          end: picked.end,
        );
      });

      if (_searchController.text.isNotEmpty) {
        _performSearch();
      }
    }
  }

  void _showSearchMetadata(SearchResults results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes da Busca'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMetadataItem(
                  'Tempo de busca', '${results.searchTime.inMilliseconds}ms'),
              _buildMetadataItem(
                  'Total de resultados', '${results.totalCount}'),
              _buildMetadataItem('Página atual', '${results.query.page}'),
              _buildMetadataItem(
                  'Resultados por página', '${results.query.pageSize}'),
              if (results.metadata.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Metadados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...results.metadata.entries.map((entry) =>
                    _buildMetadataItem(entry.key, entry.value.toString())),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$key:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
