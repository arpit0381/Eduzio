enum AttendanceStatus {
  present,
  absent,
  late,
  leave;

  String get key => name;

  static AttendanceStatus fromKey(String key) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == key.toLowerCase(),
      orElse: () => AttendanceStatus.absent,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String organizationId;
  final String batchId;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String? markedBy;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.organizationId,
    required this.batchId,
    required this.studentId,
    required this.date,
    required this.status,
    this.markedBy,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  AttendanceRecord copyWith({
    String? id,
    String? organizationId,
    String? batchId,
    String? studentId,
    DateTime? date,
    AttendanceStatus? status,
    String? markedBy,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      batchId: batchId ?? this.batchId,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
