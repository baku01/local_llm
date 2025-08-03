/// Container de injeção de dependências para a aplicação.
///
/// Implementa o padrão Singleton para gerenciar todas as dependências
/// da aplicação, incluindo clientes HTTP, datasources, repositórios,
/// casos de uso e controladores.
///
/// Segue a arquitetura Clean Architecture com separação clara de camadas.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../http/robust_http_client.dart';
import '../../data/datasources/ollama_remote_datasource.dart';
import '../../data/datasources/web_search_datasource.dart';
import '../../data/datasources/strategy_web_search_datasource.dart';
import '../../data/repositories/llm_repository_impl.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/llm_repository.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/get_available_models.dart';
import '../../domain/usecases/generate_response.dart';
import '../../domain/usecases/generate_response_stream.dart';
import '../../domain/usecases/search_web.dart';
import '../../presentation/controllers/llm_controller.dart';

/// Container singleton responsável pela injeção de dependências.
///
/// Centraliza a criação e configuração de todas as dependências da aplicação:
/// - Clientes de rede (Dio, HTTP)
/// - DataSources para APIs externas
/// - Repositórios para acesso aos dados
/// - Casos de uso para lógica de negócio
/// - Controladores para gerenciamento de estado
///
/// Utiliza lazy initialization para melhor performance.
class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();

  /// Factory constructor que retorna a instância singleton.
  factory InjectionContainer() => _instance;

  /// Construtor privado para implementar Singleton.
  InjectionContainer._internal();

  // Clientes de rede
  late final Dio _dio;
  late final http.Client _httpClient;

  // DataSources
  late final OllamaRemoteDataSource _remoteDataSource;
  late final WebSearchDataSource _searchDataSource;

  // Repositórios
  late final LlmRepository _repository;
  late final SearchRepository _searchRepository;

  // Casos de uso
  late final GetAvailableModels _getAvailableModels;
  late final GenerateResponse _generateResponse;
  late final GenerateResponseStream _generateResponseStream;
  late final SearchWeb _searchWeb;
  late final FetchWebContent _fetchWebContent;

  // Controladores
  late final LlmController _controller;

  /// Inicializa todas as dependências da aplicação.
  ///
  /// Deve ser chamado uma única vez durante a inicialização da aplicação.
  /// Configura as dependências na ordem correta: networking → datasources →
  /// repositories → use cases → controllers.
  void initialize() {
    _setupNetworking();
    _setupDataSources();
    _setupRepositories();
    _setupUseCases();
    _setupControllers();
  }

  /// Configura os clientes de rede (Dio e HTTP).
  ///
  /// Dio é usado para comunicação com API do Ollama com timeouts configurados.
  /// HTTP Client robusto é usado para pesquisas web com retry automático.
  void _setupNetworking() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    // Adiciona interceptor de log apenas em modo debug
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint('[DIO] $object'),
      ),
    );

    _httpClient = RobustHttpClient();
  }

  /// Configura os datasources para acesso a APIs externas.
  ///
  /// - OllamaRemoteDataSource: Comunicação com servidor Ollama local
  /// - StrategyWebSearchDataSource: Pesquisas web com estratégias modulares
  void _setupDataSources() {
    _remoteDataSource = OllamaRemoteDataSourceImpl(
      dio: _dio,
      baseUrl: 'http://localhost:11434',
    );

    // Usar o novo datasource baseado em estratégias
    _searchDataSource = StrategyWebSearchDataSource(
      httpClient: _httpClient,
    );
  }

  /// Configura os repositórios que implementam as interfaces de domínio.
  ///
  /// Conecta os datasources com as interfaces definidas na camada de domínio.
  void _setupRepositories() {
    _repository = LlmRepositoryImpl(remoteDataSource: _remoteDataSource);

    _searchRepository = SearchRepositoryImpl(dataSource: _searchDataSource);
  }

  /// Configura os casos de uso da aplicação.
  ///
  /// Cada caso de uso encapsula uma funcionalidade específica do negócio,
  /// recebendo os repositórios necessários via injeção de dependência.
  void _setupUseCases() {
    _getAvailableModels = GetAvailableModels(_repository);
    _generateResponse = GenerateResponse(_repository);
    _generateResponseStream = GenerateResponseStream(_repository);
    _searchWeb = SearchWeb(_searchRepository);
    _fetchWebContent = FetchWebContent(_searchRepository);
  }

  /// Configura os controladores da camada de apresentação.
  ///
  /// Os controladores recebem os casos de uso necessários para
  /// gerenciar o estado da interface do usuário.
  void _setupControllers() {
    _controller = LlmController(
      getAvailableModels: _getAvailableModels,
      generateResponse: _generateResponse,
      generateResponseStream: _generateResponseStream,
      searchWeb: _searchWeb,
    );
  }

  // === GETTERS PÚBLICOS ===
  // Fornecem acesso controlado às dependências para uso externo

  /// Cliente Dio configurado para requisições HTTP.
  Dio get dio => _dio;

  /// Cliente HTTP robusto com retry automático.
  http.Client get httpClient => _httpClient;

  /// DataSource para comunicação com API do Ollama.
  OllamaRemoteDataSource get remoteDataSource => _remoteDataSource;

  /// DataSource para pesquisas web.
  WebSearchDataSource get searchDataSource => _searchDataSource;

  /// Repositório para operações com modelos LLM.
  LlmRepository get repository => _repository;

  /// Repositório para operações de pesquisa web.
  SearchRepository get searchRepository => _searchRepository;

  /// Caso de uso para obter modelos disponíveis.
  GetAvailableModels get getAvailableModels => _getAvailableModels;

  /// Caso de uso para geração de resposta única.
  GenerateResponse get generateResponse => _generateResponse;

  /// Caso de uso para geração de resposta em streaming.
  GenerateResponseStream get generateResponseStream => _generateResponseStream;

  /// Caso de uso para pesquisas web.
  SearchWeb get searchWeb => _searchWeb;

  /// Caso de uso para busca de conteúdo web.
  FetchWebContent get fetchWebContent => _fetchWebContent;

  /// Controlador principal da aplicação.
  LlmController get controller => _controller;
}
