/// Widget para exibição dos resultados de pesquisa integrado à interface de chat.
///
/// Exibe os resultados da pesquisa web em um painel expansível e interativo
/// que se integra com a interface de chat principal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/search_result.dart';
import '../controllers/llm_controller.dart';
import '../providers/app_providers.dart';

/// Widget que exibe um painel de resultados de pesquisa web no chat.
class WebSearchResultsPanel extends ConsumerWidget {
  /// Constrói o painel de resultados de pesquisa web.
  const WebSearchResultsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(llmControllerProvider);
    final isSearching = controller.isSearching;
    final searchResults = controller.searchResults;
    final hasResults = searchResults.isNotEmpty;
    final webSearchEnabled = ref.watch(webSearchEnabledProvider);

    // Se a pesquisa web não está habilitada, não exibe nada
    if (!webSearchEnabled) return const SizedBox.shrink();

    // Se não está pesquisando e não tem resultados, não exibe nada
    if (!isSearching && !hasResults) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: isSearching || hasResults ? null : 0,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 0,
        bottom: isSearching || hasResults ? 8 : 0,
      ),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, ref, controller),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: hasResults
                  ? _buildResultsView(context, searchResults)
                  : isSearching
                      ? _buildSearchingIndicator(context)
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.2,
          end: 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
  }

  /// Constrói o cabeçalho do painel com botões de ação.
  Widget _buildHeader(
      BuildContext context, WidgetRef ref, LlmController controller) {
    final theme = Theme.of(context);
    final isSearching = controller.isSearching;
    final hasResults = controller.searchResults.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.globe(),
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isSearching
                ? 'Pesquisando na web...'
                : hasResults
                    ? 'Resultados da web'
                    : 'Pesquisa web',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (hasResults)
            Row(
              children: [
                _buildActionButton(
                  context: context,
                  icon: PhosphorIcons.arrowsClockwise(),
                  tooltip: 'Atualizar resultados',
                  onPressed: () {
                    // Implementar atualização de resultados
                  },
                ),
                _buildActionButton(
                  context: context,
                  icon: PhosphorIcons.x(),
                  tooltip: 'Limpar resultados',
                  onPressed: () {
                    controller.clearSearchResults();
                  },
                ),
              ],
            ),
          if (isSearching)
            _buildActionButton(
              context: context,
              icon: PhosphorIcons.x(),
              tooltip: 'Cancelar pesquisa',
              onPressed: () {
                // Implementar cancelamento de pesquisa
              },
            ),
        ],
      ),
    );
  }

  /// Constrói um botão de ação para o cabeçalho.
  Widget _buildActionButton({
    required BuildContext context,
    required PhosphorIconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: PhosphorIcon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  /// Constrói a visualização dos resultados da pesquisa.
  Widget _buildResultsView(BuildContext context, List<SearchResult> results) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (context, index) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final result = results[index];
          return _buildResultItem(context, result, index);
        },
      ),
    );
  }

  /// Constrói um item individual de resultado de pesquisa.
  Widget _buildResultItem(
      BuildContext context, SearchResult result, int index) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _launchUrl(result.url),
                    child: Text(
                      result.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.url,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            result.snippet,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (result.hasRelevanceScore)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getRelevanceColor(result.overallRelevance)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Relevância: ${(result.overallRelevance * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getRelevanceColor(result.overallRelevance),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            TextButton.icon(
              icon: PhosphorIcon(
                PhosphorIcons.arrowSquareOut(),
                size: 16,
              ),
              label: const Text('Abrir'),
              onPressed: () => _launchUrl(result.url),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o indicador de pesquisa em andamento.
  Widget _buildSearchingIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Buscando informações na web...',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Isso pode levar alguns segundos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtém a cor correspondente ao nível de relevância.
  Color _getRelevanceColor(double relevance) {
    if (relevance >= 0.8) {
      return Colors.green;
    } else if (relevance >= 0.6) {
      return Colors.blue;
    } else if (relevance >= 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Abre uma URL no navegador.
  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Erro ao abrir URL: $e');
    }
  }
}

/// Extension para adicionar o painel de resultados à interface de chat.
extension WebSearchResultsPanelExtension on Widget {
  /// Adiciona o painel de resultados de pesquisa acima do widget atual.
  Widget withWebSearchResultsPanel() {
    return Column(
      children: [
        const WebSearchResultsPanel(),
        Expanded(child: this),
      ],
    );
  }
}
