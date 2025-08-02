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

  /// Estado atual do modo streaming.
  final bool streamEnabled;

  /// Callback para alternar modo streaming.
  final ValueChanged<bool> onStreamToggle;

  /// Callback opcional para limpar o chat.
  final VoidCallback? onClearChat;

  /// Construtor do popup de configurações.
  ///
  /// Todos os parâmetros relacionados a callbacks são obrigatórios
  /// para garantir funcionalidade completa do popup.
  const SettingsPopup({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
    this.isLoading = false,
    required this.onRefreshModels,
    this.errorMessage,
    required this.webSearchEnabled,
    required this.onWebSearchToggle,
    this.isSearching = false,
    required this.streamEnabled,
    required this.onStreamToggle,
    this.onClearChat,
  });

  @override
  State<SettingsPopup> createState() => _SettingsPopupState();
}

/// Estado interno do popup de configurações.
///
/// Gerencia os valores locais dos toggles e sincroniza com
/// as configurações externas através de callbacks.
class _SettingsPopupState extends State<SettingsPopup> {
  /// Estado local do toggle de pesquisa web.
  late bool _webSearchEnabled;

  /// Estado local do toggle de streaming.
  late bool _streamEnabled;

  /// Inicializa o estado com os valores atuais das configurações.
  @override
  void initState() {
    super.initState();
    _webSearchEnabled = widget.webSearchEnabled;
    _streamEnabled = widget.streamEnabled;
  }

  /// Atualiza o estado local quando as configurações externas mudam.
  ///
  /// Garante que o popup sempre reflita o estado atual da aplicação
  /// mesmo se as configurações forem alteradas externamente.
  @override
  void didUpdateWidget(SettingsPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.webSearchEnabled != widget.webSearchEnabled) {
      _webSearchEnabled = widget.webSearchEnabled;
    }
    if (oldWidget.streamEnabled != widget.streamEnabled) {
      _streamEnabled = widget.streamEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: -6,
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
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
                          color: Colors.white.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.9),
                            size: 24,
                          ),
                          tooltip: 'Limpar conversa',
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.9),
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
                      // Model Selection
                      _buildSection(
                        context,
                        'Modelo LLM',
                        _buildModelDropdown(context),
                      ),

                      const SizedBox(height: 24),

                      // Web Search Toggle
                      _buildSection(
                        context,
                        'Busca Web',
                        _buildToggle(
                          context,
                          'Ativar busca na web',
                          _webSearchEnabled,
                          (value) {
                            setState(() {
                              _webSearchEnabled = value;
                            });
                            widget.onWebSearchToggle(value);
                          },
                          widget.isSearching,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stream Toggle
                      _buildSection(
                        context,
                        'Streaming',
                        _buildToggle(
                          context,
                          'Resposta em tempo real',
                          _streamEnabled,
                          (value) {
                            setState(() {
                              _streamEnabled = value;
                            });
                            widget.onStreamToggle(value);
                          },
                          false,
                        ),
                      ),

                      // Error Message
                      if (widget.errorMessage != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
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

                      const SizedBox(height: 24),

                      // Action buttons
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
        )
        .animate()
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildModelDropdown(BuildContext context) {
    final theme = Theme.of(context);

    // Remove duplicate models
    final uniqueModels = <String, LlmModel>{};
    for (final model in widget.models) {
      uniqueModels[model.name] = model;
    }
    final cleanModels = uniqueModels.values.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LlmModel>(
          value: widget.selectedModel,
          hint: const Text('Selecione um modelo'),
          isExpanded: true,
          items: cleanModels.map((model) {
            return DropdownMenuItem<LlmModel>(
              value: model,
              child: Text(
                model.name,
                style: const TextStyle(fontSize: 14),
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
    ValueChanged<bool> onChanged,
    bool isLoading,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
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
          const SizedBox(width: 12),
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
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
