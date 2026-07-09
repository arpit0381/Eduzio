import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late final FeesRepository _repository;

  @override
  Future<List<StudentFee>> build() async {
    _repository = ref.watch(feesRepositoryProvider);
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
      await _repository.submitPayment(feeId: feeId, paidAmount: paidAmount, remarks: remarks);
      return _fetchFees();
    });
  }
}

final feesControllerProvider = AsyncNotifierProvider<FeesController, List<StudentFee>>(() {
  return FeesController();
});
