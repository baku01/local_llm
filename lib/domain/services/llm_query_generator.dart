import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import 'llm_service.dart';

class LLMQueryGenerator {
  final LLMService llmService;

  LLMQueryGenerator({required this.llmService});

  Future<Either<Failure, List<String>>> generateSearchQueries(String userQuery) async {
    final prompt = '''
You are an AI query generator. Given a user query, generate 2-3 precise, 
focused web search queries that will help find the most relevant information.

Guidelines:
- Create queries that capture different aspects of the original query
- Use clear, concise language
- Avoid overly broad or vague queries

User Query: "$userQuery"

Respond with a JSON array of search queries, like:
["query1", "query2", "query3"]
    ''';

    final result = await llmService.generateText(prompt);
    
    return result.fold(
      (failure) => Left(failure),
      (response) {
        try {
          // Extract JSON from the response text
          final jsonStr = response.text.trim();
          final jsonData = jsonDecode(jsonStr);
          
          if (jsonData is List) {
            final queries = jsonData.cast<String>();
            return Right(queries);
          } else {
            return const Left(ParsingFailure(
              message: 'Response is not a valid JSON array'
            ));
          }
        } catch (e) {
          return Left(ParsingFailure(
            message: 'Failed to parse search queries: ${e.toString()}',
            failedData: response.text,
          ));
        }
      }
    );
  }
}