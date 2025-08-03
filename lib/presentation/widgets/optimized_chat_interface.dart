/// Interface de chat otimizada anti-flickering.
/// 
/// Demonstra o uso dos widgets otimizados para streaming sem tremulação.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'optimized_streaming_message.dart';

/// Interface de chat otimizada que elimina flickering
class OptimizedChatInterface extends ConsumerStatefulWidget {
  const OptimizedChatInterface({super.key});

  @override
  ConsumerState<OptimizedChatInterface> createState() => _OptimizedChatInterfaceState();
}

class _OptimizedChatInterfaceState extends ConsumerState<OptimizedChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Use seu controller otimizado aqui
    // ref.read(optimizedLlmControllerProvider).sendMessage(text);
    
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Para demonstração, vou usar um mock de dados
    // Na implementação real, você usaria:
    // final streamingMessages = ref.watch(optimizedLlmControllerProvider.select((c) => c.streamingMessages));
    
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Mock: substitua pela lista real
      itemBuilder: (context, index) {
        return _buildOptimizedMessageItem(index);
      },
    );
  }

  Widget _buildOptimizedMessageItem(int index) {
    // Mock de dados - substitua pela implementação real
    final isUser = index % 2 == 0;
    
    if (isUser) {
      return _buildUserMessage("Mensagem do usuário $index");
    } else {
      return _buildAIStreamingMessage(index);
    }
  }

  Widget _buildUserMessage(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStreamingMessage(int index) {
    // Mock stream - substitua pelo stream real da mensagem
    final mockStream = _createMockStream(index);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: RepaintBoundary(
              child: OptimizedStreamingMessage(
                textStream: mockStream,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                onStreamComplete: () {
                  _scrollToBottom();
                },
                throttleDuration: const Duration(milliseconds: 50),
                showCursor: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  /// Mock stream para demonstração - substitua pela implementação real
  Stream<String> _createMockStream(int index) async* {
    final text = "Esta é uma resposta simulada em streaming para a mensagem $index. "
                "O texto vai aparecendo progressivamente, como se fosse digitado pela IA. "
                "Note que não há flickering porque usamos otimizações específicas!";
    
    // Simular streaming chunk por chunk
    final words = text.split(' ');
    String accumulated = '';
    
    for (int i = 0; i < words.length; i++) {
      accumulated += (i == 0 ? '' : ' ') + words[i];
      yield accumulated;
      
      // Simular delay entre chunks
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}