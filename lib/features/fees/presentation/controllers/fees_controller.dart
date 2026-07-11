import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/student_fee.dart';
import '../../domain/repositories/fees_repository.dart';
import '../../data/repositories/fees_repository_impl.dart';

final feesRepositoryProvider = Provider<FeesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FeesRepositoryImpl(client);
});

class FeesController extends AsyncNotifier<List<StudentFee>> {
  late FeesRepository _repository;

  @override
  Future<List<StudentFee>> build() async {
    _repository = ref.watch(feesRepositoryProvider);
    
    // Subscribe to realtime database updates for the student_fees table
    final client = ref.watch(supabaseClientProvider);
    final subscription = client
        .channel('public:student_fees')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'student_fees',
          callback: (payload) {
            debugPrint('Realtime fee database update received: ${payload.toString()}');
            refresh();
          },
        )
        .subscribe();

    // Safely unsubscribe when the provider is disposed
    ref.onDispose(() {
      client.removeChannel(subscription);
    });

    return _fetchFees();
  }

  Future<List<StudentFee>> _fetchFees() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.organizationId == null) return [];

    if (user.role == UserProfileRole.student) {
      return _repository.getFees(user.organizationId!, studentId: user.id);
    } else {
      return _repository.getFees(user.organizationId!);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFees());
  }

  Future<void> addFeeRecord({
    required String studentId,
    String? batchId,
    required double amount,
    required DateTime dueDate,
    String? remarks,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.organizationId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final fee = StudentFee(
        id: '',
        organizationId: user.organizationId!,
        studentId: studentId,
        batchId: batchId,
        amount: amount,
        dueDate: dueDate,
        status: 'pending',
        remarks: remarks,
      );
      await _repository.addFeeRecord(fee);

      // Trigger automatic notifications (In-App and Push)
      try {
        final client = ref.read(supabaseClientProvider);
        final title = 'New Fee Assigned';
        final body = 'A new fee of ₹${amount.toStringAsFixed(0)} is due on ${DateFormat('dd MMM yyyy').format(dueDate)}.';

        // 1. Create in-app announcement targeted specifically at this student
        await client.from('announcements').insert({
          'organization_id': user.organizationId,
          'title': title,
          'content': body,
          'target_roles': ['student'],
          'user_id': studentId,
        });

        // 2. Trigger push notification
        await client.functions.invoke(
          'send-fcm',
          body: {
            'title': title,
            'body': body,
            'target': 'user',
            'userId': studentId,
            'organizationId': user.organizationId,
            'isGlobal': false,
          },
        );
      } catch (e) {
        debugPrint('Failed to send fee assignment notifications: $e');
      }

      return _fetchFees();
    });
  }

  Future<void> submitPayment({
    required String feeId,
    required double paidAmount,
    String? remarks,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      
      // Fetch fee details prior to payment to get student ID and name
      final feeData = await client.from('student_fees').select('*, profiles:student_id(name)').eq('id', feeId).single();
      final studentId = feeData['student_id'] as String;
      final studentName = feeData['profiles'] != null ? (feeData['profiles']['name'] as String? ?? 'Student') : 'Student';
      final orgId = feeData['organization_id'] as String;

      await _repository.submitPayment(feeId: feeId, paidAmount: paidAmount, remarks: remarks);

      // Trigger automatic notifications (In-App and Push)
      try {
        final title = 'Fee Payment Received';
        final body = 'Payment of ₹${paidAmount.toStringAsFixed(0)} registered successfully for student $studentName.';

        // 1. Create in-app announcement targeted specifically at this student
        await client.from('announcements').insert({
          'organization_id': orgId,
          'title': title,
          'content': body,
          'target_roles': ['student'],
          'user_id': studentId,
        });

        // 2. Trigger push notification
        await client.functions.invoke(
          'send-fcm',
          body: {
            'title': title,
            'body': body,
            'target': 'user',
            'userId': studentId,
            'organizationId': orgId,
            'isGlobal': false,
          },
        );
      } catch (e) {
        debugPrint('Failed to send fee payment notifications: $e');
      }

      return _fetchFees();
    });
  }
}

final feesControllerProvider = AsyncNotifierProvider<FeesController, List<StudentFee>>(() {
  return FeesController();
});
