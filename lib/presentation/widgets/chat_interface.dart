import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/llm_response.dart';
import 'thinking_animation.dart';
import 'animated_logo.dart';

class ChatInterface extends StatelessWidget {
  final List<ChatMessage> messages;
  final TextEditingController textController;
  final VoidCallback onSendMessage;
  final bool isLoading;
  final bool isThinking;
  final String? currentThinking;

  const ChatInterface({
    super.key,
    required this.messages,
    required this.textController,
    required this.onSendMessage,
    this.isLoading = false,
    this.isThinking = false,
    this.currentThinking,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatBubble(message: message)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: (50).ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
                        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0));
                  },
                ),
        ),
        if (isThinking && currentThinking != null)
          ThinkingAnimation(
            thinkingText: currentThinking!,
            isVisible: true,
          ),
        if (isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (isThinking)
                  ThinkingIndicator(isThinking: true)
                else ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gerando resposta...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 200.ms),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  ),
                  onSubmitted: (_) => onSendMessage(),
                ),
              ),
              const SizedBox(width: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onSendMessage,
                  icon: Icon(
                    isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                    size: 18,
                  ),
                  label: Text(isLoading ? 'Enviando...' : 'Enviar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: isLoading ? 0 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedLogo(
            size: 140,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Revolução da Inteligência Popular!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 8),
          Text(
            'A inteligência artificial a serviço do povo!\nUnidos pela democratização do conhecimento.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 400.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SuggestionChip(
                label: 'Explique teoria marxista de forma didática',
                onTap: () => _fillSuggestion('Explique conceitos de teoria marxista de forma didática'),
              ),
              _SuggestionChip(
                label: 'Analise questões sociais brasileiras',
                onTap: () => _fillSuggestion('Analise as principais questões sociais do Brasil atual'),
              ),
              _SuggestionChip(
                label: 'Pesquise movimentos populares',
                onTap: () => _fillSuggestion('Pesquise informações sobre movimentos populares e sociais'),
              ),
              _SuggestionChip(
                label: 'Discuta tecnologia e sociedade',
                onTap: () => _fillSuggestion('Como a tecnologia pode servir à democratização do conhecimento?'),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 600.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  void _fillSuggestion(String suggestion) {
    textController.text = suggestion;
  }
}

class _SuggestionChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
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
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered 
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered 
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered ? [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: _isHovered 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isHovered 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onPrimaryContainer,
                  fontSize: 14,
                  fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  factory ChatMessage.fromUser(String content) {
    return ChatMessage(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.fromResponse(LlmResponse response) {
    return ChatMessage(
      content: response.content,
      isUser: false,
      timestamp: response.timestamp,
      isError: response.isError,
    );
  }
}

class ChatBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: widget.message.isUser 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (!widget.message.isUser) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: widget.message.isError 
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                child: Icon(
                  widget.message.isError ? Icons.error : Icons.psychology_rounded,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.message.isUser 
                    ? theme.colorScheme.primary
                    : widget.message.isError
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isHovered ? [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.content,
                    style: TextStyle(
                      color: widget.message.isUser 
                          ? theme.colorScheme.onPrimary
                          : widget.message.isError
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(widget.message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.message.isUser 
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.message.isUser) ...[
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondary,
                child: Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }
}