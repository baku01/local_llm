/// Biblioteca que define o caso de uso para geração de respostas em stream.
/// 
/// Esta biblioteca contém o caso de uso [GenerateResponseStream] que
/// permite gerar respostas de modelos LLM em formato de stream,
/// possibilitando exibição progressiva do conteúdo.
library;

import '../repositories/llm_repository.dart';

/// Caso de uso para geração de respostas LLM em stream.
/// 
/// Esta classe encapsula a lógica de negócio para gerar respostas
/// de modelos de linguagem em formato de stream, permitindo que
/// a interface do usuário exiba o conteúdo conforme ele é gerado.
/// 
/// O padrão de stream é útil para:
/// - Melhorar a experiência do usuário com feedback em tempo real
/// - Reduzir a percepção de latência
/// - Permitir interrupção da geração se necessário
/// 
/// Exemplo de uso:
/// ```dart
/// final useCase = GenerateResponseStream(repository);
/// 
/// final stream = useCase(
///   prompt: 'Explique o que é Flutter',
///   modelName: 'llama2',
/// );
/// 
/// await for (final chunk in stream) {
///   print(chunk); // Exibe cada parte da resposta conforme gerada
/// }
/// ```
class GenerateResponseStream {
  /// Repositório para operações com modelos LLM.
  /// 
  /// Esta propriedade mantém uma referência para o [LlmRepository]
  /// que será usado para executar operações de geração de resposta.
  final LlmRepository repository;

  /// Cria uma nova instância de [GenerateResponseStream].
  /// 
  /// Parâmetros:
  /// - [repository]: O repositório para operações LLM.
  const GenerateResponseStream(this.repository);

  /// Executa o caso de uso de geração de resposta em stream.
  /// 
  /// Este método inicia a geração de uma resposta usando o modelo
  /// especificado e retorna um stream que emite partes da resposta
  /// conforme ela é gerada.
  /// 
  /// Parâmetros:
  /// - [prompt]: O texto de entrada para o modelo.
  /// - [modelName]: O nome do modelo a ser usado para gerar a resposta.
  /// 
  /// Retorna um [Stream<String>] que emite partes da resposta conforme
  /// são geradas pelo modelo. O stream será finalizado quando a
  /// resposta estiver completa.
  /// 
  /// Exemplo:
  /// ```dart
  /// final stream = useCase(
  ///   prompt: 'O que é programação?',
  ///   modelName: 'codellama',
  /// );
  /// 
  /// await for (final chunk in stream) {
  ///   stdout.write(chunk);
  /// }
  /// ```
  Stream<String> call({required String prompt, required String modelName}) {
    if (prompt.trim().isEmpty) {
      throw ArgumentError('O prompt não pode estar vazio');
    }

    if (modelName.trim().isEmpty) {
      throw ArgumentError('O nome do modelo não pode estar vazio');
    }

    return repository.generateResponseStream(
      prompt: prompt,
      modelName: modelName,
    );
  }
}
