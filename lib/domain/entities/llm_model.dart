class LlmModel {
  final String name;
  final String? description;
  final DateTime? modifiedAt;
  final int? size;

  const LlmModel({
    required this.name,
    this.description,
    this.modifiedAt,
    this.size,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LlmModel &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'LlmModel(name: $name)';
}
