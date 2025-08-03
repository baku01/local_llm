/// Advanced content extraction and cleaning utilities.
/// 
/// This library provides comprehensive utilities for extracting, cleaning,
/// and processing web content including:
/// - Content readability analysis
/// - Text summarization
/// - Language detection
/// - Content classification
/// - Data extraction patterns
library;

import 'dart:math' as math;

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

/// Content extraction and analysis utilities
class ContentExtractionUtils {
  /// Extract readable content using advanced heuristics
  static ReadableContent extractReadableContent(String html) {
    final doc = html_parser.parse(html);
    
    // Remove unwanted elements
    _removeUnwantedElements(doc);
    
    // Find the main content container
    final mainContent = _findMainContent(doc);
    
    // Extract and score text blocks
    final textBlocks = _extractTextBlocks(mainContent);
    final scoredBlocks = _scoreTextBlocks(textBlocks);
    
    // Filter and combine best blocks
    final readableBlocks = _filterReadableBlocks(scoredBlocks);
    final content = _combineTextBlocks(readableBlocks);
    
    // Extract metadata
    final metadata = _extractContentMetadata(doc, content);
    
    return ReadableContent(
      content: content,
      metadata: metadata,
      textBlocks: readableBlocks,
      readabilityScore: _calculateReadabilityScore(content),
    );
  }

  /// Remove unwanted HTML elements that don't contribute to content
  static void _removeUnwantedElements(html_dom.Document doc) {
    final unwantedSelectors = [
      // Scripts and styles
      'script', 'style', 'noscript',
      
      // Navigation and UI elements
      'nav', 'header', 'footer', 'aside',
      '.navigation', '.nav', '.menu',
      '.sidebar', '.header', '.footer',
      
      // Advertisements and social
      '.ad', '.ads', '.advertisement', '.adsbygoogle',
      '.social', '.social-share', '.sharing',
      '.fb-like', '.twitter-share', '.pinterest',
      
      // Comments and interactions
      '.comments', '.comment-section',
      '.disqus', '.livefyre',
      
      // Forms and popups
      '.popup', '.modal', '.overlay',
      '.newsletter-signup', '.subscription',
      
      // Metadata and tracking
      '.breadcrumb', '.tags', '.categories',
      '.author-bio', '.related-articles',
      
      // Technical elements
      '[role="banner"]', '[role="navigation"]',
      '[role="complementary"]', '[role="contentinfo"]',
      '.screen-reader-only', '.sr-only',
    ];
    
    for (final selector in unwantedSelectors) {
      try {
        doc.querySelectorAll(selector).forEach((el) => el.remove());
      } catch (e) {
        // Continue if selector fails
      }
    }
  }

  /// Find the main content container using multiple strategies
  static html_dom.Element _findMainContent(html_dom.Document doc) {
    // Strategy 1: Semantic HTML5 elements
    final semanticSelectors = [
      'main',
      '[role="main"]',
      'article',
      '.main-content',
      '.content',
      '.post-content',
      '.article-content',
      '.entry-content',
      '#main-content',
      '#content',
      '#main',
    ];
    
    for (final selector in semanticSelectors) {
      final element = doc.querySelector(selector);
      if (element != null && _hasSignificantContent(element)) {
        return element;
      }
    }
    
    // Strategy 2: Find element with most text content
    final candidates = doc.querySelectorAll('div, section, article');
    html_dom.Element? bestCandidate;
    int maxTextLength = 0;
    
    for (final candidate in candidates) {
      final textLength = candidate.text.trim().length;
      final linkDensity = _calculateLinkDensity(candidate);
      
      // Prefer elements with more text and lower link density
      if (textLength > maxTextLength && linkDensity < 0.5) {
        maxTextLength = textLength;
        bestCandidate = candidate;
      }
    }
    
    return bestCandidate ?? doc.body ?? doc.documentElement!;
  }

  /// Check if element has significant content
  static bool _hasSignificantContent(html_dom.Element element) {
    final text = element.text.trim();
    final words = text.split(RegExp(r'\s+'));
    return words.length >= 50 && text.length >= 200;
  }

  /// Calculate link density (ratio of link text to total text)
  static double _calculateLinkDensity(html_dom.Element element) {
    final totalText = element.text.length;
    if (totalText == 0) return 1.0;
    
    final links = element.querySelectorAll('a');
    final linkText = links.fold<int>(0, (sum, link) => sum + link.text.length);
    
    return linkText / totalText;
  }

  /// Extract text blocks from content
  static List<TextBlock> _extractTextBlocks(html_dom.Element element) {
    final blocks = <TextBlock>[];
    final textElements = ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'blockquote', 'pre'];
    
    for (final tagName in textElements) {
      final elements = element.querySelectorAll(tagName);
      
      for (final el in elements) {
        final text = el.text.trim();
        if (text.isNotEmpty && text.length >= 20) {
          blocks.add(TextBlock(
            text: text,
            tagName: tagName,
            element: el,
            wordCount: text.split(RegExp(r'\s+')).length,
            linkDensity: _calculateLinkDensity(el),
            position: blocks.length,
          ));
        }
      }
    }
    
    return blocks;
  }

  /// Score text blocks based on content quality indicators
  static List<ScoredTextBlock> _scoreTextBlocks(List<TextBlock> blocks) {
    return blocks.map((block) {
      double score = 0.0;
      
      // Base score by word count
      score += math.min(block.wordCount / 20.0, 5.0);
      
      // Penalty for high link density
      score -= block.linkDensity * 3.0;
      
      // Bonus for paragraph tags
      if (block.tagName == 'p') score += 2.0;
      
      // Bonus for headings (but less than paragraphs)
      if (block.tagName.startsWith('h')) score += 1.5;
      
      // Bonus for lists
      if (block.tagName == 'li') score += 1.0;
      
      // Penalty for very short or very long blocks
      if (block.wordCount < 10) score -= 2.0;
      if (block.wordCount > 200) score -= 1.0;
      
      // Contextual scoring based on surrounding blocks
      score += _calculateContextualScore(block, blocks);
      
      return ScoredTextBlock(block, math.max(score, 0.0));
    }).toList();
  }

  /// Calculate contextual score based on surrounding blocks
  static double _calculateContextualScore(TextBlock block, List<TextBlock> allBlocks) {
    double contextScore = 0.0;
    final position = block.position;
    
    // Look at adjacent blocks
    for (int i = math.max(0, position - 2); i <= math.min(allBlocks.length - 1, position + 2); i++) {
      if (i == position) continue;
      
      final adjacentBlock = allBlocks[i];
      final distance = (position - i).abs();
      final proximityWeight = 1.0 / distance;
      
      // Bonus if adjacent blocks are also substantial
      if (adjacentBlock.wordCount > 15 && adjacentBlock.linkDensity < 0.3) {
        contextScore += proximityWeight * 0.5;
      }
    }
    
    return contextScore;
  }

  /// Filter readable blocks based on score threshold
  static List<ScoredTextBlock> _filterReadableBlocks(List<ScoredTextBlock> scoredBlocks) {
    // Sort by score descending
    scoredBlocks.sort((a, b) => b.score.compareTo(a.score));
    
    // Calculate dynamic threshold
    final scores = scoredBlocks.map((b) => b.score).toList();
    final avgScore = scores.isNotEmpty ? scores.fold<double>(0.0, (sum, value) => sum + value) / scores.length : 0.0;
    final threshold = math.max(avgScore * 0.5, 1.0);
    
    // Filter blocks above threshold
    final filtered = scoredBlocks.where((block) => block.score >= threshold).toList();
    
    // Ensure we have at least some content
    if (filtered.isEmpty && scoredBlocks.isNotEmpty) {
      return [scoredBlocks.first];
    }
    
    return filtered;
  }

  /// Combine text blocks into readable content
  static String _combineTextBlocks(List<ScoredTextBlock> blocks) {
    if (blocks.isEmpty) return '';
    
    // Sort by original position to maintain reading order
    blocks.sort((a, b) => a.block.position.compareTo(b.block.position));
    
    final buffer = StringBuffer();
    String? lastTagName;
    
    for (final scoredBlock in blocks) {
      final block = scoredBlock.block;
      
      // Add appropriate spacing based on tag types
      if (buffer.isNotEmpty) {
        if (block.tagName.startsWith('h') || lastTagName?.startsWith('h') == true) {
          buffer.writeln('\n');
        } else {
          buffer.writeln();
        }
      }
      
      buffer.write(block.text);
      lastTagName = block.tagName;
    }
    
    return buffer.toString().trim();
  }

  /// Extract comprehensive content metadata
  static ContentMetadata _extractContentMetadata(html_dom.Document doc, String content) {
    return ContentMetadata(
      title: _extractTitle(doc),
      description: _extractDescription(doc),
      author: _extractAuthor(doc),
      publishedDate: _extractPublishedDate(doc),
      modifiedDate: _extractModifiedDate(doc),
      language: _extractLanguage(doc),
      keywords: _extractKeywords(doc),
      canonicalUrl: _extractCanonicalUrl(doc),
      wordCount: content.split(RegExp(r'\s+')).length,
      readingTime: _calculateReadingTime(content),
      contentType: _classifyContentType(doc, content),
      sentiment: _analyzeSentiment(content),
      topics: _extractTopics(content),
    );
  }

  /// Extract page title with fallbacks
  static String _extractTitle(html_dom.Document doc) {
    // Try multiple sources for title
    final titleSources = [
      () => doc.querySelector('h1')?.text.trim(),
      () => doc.querySelector('title')?.text.trim(),
      () => doc.querySelector('meta[property="og:title"]')?.attributes['content'],
      () => doc.querySelector('meta[name="twitter:title"]')?.attributes['content'],
      () => doc.querySelector('.title, .post-title, .article-title')?.text.trim(),
    ];
    
    for (final source in titleSources) {
      try {
        final title = source();
        if (title != null && title.isNotEmpty && title.length > 3) {
          return title;
        }
      } catch (e) {
        continue;
      }
    }
    
    return '';
  }

  /// Extract meta description
  static String _extractDescription(html_dom.Document doc) {
    final descSources = [
      () => doc.querySelector('meta[name="description"]')?.attributes['content'],
      () => doc.querySelector('meta[property="og:description"]')?.attributes['content'],
      () => doc.querySelector('meta[name="twitter:description"]')?.attributes['content'],
    ];
    
    for (final source in descSources) {
      try {
        final desc = source();
        if (desc != null && desc.isNotEmpty) {
          return desc.trim();
        }
      } catch (e) {
        continue;
      }
    }
    
    return '';
  }

  /// Extract author information
  static String _extractAuthor(html_dom.Document doc) {
    final authorSources = [
      () => doc.querySelector('meta[name="author"]')?.attributes['content'],
      () => doc.querySelector('[rel="author"]')?.text.trim(),
      () => doc.querySelector('.author, .by-author, .post-author')?.text.trim(),
      () => doc.querySelector('[itemprop="author"]')?.text.trim(),
    ];
    
    for (final source in authorSources) {
      try {
        final author = source();
        if (author != null && author.isNotEmpty) {
          return author;
        }
      } catch (e) {
        continue;
      }
    }
    
    return '';
  }

  /// Extract published date
  static DateTime? _extractPublishedDate(html_dom.Document doc) {
    final dateSources = [
      () => doc.querySelector('meta[property="article:published_time"]')?.attributes['content'],
      () => doc.querySelector('time[datetime]')?.attributes['datetime'],
      () => doc.querySelector('[itemprop="datePublished"]')?.attributes['content'],
      () => doc.querySelector('.published-date, .post-date')?.text.trim(),
    ];
    
    for (final source in dateSources) {
      try {
        final dateStr = source();
        if (dateStr != null && dateStr.isNotEmpty) {
          return DateTime.tryParse(dateStr);
        }
      } catch (e) {
        continue;
      }
    }
    
    return null;
  }

  /// Extract modified date
  static DateTime? _extractModifiedDate(html_dom.Document doc) {
    final dateSources = [
      () => doc.querySelector('meta[property="article:modified_time"]')?.attributes['content'],
      () => doc.querySelector('[itemprop="dateModified"]')?.attributes['content'],
    ];
    
    for (final source in dateSources) {
      try {
        final dateStr = source();
        if (dateStr != null && dateStr.isNotEmpty) {
          return DateTime.tryParse(dateStr);
        }
      } catch (e) {
        continue;
      }
    }
    
    return null;
  }

  /// Extract language
  static String _extractLanguage(html_dom.Document doc) {
    return doc.documentElement?.attributes['lang'] ??
           doc.querySelector('meta[http-equiv="content-language"]')?.attributes['content'] ??
           'pt-BR';
  }

  /// Extract keywords
  static List<String> _extractKeywords(html_dom.Document doc) {
    final keywordsSources = [
      () => doc.querySelector('meta[name="keywords"]')?.attributes['content'],
      () => doc.querySelector('meta[property="article:tag"]')?.attributes['content'],
    ];
    
    final keywords = <String>[];
    
    for (final source in keywordsSources) {
      try {
        final keywordStr = source();
        if (keywordStr != null && keywordStr.isNotEmpty) {
          keywords.addAll(keywordStr.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty));
        }
      } catch (e) {
        continue;
      }
    }
    
    return keywords;
  }

  /// Extract canonical URL
  static String _extractCanonicalUrl(html_dom.Document doc) {
    return doc.querySelector('link[rel="canonical"]')?.attributes['href'] ?? '';
  }

  /// Calculate estimated reading time
  static Duration _calculateReadingTime(String content) {
    const wordsPerMinute = 200;
    final wordCount = content.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return Duration(minutes: math.max(minutes, 1));
  }

  /// Classify content type based on structure and content
  static ContentType _classifyContentType(html_dom.Document doc, String content) {
    // Check for common patterns
    if (doc.querySelector('article') != null) return ContentType.article;
    if (doc.querySelector('.blog-post, .post') != null) return ContentType.blogPost;
    if (doc.querySelector('.news, .news-article') != null) return ContentType.news;
    if (content.contains('recipe') || doc.querySelector('[itemtype*="Recipe"]') != null) return ContentType.recipe;
    if (doc.querySelector('.product, [itemtype*="Product"]') != null) return ContentType.product;
    if (content.length < 500) return ContentType.shortForm;
    
    return ContentType.webpage;
  }

  /// Analyze content sentiment (basic implementation)
  static ContentSentiment _analyzeSentiment(String content) {
    final positiveWords = ['bom', 'ótimo', 'excelente', 'amor', 'feliz', 'positivo', 'sucesso'];
    final negativeWords = ['ruim', 'terrível', 'ódio', 'triste', 'negativo', 'falha', 'problema'];
    
    final words = content.toLowerCase().split(RegExp(r'\W+'));
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in words) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    final total = positiveCount + negativeCount;
    if (total == 0) return ContentSentiment.neutral;
    
    final positiveRatio = positiveCount / total;
    if (positiveRatio > 0.6) return ContentSentiment.positive;
    if (positiveRatio < 0.4) return ContentSentiment.negative;
    
    return ContentSentiment.neutral;
  }

  /// Extract main topics from content (basic keyword extraction)
  static List<String> _extractTopics(String content) {
    final words = content.toLowerCase()
        .split(RegExp(r'\W+'))
        .where((word) => word.length > 4)
        .toList();
    
    // Count word frequency
    final wordCount = <String, int>{};
    for (final word in words) {
      wordCount[word] = (wordCount[word] ?? 0) + 1;
    }
    
    // Get top words
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords
        .take(10)
        .map((entry) => entry.key)
        .toList();
  }

  /// Calculate readability score (simplified Flesch Reading Ease)
  static double _calculateReadabilityScore(String content) {
    if (content.isEmpty) return 0.0;
    
    final sentences = content.split(RegExp(r'[.!?]+'));
    final words = content.split(RegExp(r'\s+'));
    final syllables = words.fold<int>(0, (sum, word) => sum + _countSyllables(word));
    
    if (sentences.isEmpty || words.isEmpty) return 0.0;
    
    final avgWordsPerSentence = words.length / sentences.length;
    final avgSyllablesPerWord = syllables / words.length;
    
    // Simplified Flesch Reading Ease formula
    final score = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllablesPerWord);
    
    return math.max(0.0, math.min(100.0, score));
  }

  /// Count syllables in a word (approximation)
  static int _countSyllables(String word) {
    if (word.isEmpty) return 0;
    
    final vowels = RegExp(r'[aeiouAEIOU]');
    int count = 0;
    bool previousWasVowel = false;
    
    for (int i = 0; i < word.length; i++) {
      final isVowel = vowels.hasMatch(word[i]);
      if (isVowel && !previousWasVowel) {
        count++;
      }
      previousWasVowel = isVowel;
    }
    
    // Handle silent 'e'
    if (word.endsWith('e') && count > 1) {
      count--;
    }
    
    return math.max(count, 1);
  }
}

/// Container for readable content and metadata
class ReadableContent {
  final String content;
  final ContentMetadata metadata;
  final List<ScoredTextBlock> textBlocks;
  final double readabilityScore;

  const ReadableContent({
    required this.content,
    required this.metadata,
    required this.textBlocks,
    required this.readabilityScore,
  });
}

/// Content metadata container
class ContentMetadata {
  final String title;
  final String description;
  final String author;
  final DateTime? publishedDate;
  final DateTime? modifiedDate;
  final String language;
  final List<String> keywords;
  final String canonicalUrl;
  final int wordCount;
  final Duration readingTime;
  final ContentType contentType;
  final ContentSentiment sentiment;
  final List<String> topics;

  const ContentMetadata({
    required this.title,
    required this.description,
    required this.author,
    this.publishedDate,
    this.modifiedDate,
    required this.language,
    required this.keywords,
    required this.canonicalUrl,
    required this.wordCount,
    required this.readingTime,
    required this.contentType,
    required this.sentiment,
    required this.topics,
  });
}

/// Text block container
class TextBlock {
  final String text;
  final String tagName;
  final html_dom.Element element;
  final int wordCount;
  final double linkDensity;
  final int position;

  const TextBlock({
    required this.text,
    required this.tagName,
    required this.element,
    required this.wordCount,
    required this.linkDensity,
    required this.position,
  });
}

/// Scored text block
class ScoredTextBlock {
  final TextBlock block;
  final double score;

  const ScoredTextBlock(this.block, this.score);
}

/// Content type enumeration
enum ContentType {
  article,
  blogPost,
  news,
  recipe,
  product,
  shortForm,
  webpage,
}

/// Content sentiment enumeration
enum ContentSentiment {
  positive,
  negative,
  neutral,
}