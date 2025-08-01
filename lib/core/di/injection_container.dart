import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../http/robust_http_client.dart';
import '../../data/datasources/ollama_remote_datasource.dart';
import '../../data/datasources/web_search_datasource.dart';
import '../../data/datasources/local_web_search_datasource.dart';
import '../../data/repositories/llm_repository_impl.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/llm_repository.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/get_available_models.dart';
import '../../domain/usecases/generate_response.dart';
import '../../domain/usecases/generate_response_stream.dart';
import '../../domain/usecases/search_web.dart';
import '../../presentation/controllers/llm_controller.dart';

class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  late final Dio _dio;
  late final http.Client _httpClient;
  late final OllamaRemoteDataSource _remoteDataSource;
  late final WebSearchDataSource _searchDataSource;
  late final LlmRepository _repository;
  late final SearchRepository _searchRepository;
  late final GetAvailableModels _getAvailableModels;
  late final GenerateResponse _generateResponse;
  late final GenerateResponseStream _generateResponseStream;
  late final SearchWeb _searchWeb;
  late final FetchWebContent _fetchWebContent;
  late final LlmController _controller;

  void initialize() {
    _setupNetworking();
    _setupDataSources();
    _setupRepositories();
    _setupUseCases();
    _setupControllers();
  }

  void _setupNetworking() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint('[DIO] $object'),
      ),
    );

    _httpClient = RobustHttpClient();
  }

  void _setupDataSources() {
    _remoteDataSource = OllamaRemoteDataSourceImpl(
      dio: _dio,
      baseUrl: 'http://localhost:11434',
    );

    _searchDataSource = LocalWebSearchDataSource(client: _httpClient);
  }

  void _setupRepositories() {
    _repository = LlmRepositoryImpl(remoteDataSource: _remoteDataSource);

    _searchRepository = SearchRepositoryImpl(dataSource: _searchDataSource);
  }

  void _setupUseCases() {
    _getAvailableModels = GetAvailableModels(_repository);
    _generateResponse = GenerateResponse(_repository);
    _generateResponseStream = GenerateResponseStream(_repository);
    _searchWeb = SearchWeb(_searchRepository);
    _fetchWebContent = FetchWebContent(_searchRepository);
  }

  void _setupControllers() {
    _controller = LlmController(
      getAvailableModels: _getAvailableModels,
      generateResponse: _generateResponse,
      generateResponseStream: _generateResponseStream,
      searchWeb: _searchWeb,
    );
  }

  // Getters
  Dio get dio => _dio;
  http.Client get httpClient => _httpClient;
  OllamaRemoteDataSource get remoteDataSource => _remoteDataSource;
  WebSearchDataSource get searchDataSource => _searchDataSource;
  LlmRepository get repository => _repository;
  SearchRepository get searchRepository => _searchRepository;
  GetAvailableModels get getAvailableModels => _getAvailableModels;
  GenerateResponse get generateResponse => _generateResponse;
  GenerateResponseStream get generateResponseStream => _generateResponseStream;
  SearchWeb get searchWeb => _searchWeb;
  FetchWebContent get fetchWebContent => _fetchWebContent;
  LlmController get controller => _controller;
}
