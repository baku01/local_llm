import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/unified_theme.dart';
import 'advanced_markdown_widget.dart';

class EnhancedChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  
  const EnhancedChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
  
  @override
  State<EnhancedChatBubble> createState() => _EnhancedChatBubbleState();
}

class _EnhancedChatBubbleState extends State<EnhancedChatBubble> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isCopied = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: widget.isUser ? null : _copyToClipboard,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(
            left: widget.isUser ? 64 : 16,
            right: widget.isUser ? 16 : 64,
            bottom: 12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getBubbleColor(theme, isDark),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.05),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
                spreadRadius: _isHovered ? 1 : 0,
              ),
            ],
            border: Border.all(
              color: _getBorderColor(theme, isDark),
              width: 1,
            ),
          ),
          transform: Matrix4.identity()..translate(0.0, _isPressed ? 1.0 : _isHovered ? -1.0 : 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isUser) ...[
                _buildMessageContent(theme, isDark),
                const SizedBox(height: 8),
                _buildBottomRow(theme, isDark),
              ] else ...[
                Text(
                  widget.message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(widget.timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ).animate(target: _isCopied ? 1 : 0)
        .shimmer(duration: 600.ms, color: theme.colorScheme.primary.withValues(alpha: 0.3))
        .then(delay: 200.ms)
        .fadeOut(duration: 400.ms),
    );
  }
  
  Widget _buildMessageContent(ThemeData theme, bool isDark) {
    if (widget.isUser) {
      return Text(
        widget.message,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
      );
    } else {
      return AdvancedMarkdownWidget(
        data: widget.message,
        selectable: true,
      );
    }
  }
  
  Widget _buildBottomRow(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatTime(widget.timestamp),
          style: TextStyle(
            color: widget.isUser 
                ? Colors.white.withValues(alpha: 0.7) 
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        if (_isHovered && !widget.isUser)
          _buildCopyButton(theme, isDark),
      ],
    );
  }
  
  Widget _buildCopyButton(ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: _copyToClipboard,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCopied ? Icons.check : Icons.copy,
                size: 14,
                color: _isCopied 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              if (_isCopied) ...[
                const SizedBox(width: 4),
                Text(
                  'Copiado',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getBubbleColor(ThemeData theme, bool isDark) {
    if (widget.isUser) {
      return theme.colorScheme.primary;
    } else if (widget.isError) {
      return theme.colorScheme.error.withValues(alpha: 0.1);
    } else {
      return _isHovered 
          ? (isDark ? AppTheme.kDarkSurface : AppTheme.kLightSurface)
          : (isDark ? AppTheme.kDarkCardBg : AppTheme.kLightCardBg);
    }
  }
  
  Color _getBorderColor(ThemeData theme, bool isDark) {
    if (widget.isUser) {
      return Colors.transparent;
    } else if (widget.isError) {
      return theme.colorScheme.error.withValues(alpha: 0.2);
    } else {
      return _isHovered 
          ? theme.colorScheme.primary.withValues(alpha: 0.3)
          : theme.colorScheme.outline.withValues(alpha: 0.2);
    }
  }
  
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message));
    setState(() => _isCopied = true);
    HapticFeedback.lightImpact();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}