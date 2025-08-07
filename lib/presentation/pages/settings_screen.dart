import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _apiUrlController;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backend = ref.watch(llmBackendProvider);
    final apiUrl = ref.watch(apiUrlProvider);
    final lmStudioUrl = ref.watch(lmStudioUrlProvider);
    final themeMode = ref.watch(themeModeProvider);

    final currentUrl = backend == LlmBackend.lmStudio ? lmStudioUrl : apiUrl;
    if (_apiUrlController.text != currentUrl) {
      _apiUrlController.text = currentUrl;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: PhosphorIcon(PhosphorIcons.arrowLeft()),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção Conexão
          _buildSectionHeader('Conexão', PhosphorIcons.globe()),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<LlmBackend>(
                    value: backend,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.computer),
                      labelText: 'Backend',
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: LlmBackend.ollama, child: Text('Ollama')),
                      DropdownMenuItem(
                          value: LlmBackend.lmStudio, child: Text('LM Studio')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(llmBackendProvider.notifier).state = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    backend == LlmBackend.lmStudio
                        ? 'URL da API LM Studio'
                        : 'URL da API Ollama',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _apiUrlController,
                    decoration: InputDecoration(
                      hintText: backend == LlmBackend.lmStudio
                          ? 'http://localhost:1234'
                          : 'http://localhost:11434',
                      prefixIcon: const Icon(Icons.link),
                    ),
                    onChanged: (value) {
                      if (backend == LlmBackend.lmStudio) {
                        ref.read(lmStudioUrlProvider.notifier).state = value;
                      } else {
                        ref.read(apiUrlProvider.notifier).state = value;
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    backend == LlmBackend.lmStudio
                        ? 'Configure a URL do servidor LM Studio. Use localhost:1234 para instalação local.'
                        : 'Configure a URL do servidor Ollama. Use localhost:11434 para instalação local.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Seção IA
          _buildSectionHeader('Inteligência Artificial', PhosphorIcons.robot()),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final webSearchEnabled =
                        ref.watch(webSearchEnabledProvider);
                    return SwitchListTile(
                      secondary: PhosphorIcon(PhosphorIcons.magnifyingGlass()),
                      title: const Text('Pesquisa Web'),
                      subtitle: const Text(
                          'Buscar informações na internet para respostas mais precisas'),
                      value: webSearchEnabled,
                      onChanged: (value) {
                        ref.read(webSearchEnabledProvider.notifier).state =
                            value;
                        // Sincronizar com o controller imediatamente
                        ref.read(llmControllerProvider).toggleWebSearch(value);
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                Consumer(
                  builder: (context, ref, child) {
                    final streamModeEnabled =
                        ref.watch(streamModeEnabledProvider);
                    return SwitchListTile(
                      secondary: PhosphorIcon(PhosphorIcons.lightning()),
                      title: const Text('Modo Streaming'),
                      subtitle: const Text(
                          'Receber respostas em tempo real conforme são geradas'),
                      value: streamModeEnabled,
                      onChanged: (value) {
                        ref.read(streamModeEnabledProvider.notifier).state =
                            value;
                        // Sincronizar com o controller imediatamente
                        ref.read(llmControllerProvider).toggleStreamMode(value);
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Seção Aparência
          _buildSectionHeader('Aparência', PhosphorIcons.palette()),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: PhosphorIcon(PhosphorIcons.moon()),
                  title: const Text('Tema'),
                  subtitle: Text(_getThemeModeText(themeMode)),
                  trailing: PhosphorIcon(PhosphorIcons.caretRight()),
                  onTap: () => _showThemeDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: PhosphorIcon(PhosphorIcons.chatCircle()),
                  title: const Text('Limpar Conversa'),
                  subtitle: const Text('Remove todas as mensagens do chat'),
                  trailing: PhosphorIcon(PhosphorIcons.trash()),
                  onTap: () => _showClearChatDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Seção Sobre
          _buildSectionHeader('Sobre', PhosphorIcons.info()),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: PhosphorIcon(PhosphorIcons.appWindow()),
                  title: const Text('Local LLM Chat'),
                  subtitle: const Text('Versão 1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: PhosphorIcon(PhosphorIcons.code()),
                  title: const Text('Código Fonte'),
                  subtitle: const Text('Disponível no GitHub'),
                  trailing: PhosphorIcon(PhosphorIcons.arrowSquareOut()),
                  onTap: () {
                    // Implementar abertura do GitHub
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, PhosphorIconData icon) {
    return Row(
      children: [
        PhosphorIcon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Tema'),
        content: Consumer(
          builder: (context, ref, child) {
            final currentTheme = ref.watch(themeModeProvider);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Claro'),
                  value: ThemeMode.light,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).state = value;
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Escuro'),
                  value: ThemeMode.dark,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).state = value;
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Sistema'),
                  value: ThemeMode.system,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).state = value;
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Conversa'),
        content: const Text(
          'Tem certeza que deseja remover todas as mensagens do chat? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(llmControllerProvider).clearChat();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversa limpa com sucesso'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}
