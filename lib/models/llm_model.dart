class LLMModel {
  final String name;
  final String displayName;
  final String size;
  final DateTime? modifiedAt;

  const LLMModel({
    required this.name,
    required this.displayName,
    required this.size,
    this.modifiedAt,
  });

  factory LLMModel.fromJson(Map<String, dynamic> json) {
    return LLMModel(
      name: json['name'] as String,
      displayName: json['name'] as String,
      size: json['size']?.toString() ?? 'Desconhecido',
      modifiedAt: json['modified_at'] != null 
          ? DateTime.parse(json['modified_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'modified_at': modifiedAt?.toIso8601String(),
    };
  }
}