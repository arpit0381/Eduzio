import '../entities/student_fee.dart';

abstract class FeesRepository {
  Future<List<StudentFee>> getFees(String organizationId, {String? studentId});
  Future<void> addFeeRecord(StudentFee fee);
  Future<void> submitPayment({
    required String feeId,
    required double paidAmount,
    String? remarks,
  });
}
