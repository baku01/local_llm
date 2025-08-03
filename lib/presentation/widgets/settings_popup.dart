/// Popup de configurações da aplicação.
///
/// Widget modal que exibe todas as configurações disponíveis da aplicação,
/// incluindo seleção de modelos LLM, configurações de pesquisa web,
/// controles de streaming e ações de limpeza do chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/llm_model.dart';

/// Popup modal para configurações da aplicação LLM.
///
/// Este widget apresenta uma interface completa de configurações que inclui:
/// - Seleção de modelo LLM ativo
/// - Toggle para pesquisa web
/// - Toggle para modo streaming
/// - Botão para limpar histórico do chat
/// - Botão para atualizar lista de modelos
/// - Tratamento de estados de carregamento e erro
///
/// O popup mantém estado interno sincronizado com as configurações
/// externas e propaga mudanças através de callbacks.
class SettingsPopup extends StatefulWidget {
  /// Lista de modelos LLM disponíveis para seleção.
  final List<LlmModel> models;

  /// Modelo atualmente selecionado.
  final LlmModel? selectedModel;

  /// Callback executado quando um novo modelo é selecionado.
  final ValueChanged<LlmModel?> onModelSelected;

  /// Indica se a aplicação está carregando modelos.
  final bool isLoading;

  /// Callback para atualizar a lista de modelos.
  final VoidCallback onRefreshModels;

  /// Mensagem de erro atual, se houver.
  final String? errorMessage;

  /// Estado atual da pesquisa web.
  final bool webSearchEnabled;

  /// Callback para alternar pesquisa web.
  final ValueChanged<bool> onWebSearchToggle;

  /// Indica se uma pesquisa web está em andamento.
  final bool isSearching;

  /// Estado atual do streaming.
  final bool streamingEnabled;

  /// Callback para alternar streaming.
  final ValueChanged<bool> onStreamingToggle;

  /// Callback para limpar o chat (opcional).
  final VoidCallback? onClearChat;

  /// Cria uma nova instância do popup de configurações.
  const SettingsPopup({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
    required this.isLoading,
    required this.onRefreshModels,
    this.errorMessage,
    required this.webSearchEnabled,
    required this.onWebSearchToggle,
    required this.isSearching,
    required this.streamingEnabled,
    required this.onStreamingToggle,
    this.onClearChat,
  });

  @override
  State<SettingsPopup> createState() => _SettingsPopupState();
}

class _SettingsPopupState extends State<SettingsPopup> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.9,
              maxWidth: 500,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: -6,
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com gradiente
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Configurações',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (widget.onClearChat != null)
                            IconButton(
                              onPressed: () {
                                widget.onClearChat!();
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 24,
                              ),
                              tooltip: 'Limpar conversa',
                            ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 24,
                            ),
                            tooltip: 'Fechar',
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Seleção de Modelo
                          _buildSection(
                            context,
                            'Seleção de Modelo',
                            _buildModelDropdown(context),
                          ),

                          const SizedBox(height: 24),

                          // Pesquisa Web
                          _buildSection(
                            context,
                            'Pesquisa Web',
                            _buildToggle(
                              context,
                              'Habilitar pesquisa web',
                              widget.webSearchEnabled,
                              widget.onWebSearchToggle,
                              isLoading: widget.isSearching,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Streaming
                          _buildSection(
                            context,
                            'Streaming',
                            _buildToggle(
                              context,
                              'Habilitar streaming',
                              widget.streamingEnabled,
                              widget.onStreamingToggle,
                            ),
                          ),

                          // Mensagem de erro
                           if (widget.errorMessage != null) ...[
                             const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.errorMessage!,
                                      style: TextStyle(
                                        color: theme.colorScheme.onErrorContainer,
                                        fontSize: 14,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Botões de ação
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Fechar'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: widget.onRefreshModels,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Atualizar Modelos'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildSection(BuildContext context, String title, Widget child) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildModelDropdown(BuildContext context) {
    final theme = Theme.of(context);
    
    // Remove duplicatas baseado no nome do modelo
    final uniqueModels = <String, LlmModel>{};
    for (final model in widget.models) {
      uniqueModels[model.name] = model;
    }
    final models = uniqueModels.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LlmModel>(
          value: widget.selectedModel,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hint: Text(
            widget.isLoading ? 'Carregando modelos...' : 'Selecione um modelo',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          items: models.map((model) {
            return DropdownMenuItem<LlmModel>(
              value: model,
              child: Text(
                model.name,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.isLoading ? null : widget.onModelSelected,
        ),
      ),
    );
  }

  Widget _buildToggle(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
