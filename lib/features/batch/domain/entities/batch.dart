class Batch {
  final String id;
  final String organizationId;
  final String name;
  final String code;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;

  const Batch({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    this.description,
    this.startDate,
    this.endDate,
  });

  Batch copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? code,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Batch(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
