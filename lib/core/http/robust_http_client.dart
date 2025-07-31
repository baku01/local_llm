import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class RobustHttpClient extends http.BaseClient {
  final http.Client _inner;
  
  RobustHttpClient() : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Configurar timeout padrão
    request.headers.addAll({
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    });

    try {
      final response = await _inner.send(request).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timeout', const Duration(seconds: 15)),
      );
      
      return response;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        // Retry uma vez em caso de erro de rede
        await Future.delayed(const Duration(milliseconds: 500));
        return await _inner.send(request).timeout(
          const Duration(seconds: 10),
        );
      }
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}