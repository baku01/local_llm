import 'package:flutter/material.dart';
import '../controllers/llm_controller.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/chat_interface.dart';
import '../providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  final LlmController controller;
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
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadAvailableModels();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _messageController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.controller.sendMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      models: widget.controller.models,
      selectedModel: widget.controller.selectedModel,
      onModelSelected: (model) {
        if (model != null) {
          widget.controller.selectModel(model);
        }
      },
      isLoading: widget.controller.isLoading,
      onRefreshModels: widget.controller.loadAvailableModels,
      errorMessage: widget.controller.errorMessage,
      webSearchEnabled: widget.controller.webSearchEnabled,
      onWebSearchToggle: widget.controller.toggleWebSearch,
      isSearching: widget.controller.isSearching,
      streamEnabled: widget.controller.streamEnabled,
      onStreamToggle: widget.controller.toggleStreamMode,
      onClearChat: widget.controller.messages.isNotEmpty ? () => _showClearChatDialog() : null,
      themeProvider: widget.themeProvider,
      content: ChatInterface(
        messages: widget.controller.messages,
        textController: _messageController,
        onSendMessage: _sendMessage,
        isLoading:
            widget.controller.isLoading || widget.controller.isSearching,
        isThinking: widget.controller.isThinking,
        currentThinking: widget.controller.currentThinking,
      ),
    );
  }

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
