import 'package:flutter/material.dart';
import '../controllers/llm_controller.dart';
import '../widgets/desktop_layout.dart';
import '../widgets/settings_sidebar.dart';
import '../widgets/chat_interface.dart';

class HomePage extends StatefulWidget {
  final LlmController controller;

  const HomePage({
    super.key,
    required this.controller,
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.psychology_rounded, 
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Revolução IA - Ferramenta Popular'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.controller.messages.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton.outlined(
                icon: const Icon(Icons.clear_all_rounded),
                onPressed: () => _showClearChatDialog(),
                tooltip: 'Limpar conversa',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
        ],
      ),
      body: DesktopLayout(
        sidebar: SettingsSidebar(
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
        ),
        content: ChatInterface(
          messages: widget.controller.messages,
          textController: _messageController,
          onSendMessage: _sendMessage,
          isLoading: widget.controller.isLoading || widget.controller.isSearching,
          isThinking: widget.controller.isThinking,
          currentThinking: widget.controller.currentThinking,
        ),
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