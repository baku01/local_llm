import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../../domain/entities/search_result.dart';

abstract class WebSearchDataSource {
  Future<List<SearchResult>> search(SearchQuery query);
  Future<String> fetchPageContent(String url);
}

class DuckDuckGoSearchDataSource implements WebSearchDataSource {
  final http.Client client;

  const DuckDuckGoSearchDataSource({required this.client});

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    try {
      // Usando DuckDuckGo Instant Answer API (limitado mas funcional)
      final url = Uri.parse(
        'https://api.duckduckgo.com/?q=${Uri.encodeComponent(query.formattedQuery)}&format=json&no_html=1&skip_disambig=1'
      );

      final response = await client.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('Falha na busca: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = <SearchResult>[];

      // Processar resultados relacionados
      if (data['RelatedTopics'] != null) {
        final topics = data['RelatedTopics'] as List;
        
        for (var topic in topics.take(query.maxResults)) {
          if (topic is Map<String, dynamic> && topic['Text'] != null) {
            results.add(SearchResult(
              title: _extractTitle(topic['Text'] as String),
              url: topic['FirstURL'] as String? ?? '',
              snippet: topic['Text'] as String,
              timestamp: DateTime.now(),
            ));
          }
        }
      }

      // Se não há resultados relacionados, criar um resultado com a definição
      if (results.isEmpty && data['Definition'] != null) {
        results.add(SearchResult(
          title: data['Heading'] as String? ?? query.query,
          url: data['DefinitionURL'] as String? ?? '',
          snippet: data['Definition'] as String,
          timestamp: DateTime.now(),
        ));
      }

      return results;
    } catch (e) {
      throw Exception('Erro na pesquisa web: $e');
    }
  }

  @override
  Future<String> fetchPageContent(String url) async {
    try {
      final response = await client.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar página: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);
      
      // Extrair texto principal, removendo scripts e estilos
      document.querySelectorAll('script, style, nav, header, footer').forEach((element) {
        element.remove();
      });

      final textContent = document.body?.text ?? '';
      
      // Limitar o tamanho do conteúdo
      const maxLength = 2000;
      if (textContent.length > maxLength) {
        return '${textContent.substring(0, maxLength)}...';
      }
      
      return textContent;
    } catch (e) {
      throw Exception('Erro ao buscar conteúdo da página: $e');
    }
  }

  String _extractTitle(String text) {
    // Extrair as primeiras palavras como título
    final words = text.split(' ');
    if (words.length <= 8) return text;
    return '${words.take(8).join(' ')}...';
  }
}