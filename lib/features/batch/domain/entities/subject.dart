class Subject {
  final String id;
  final String organizationId;
  final String name;
  final String code;
  final String? description;

  const Subject({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    this.description,
  });

  Subject copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? code,
    String? description,
  }) {
    return Subject(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
    );
  }
}
