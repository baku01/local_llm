import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/app_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/llm_model.dart';
import '../widgets/thinking_animation.dart';
import 'settings_screen.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Otimização: usar select mais específicos para reduzir rebuilds
    final messages = ref.watch(
        llmControllerProvider.select((controller) => controller.messages));
    final selectedModel = ref.watch(
        llmControllerProvider.select((controller) => controller.selectedModel));
    final isReplying = ref.watch(
        llmControllerProvider.select((controller) => controller.isLoading));
    final isThinking = ref.watch(
        llmControllerProvider.select((controller) => controller.isThinking));
    final currentThinking = ref.watch(llmControllerProvider
        .select((controller) => controller.currentThinking));

    final llmController = ref.read(llmControllerProvider.notifier);

    // Sincronização otimizada para evitar loops e rebuilds desnecessários
    ref.listen(selectedModelProvider, (previous, next) {
      if (next != null &&
          previous != next &&
          (selectedModel == null || selectedModel.name != next.name)) {
        final domainModel = LlmModel(
          name: next.name,
          description: next.name,
          modifiedAt: next.modifiedAt,
          size: null,
        );
        llmController.selectModel(domainModel);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showModelSelector(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedModel?.description ??
                    selectedModel?.name ??
                    'Selecionar Modelo',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              PhosphorIcon(
                PhosphorIcons.caretDown(),
                size: 16,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: PhosphorIcon(PhosphorIcons.gear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty && !isReplying
                ? _buildEmptyState(context)
                : RepaintBoundary(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isReplying ? 1 : 0),
                      itemBuilder: (context, index) {
                        final messageIndex = index;

                        if (messageIndex == messages.length && isReplying) {
                          return RepaintBoundary(
                            child: ChatBubble(
                              message: ChatMessage(
                                text: '',
                                isUser: false,
                                timestamp: DateTime.now(),
                              ),
                              isTyping: true,
                            ).animate().fadeIn(duration: 250.ms).slideY(
                                  begin: 0.05,
                                  end: 0,
                                  duration: 250.ms,
                                  curve: Curves.easeOut,
                                ),
                          );
                        }

                        final message = messages[messageIndex];

                        return RepaintBoundary(
                          child: ChatBubble(
                            key: ValueKey(
                                'message_${message.timestamp.millisecondsSinceEpoch}'),
                            message: message,
                            thinkingText: message.thinkingText,
                            showThinking:
                                !message.isUser && message.thinkingText != null,
                          ).animate().fadeIn(duration: 250.ms).slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 250.ms,
                                curve: Curves.easeOut,
                              ),
                        );
                      },
                    ),
                  ),
          ),
          if (isThinking)
            RepaintBoundary(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ThinkingAnimation(
                  key: const ValueKey('thinking_animation'),
                  thinkingText: currentThinking ?? 'Analisando...',
                  isVisible: true,
                ),
              ),
            ),
          const ChatInputField(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado moderno
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 60,
                color: Colors.white,
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withValues(alpha: 0.3))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                ),

            const SizedBox(height: 32),

            // Título moderno
            Text(
              'Local LLM Chat',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ).createShader(
                          const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                  ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 200.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 16),

            // Subtítulo
            Text(
              'Converse com modelos de IA localmente\ncom privacidade total',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 400.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 48),

            // Cards de sugestão modernos
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildSuggestionCard(
                  context,
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Ideias Criativas',
                  subtitle: 'Brainstorming e inovação',
                ),
                _buildSuggestionCard(
                  context,
                  icon: Icons.code_rounded,
                  title: 'Programação',
                  subtitle: 'Ajuda com código',
                ),
                _buildSuggestionCard(
                  context,
                  icon: Icons.school_rounded,
                  title: 'Aprendizado',
                  subtitle: 'Explicações detalhadas',
                ),
                _buildSuggestionCard(
                  context,
                  icon: Icons.psychology_rounded,
                  title: 'Análise',
                  subtitle: 'Insights profundos',
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 600.ms)
                .slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    // Mapear títulos para sugestões específicas
    String getSuggestionText() {
      switch (title) {
        case 'Ideias Criativas':
          return 'Preciso de ideias criativas para';
        case 'Programação':
          return 'Me ajude a escrever um código';
        case 'Aprendizado':
          return 'Explique de forma simples o conceito de';
        case 'Análise':
          return 'Ajude-me a analisar estes dados';
        default:
          return 'Como posso ajudar você hoje?';
      }
    }

    return GestureDetector(
      onTap: () {
        // Usar o provider para preencher o campo de texto com a sugestão
        final ref = ProviderScope.containerOf(context)
            .read(suggestionTextProvider.notifier);
        ref.state = getSuggestionText();
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showModelSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            final maxHeight = screenHeight * 0.8;
            final minHeight = screenHeight * 0.3;

            return Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                minHeight: minHeight,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final availableModels = ref.watch(availableModelsProvider);
                  final selectedModel = ref.watch(selectedModelProvider);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Selecionar Modelo',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                ref
                                    .read(availableModelsProvider.notifier)
                                    .refresh();
                              },
                              icon:
                                  PhosphorIcon(PhosphorIcons.arrowClockwise()),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Content
                      Flexible(
                        child: availableModels.when(
                          data: (models) {
                            if (models.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text('Nenhum modelo encontrado'),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: models.length,
                              itemBuilder: (context, index) {
                                final model = models[index];
                                final isSelected =
                                    selectedModel?.name == model.name;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1)
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      model.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Tamanho: ${model.size}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.7)
                                            : null,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? AnimatedScale(
                                            scale: isSelected ? 1.0 : 0.0,
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: PhosphorIcon(
                                              PhosphorIcons.check(),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      // Usar setState para atualização imediata sem rebuild
                                      final notifier = ref
                                          .read(selectedModelProvider.notifier);
                                      notifier.state = model;
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Erro ao carregar modelos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    error.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref
                                          .read(
                                              availableModelsProvider.notifier)
                                          .refresh();
                                    },
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
