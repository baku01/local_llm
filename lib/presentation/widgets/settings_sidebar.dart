import 'package:flutter/material.dart';
import '../../domain/entities/llm_model.dart';

class SettingsSidebar extends StatelessWidget {
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

  const SettingsSidebar({
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configurações',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Seção de Modelos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Modelos LLM',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: isLoading ? null : onRefreshModels,
                        icon: isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        tooltip: 'Atualizar modelos',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error,
                            color: theme.colorScheme.onErrorContainer,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (models.isEmpty && !isLoading)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nenhum modelo encontrado',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (models.isNotEmpty)
                    DropdownButtonFormField<LlmModel>(
                      value: selectedModel,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: models.map((model) {
                        return DropdownMenuItem<LlmModel>(
                          value: model,
                          child: Tooltip(
                            message: model.name,
                            child: Text(
                              _formatModelName(model.name),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: onModelSelected,
                      hint: const Text('Selecione um modelo'),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Pesquisa Web
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesquisa Web',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 20,
                          color: webSearchEnabled 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Buscar na web',
                            style: TextStyle(
                              fontSize: 14,
                              color: webSearchEnabled 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.onSurface,
                              fontWeight: webSearchEnabled 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: isSearching 
                        ? Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pesquisando...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            webSearchEnabled 
                                ? 'Contexto web incluído nas respostas'
                                : 'Apenas conhecimento do modelo',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                    value: webSearchEnabled,
                    onChanged: onWebSearchToggle,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Modo Streaming
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo Streaming',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(
                          Icons.stream,
                          size: 20,
                          color: streamEnabled 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Resposta em tempo real',
                            style: TextStyle(
                              fontSize: 14,
                              color: streamEnabled 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.onSurface,
                              fontWeight: streamEnabled 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      streamEnabled 
                          ? 'Resposta aparece enquanto é gerada'
                          : 'Resposta aparece completa ao final',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: streamEnabled,
                    onChanged: onStreamToggle,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informações do Sistema
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.computer,
                    label: 'Servidor',
                    value: 'localhost:11434',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.memory,
                    label: 'Modelos',
                    value: '${models.length} disponíveis',
                  ),
                  if (selectedModel != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.smart_toy,
                      label: 'Ativo',
                      value: selectedModel!.name,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: webSearchEnabled ? Icons.wifi : Icons.wifi_off,
                    label: 'Pesquisa Web',
                    value: webSearchEnabled ? 'Habilitada' : 'Desabilitada',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: streamEnabled ? Icons.stream : Icons.stop_circle,
                    label: 'Streaming',
                    value: streamEnabled ? 'Habilitado' : 'Desabilitado',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Rodapé
          Center(
            child: Column(
              children: [
                Text(
                  'Revolução IA v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ferramenta Popular de IA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '🔴 Pela democratização da tecnologia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _formatModelName(String name) {
    // Encurtar nomes longos
    if (name.length > 25) {
      return '${name.substring(0, 22)}...';
    }
    return name;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}