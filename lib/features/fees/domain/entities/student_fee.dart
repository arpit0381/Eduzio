class StudentFee {
  final String id;
  final String organizationId;
  final String studentId;
  final String studentName;
  final String? batchId;
  final String? batchName;
  final double amount;
  final DateTime dueDate;
  final String status; // 'paid', 'pending', 'overdue'
  final double paidAmount;
  final DateTime? paidDate;
  final String? remarks;
  final DateTime? createdAt;

  const StudentFee({
    required this.id,
    required this.organizationId,
    required this.studentId,
    this.studentName = '',
    this.batchId,
    this.batchName,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAmount = 0.0,
    this.paidDate,
    this.remarks,
    this.createdAt,
  });

  factory StudentFee.fromJson(Map<String, dynamic> json) {
    // Check if student profile data is joined
    final studentData = json['profiles'] as Map<String, dynamic>?;
    final studentName = studentData != null ? (studentData['name'] as String? ?? '') : '';

    // Check if batch data is joined
    final batchData = json['batches'] as Map<String, dynamic>?;
    final batchName = batchData != null ? (batchData['name'] as String? ?? '') : '';

    return StudentFee(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      studentId: json['student_id'] as String,
      studentName: studentName,
      batchId: json['batch_id'] as String?,
      batchName: batchName,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String? ?? 'pending',
      paidAmount: (json['paid_amount'] as num? ?? 0.0).toDouble(),
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date'] as String) : null,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'student_id': studentId,
      'batch_id': batchId,
      'amount': amount,
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'status': status,
      'paid_amount': paidAmount,
      'paid_date': paidDate?.toIso8601String(),
      'remarks': remarks,
    };
  }

  StudentFee copyWith({
    String? id,
    String? organizationId,
    String? studentId,
    String? studentName,
    String? batchId,
    String? batchName,
    double? amount,
    DateTime? dueDate,
    String? status,
    double? paidAmount,
    DateTime? paidDate,
    String? remarks,
    DateTime? createdAt,
  }) {
    return StudentFee(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      paidDate: paidDate ?? this.paidDate,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
