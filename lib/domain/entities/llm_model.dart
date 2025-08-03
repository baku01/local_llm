/// Entidade que representa um modelo de linguagem LLM disponível.
///
/// Esta classe define as propriedades básicas de um modelo LLM que pode
/// ser usado na aplicação, incluindo metadados como tamanho e data de modificação.
class LlmModel {
  /// Nome único do modelo (por exemplo: "llama2", "mistral").
  final String name;

  /// Descrição opcional do modelo fornecida pelo servidor.
  final String? description;

  /// Data da última modificação do modelo no servidor.
  final DateTime? modifiedAt;

  /// Tamanho do modelo em bytes, se disponível.
  final int? size;

  /// Construtor da entidade LlmModel.
  ///
  /// [name] é obrigatório pois é o identificador único do modelo.
  /// Demais propriedades são opcionais e dependem da disponibilidade
  /// de informações do servidor Ollama.
  const LlmModel({
    required this.name,
    this.description,
    this.modifiedAt,
    this.size,
  });

  /// Comparação de igualdade baseada apenas no nome do modelo.
  ///
  /// Dois modelos são considerados iguais se possuem o mesmo nome,
  /// independente de outros metadados.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LlmModel &&
          runtimeType == other.runtimeType &&
          name == other.name;

  /// Hash code baseado no nome do modelo para uso em coleções.
  @override
  int get hashCode => name.hashCode;

  /// Representação textual da entidade para debug.
  @override
  String toString() => 'LlmModel(name: $name)';
}
