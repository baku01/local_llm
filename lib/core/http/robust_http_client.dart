/// Cliente HTTP robusto com retry automático e headers otimizados.
/// 
/// Implementa um wrapper em torno do cliente HTTP padrão do Dart,
/// adicionando funcionalidades de resiliência como timeout configurável,
/// retry automático em falhas de rede e headers personalizados para
/// melhor compatibilidade com diferentes websites.
library;

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Cliente HTTP robusto com funcionalidades de resiliência.
/// 
/// Características principais:
/// - Headers de User-Agent realísticos para evitar bloqueios
/// - Timeout configurável com fallback
/// - Retry automático em falhas de conectividade
/// - Support para gzip e deflate compression
/// - Headers de cache otimizados para web scraping
class RobustHttpClient extends http.BaseClient {
  /// Cliente HTTP interno do Dart.
  final http.Client _inner;

  /// Construtor que inicializa o cliente interno.
  RobustHttpClient() : _inner = http.Client();

  /// Envia uma requisição HTTP com resiliência e retry.
  /// 
  /// Adiciona headers padronizados para melhor compatibilidade,
  /// implementa timeout e retry automático em caso de falhas de rede.
  /// 
  /// [request] - A requisição HTTP a ser enviada
  /// 
  /// Returns: [http.StreamedResponse] com a resposta do servidor
  /// 
  /// Throws: Exceções de rede após retry ou outros erros não relacionados à conectividade
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Adicionar headers realísticos para evitar bloqueios de bots
    request.headers.addAll({
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    });

    try {
      // Primeira tentativa com timeout de 15 segundos
      final response = await _inner
          .send(request)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Request timeout',
              const Duration(seconds: 15),
            ),
          );

      return response;
    } catch (e) {
      // Retry automático apenas para erros de conectividade
      if (e is SocketException || e is TimeoutException) {
        // Aguarda um pouco antes do retry para dar tempo de recuperação
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Segunda tentativa com timeout menor
        return await _inner.send(request).timeout(const Duration(seconds: 10));
      }
      rethrow;
    }
  }

  /// Fecha o cliente HTTP e libera recursos.
  /// 
  /// Deve ser chamado quando o cliente não for mais necessário
  /// para evitar vazamentos de recursos.
  @override
  void close() {
    _inner.close();
  }
}
