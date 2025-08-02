/// Página principal da aplicação Local LLM Chat.
/// 
/// Esta é a tela principal que contém toda a interface do usuário para
/// interação com modelos de linguagem locais, incluindo seleção de modelos,
/// configurações e interface de chat.
library;

import 'package:flutter/material.dart';
import '../controllers/llm_controller.dart';
import '../widgets/chat_interface.dart';
import '../providers/theme_provider.dart';

/// Widget da página principal da aplicação.
/// 
/// Gerencia a interface completa do usuário incluindo:
/// - Layout responsivo para diferentes tamanhos de tela
/// - Interface de chat com histórico de mensagens
/// - Controles de configuração (modelo, pesquisa web, streaming)
/// - Integração com o sistema de temas
class HomePage extends StatefulWidget {
  /// Controlador principal para interação com LLM.
  final LlmController controller;
  
  /// Provedor de temas da aplicação.
  final ThemeProvider themeProvider;

  const HomePage({
    super.key, 
    required this.controller, 
    required this.themeProvider,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Controlador para o campo de entrada de texto das mensagens.
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Registra listener para reconstruir quando o controlador mudar
    widget.controller.addListener(_onControllerChange);
    
    // Carrega modelos disponíveis após a construção inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadAvailableModels();
    });
  }

  @override
  void dispose() {
    // Remove listener para evitar vazamentos de memória
    widget.controller.removeListener(_onControllerChange);
    _messageController.dispose();
    super.dispose();
  }

  /// Callback chamado quando o estado do controlador muda.
  /// Reconstrói a interface se o widget ainda estiver montado.
  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  /// Envia uma mensagem para o modelo LLM e limpa o campo de entrada.
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.controller.sendMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatInterface(
        messages: widget.controller.messages,
        textController: _messageController,
        onSendMessage: _sendMessage,
        isLoading: widget.controller.isLoading || widget.controller.isSearching,
        isThinking: widget.controller.isThinking,
        currentThinking: widget.controller.currentThinking,
      ),
    );
  }

  /// Exibe um diálogo de confirmação para limpar o chat.
  /// 
  /// Mostra uma caixa de diálogo pedindo confirmação do usuário antes
  /// de limpar todo o histórico de conversas. A ação é irreversível.
  void _showClearChatDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar conversa'),
        content: const Text(
          'Tem certeza de que deseja limpar toda a conversa? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              widget.controller.clearChat();
              Navigator.of(context).pop();
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}
