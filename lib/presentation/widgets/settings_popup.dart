/// Popup de configurações da aplicação.
/// 
/// Widget modal que exibe todas as configurações disponíveis da aplicação,
/// incluindo seleção de modelos LLM, configurações de pesquisa web,
/// controles de streaming e ações de limpeza do chat.
library;

import 'package:flutter/material.dart';
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
                      Icons.clear_all,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Limpar conversa',
                  ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Model Selection
            _buildSection(
              context,
              'Modelo LLM',
              _buildModelDropdown(context),
            ),
            
            const SizedBox(height: 20),
            
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
            
            const SizedBox(height: 20),
            
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: widget.onRefreshModels,
                  child: const Text('Atualizar Modelos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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