import 'package:dartz/dartz.dart';
import '../infrastructure/core/error/failures.dart';
import '../infrastructure/core/search/search_strategy_manager.dart';
import '../domain/entities/search_query.dart';
import '../domain/entities/search_result.dart';
import '../domain/services/llm_query_generator.dart';
import '../domain/services/llm_result_processor.dart';

class WebSearchWithLLM {
  final SearchStrategyManager searchStrategyManager;
  final LLMQueryGenerator queryGenerator;
  final LLMResultProcessor resultProcessor;

  WebSearchWithLLM({
    required this.searchStrategyManager,
    required this.queryGenerator,
    required this.resultProcessor,
  });

  Future<Either<Failure, String>> execute(String userQuery) async {
    try {
      // Step 1: Generate search queries using LLM
      final queryGenerationResult =
          await queryGenerator.generateSearchQueries(userQuery);

      return queryGenerationResult.fold((failure) => Left(failure),
          (searchQueries) async {
        // Step 2: Perform web search for each query
        final searchResults = <SearchResult>[];

        for (var query in searchQueries) {
          final searchQuery = SearchQuery(
            query: query,
            maxResults: 3, // Configurable
            language: 'en', // Can be dynamic
          );

          try {
            final searchResult =
                await searchStrategyManager.search(searchQuery);

            // Extract search results from StrategySearchResult
            if (searchResult.isSuccessful) {
              searchResults.addAll(searchResult.results);
            }
          } catch (e) {
            // Log partial failure but continue with other queries
            // This ensures we don't fail completely if one search fails
            continue;
          }
        }

        // Step 3: Process search results with LLM
        if (searchResults.isEmpty) {
          return const Left(SearchFailure(
            message: 'No search results found for any generated queries',
          ));
        }

        return resultProcessor.processSearchResults(
            originalQuery: userQuery, searchResults: searchResults);
      });
    } catch (e) {
      return Left(UnexpectedFailure(
        message: e.toString(),
        originalException: e,
      ));
    }
  }
}
