/// Interface principal de chat da aplicação.
///
/// Widget responsável por exibir o histórico de mensagens,
/// área de entrada de texto e indicadores de estado como
/// carregamento e processamento de "pensamento".
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/chat_message.dart';
import 'chat_bubble.dart';
import 'animated_logo.dart';
import 'thinking_animation.dart';

/// Widget principal da interface de chat.
///
/// Gerencia a exibição de:
/// - Lista de mensagens do histórico
/// - Estado vazio com logo animado
/// - Indicadores de carregamento e processamento
/// - Área de entrada de texto com botão de envio
/// - Animações de "pensamento" para modelos R1
class ChatInterface extends StatelessWidget {
  /// Lista de mensagens do chat atual.
  final List<ChatMessage> messages;

  /// Controlador do campo de entrada de texto.
  final TextEditingController textController;

  /// Callback executado quando uma mensagem é enviada.
  final VoidCallback onSendMessage;

  /// Indica se uma resposta está sendo gerada.
  final bool isLoading;

  /// Indica se o modelo está no processo de "pensamento".
  final bool isThinking;

  /// Texto atual do pensamento (para modelos R1).
  final String? currentThinking;

  /// Nome do modelo selecionado para verificar se é R1.
  final String? selectedModelName;

  /// Construtor da interface de chat.
  const ChatInterface({
    super.key,
    required this.messages,
    required this.textController,
    required this.onSendMessage,
    this.isLoading = false,
    this.isThinking = false,
    this.currentThinking,
    this.selectedModelName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context)
                : _buildMessageList(context),
          ),
          if (isThinking && currentThinking != null)
            ThinkingAnimation(thinkingText: currentThinking!, isVisible: true),
          if (isLoading) _buildLoadingIndicator(context),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];

        return ChatBubble(
          message: message,
          thinkingText: message.thinkingText,
          showThinking: !message.isUser && message.thinkingText != null,
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: (index * 50).ms)
            .slideX(
              begin: message.isUser ? 0.3 : -0.3,
              end: 0,
              curve: Curves.easeOutCubic,
              duration: 600.ms,
            )
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              curve: Curves.easeOutBack,
              duration: 500.ms,
            );
      },
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Gerando resposta...',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
            spreadRadius: -3,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.cardColor,
            Color.lerp(theme.cardColor,
                    theme.colorScheme.primary.withValues(alpha: 0.03), 0.5) ??
                theme.cardColor,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: TextField(
                controller: textController,
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.attach_file_rounded,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        onPressed: () {
                          // Implementar anexo de arquivos no futuro
                        },
                        tooltip: 'Anexar arquivo (em breve)',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.mic_rounded,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        onPressed: () {
                          // Implementar reconhecimento de voz no futuro
                        },
                        tooltip: 'Entrada por voz (em breve)',
                      ),
                    ],
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
                onSubmitted: (_) => onSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: isLoading ? null : onSendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isLoading
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                color: isLoading
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isLoading
                    ? null
                    : [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: -3,
                        ),
                      ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        key: const ValueKey('send'),
                        Icons.send_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(
                  duration: 3.seconds,
                  delay: 1.seconds,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 0.4),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 64, // Subtract padding
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  AnimatedLogo(
                      size: 100,
                      color: theme.colorScheme.primary,
                      showIntro: true),
                  const SizedBox(height: 32),
                  Text(
                    'Local LLM Chat',
                    style: TextStyle(
                      fontSize: 28,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Text(
                    'Converse com modelos de IA localmente',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 40),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3.5,
                      children: [
                        _SuggestionCard(
                          icon: Icons.code,
                          label: 'Ajuda com código',
                          onTap: () => textController.text =
                              'Me ajude a escrever um código',
                        ),
                        _SuggestionCard(
                          icon: Icons.lightbulb_outline,
                          label: 'Ideias criativas',
                          onTap: () => textController.text =
                              'Preciso de ideias criativas para',
                        ),
                        _SuggestionCard(
                          icon: Icons.school,
                          label: 'Explicar conceitos',
                          onTap: () => textController.text =
                              'Explique de forma simples o conceito de',
                        ),
                        _SuggestionCard(
                          icon: Icons.analytics,
                          label: 'Análise de dados',
                          onTap: () => textController.text =
                              'Ajude-me a analisar estes dados',
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 800.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -2.0 : 0.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: _isHovered
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: _isHovered
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
