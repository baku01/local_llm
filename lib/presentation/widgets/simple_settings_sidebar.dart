import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/llm_model.dart';

class SimpleSettingsSidebar extends StatelessWidget {
  final List<LlmModel> models;
  final LlmModel? selectedModel;
  final ValueChanged<LlmModel?> onModelSelected;
  final bool isLoading;
  final VoidCallback onRefreshModels;
  final String? errorMessage;
  final bool webSearchEnabled;
  final ValueChanged<bool> onWebSearchToggle;
  final bool isSearching;
  final bool streamEnabled;
  final ValueChanged<bool> onStreamToggle;
  final VoidCallback? onClearChat;

  const SimpleSettingsSidebar({
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Config',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClearChat != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onClearChat,
                  icon: Icon(
                    Icons.clear_all,
                    color: theme.colorScheme.error,
                    size: 18,
                  ),
                  tooltip: 'Limpar conversa',
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Model Selection
          _buildSection(
            context,
            'Modelo',
            _buildModelDropdown(context),
          ),
          
          const SizedBox(height: 12),
          
          // Web Search Toggle  
          _buildToggle(
            context,
            'Busca web',
            webSearchEnabled,
            onWebSearchToggle,
            isSearching,
          ),
          
          const SizedBox(height: 12),
          
          // Stream Toggle
          _buildToggle(
            context,
            'Streaming',
            streamEnabled,
            onStreamToggle,
            false,
          ),
          
          const Spacer(),
          
          // Error Message
          if (errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
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
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LlmModel>(
          value: selectedModel,
          hint: Text(
            'Modelo',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          isExpanded: true,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          items: models.map((model) {
            return DropdownMenuItem<LlmModel>(
              value: model,
              child: Text(
                _truncateModelName(model.name),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: isLoading ? null : onModelSelected,
        ),
      ),
    );
  }

  String _truncateModelName(String name) {
    // Remove common suffixes and truncate long names
    String cleaned = name
        .replaceAll(':latest', '')
        .replaceAll(':8b', '')
        .replaceAll(':7b', '')
        .replaceAll(':4b', '')
        .replaceAll(':1.5b', '')
        .replaceAll(':0.6b', '');
    
    if (cleaned.length > 20) {
      return '${cleaned.substring(0, 17)}...';
    }
    return cleaned;
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      value: value,
                      onChanged: (val) => onChanged(val ?? false),
                      activeColor: theme.colorScheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}