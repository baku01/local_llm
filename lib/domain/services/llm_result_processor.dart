import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/search_result.dart';
import 'llm_service.dart';

class LLMResultProcessor {
  final LLMService llmService;

  LLMResultProcessor({required this.llmService});

  Future<Either<Failure, String>> processSearchResults({
    required String originalQuery,
    required List<SearchResult> searchResults,
  }) async {
    // Limit search results to prevent token overflow
    final limitedResults = searchResults.take(5).toList();

    final prompt = '''
You are an AI that synthesizes web search results into a coherent, concise response.

Original Query: "$originalQuery"

Search Results:
${limitedResults.map((result) => '- Source: ${_extractDomain(result.url)}\n  Title: ${result.title}\n  Snippet: ${result.snippet}\n  URL: ${result.url}').join('\n\n')}

Instructions:
- Analyze the search results thoroughly
- Generate a comprehensive, well-structured response
- Cite sources where appropriate using the format [Source Name](URL)
- If results are insufficient, acknowledge the limitations
- Be concise but informative
    ''';

    final result = await llmService.generateText(prompt);

    return result.fold(
      (failure) => Left(failure),
      (response) => Right(response.text),
    );
  }

  /// Extracts domain from URL for source citation.
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }
}
