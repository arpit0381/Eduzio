import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/student_fee.dart';
import '../../domain/repositories/fees_repository.dart';

class FeesRepositoryImpl implements FeesRepository {
  final SupabaseClient _client;

  FeesRepositoryImpl(this._client);

  @override
  Future<List<StudentFee>> getFees(String organizationId, {String? studentId}) async {
    var query = _client
        .from('student_fees')
        .select('*, profiles:student_id(name), batches:batch_id(name)')
        .eq('organization_id', organizationId);
    
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    
    final response = await query.order('due_date', ascending: false);
    return (response as List).map((json) => StudentFee.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> addFeeRecord(StudentFee fee) async {
    await _client.from('student_fees').insert(fee.toJson());
  }

  @override
  Future<void> submitPayment({
    required String feeId,
    required double paidAmount,
    String? remarks,
  }) async {
    final data = await _client.from('student_fees').select().eq('id', feeId).single();
    final double amount = (data['amount'] as num).toDouble();
    final double currentPaid = (data['paid_amount'] as num? ?? 0.0).toDouble();

    final newPaid = currentPaid + paidAmount;
    final status = newPaid >= amount ? 'paid' : 'pending';

    await _client.from('student_fees').update({
      'paid_amount': newPaid,
      'paid_date': DateTime.now().toIso8601String(),
      'status': status,
      'remarks': remarks,
    }).eq('id', feeId);
  }
}
