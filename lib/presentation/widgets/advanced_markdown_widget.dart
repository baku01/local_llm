import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:url_launcher/url_launcher.dart';

class AdvancedMarkdownWidget extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownConfig? config;

  const AdvancedMarkdownWidget({
    super.key,
    required this.data,
    this.selectable = true,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownBlock(
      data: data,
      selectable: selectable,
      config: config ?? _buildMarkdownConfig(context, isDark),
    );
  }

  MarkdownConfig _buildMarkdownConfig(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return MarkdownConfig(
      configs: [
        // Paragraph styling
        PConfig(
          textStyle: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        
        // Headers styling
        H1Config(
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            height: 1.2,
          ),
        ),
        H2Config(
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            height: 1.3,
          ),
        ),
        H3Config(
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            height: 1.3,
          ),
        ),
        H4Config(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        H5Config(
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        H6Config(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        
        // Code block styling with syntax highlighting
        PreConfig(
          theme: githubTheme,
          wrapper: (child, code, language) {
            return Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1e1e1e)
                    : const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  child,
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildCopyButton(context, code),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Inline code styling
        CodeConfig(
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            color: isDark 
                ? const Color(0xFFE06C75) 
                : const Color(0xFFD73A49),
            backgroundColor: isDark
                ? const Color(0xFF2D2D32).withValues(alpha: 0.8)
                : const Color(0xFFF1F3F4).withValues(alpha: 0.8),
          ),
        ),
        
        // Blockquote styling
        BlockquoteConfig(),
        
        // Link styling
        LinkConfig(
          style: TextStyle(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          onTap: (url) {
            _launchUrl(url);
          },
        ),
        
        // List styling - use default for compatibility
        
        // Table styling - simplified
        TableConfig(),
        
        // Horizontal rule styling
        HrConfig(
          height: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        
        // Image styling
        ImgConfig(
          builder: (url, attributes) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Erro ao carregar imagem: $url',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCopyButton(BuildContext context, String code) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _copyToClipboard(context, code),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.copy,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Código copiado para a área de transferência'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}