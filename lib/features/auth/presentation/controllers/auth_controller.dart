import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(client);
});

// StreamProvider tracking current session user profile
final authStateProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// State definition for UI actions (login, signup, onboarding)
class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;
  final UserProfile? user;

  const AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserProfile? user,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

// Controller managing Auth Actions using modern Notifier API
class AuthController extends Notifier<AuthControllerState> {
  @override
  AuthControllerState build() {
    return const AuthControllerState();
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signInWithEmailAndPassword(email, password);
      state = AuthControllerState(user: user);
    } catch (e) {
      state = AuthControllerState(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserProfileRole role,
    String? organizationId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
        organizationId: organizationId,
      );
      state = AuthControllerState(user: user);
    } catch (e) {
      state = AuthControllerState(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> onboard({
    required String orgName,
    required String subdomain,
    required String phone,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.onboardOrganization(
        orgName: orgName,
        subdomain: subdomain,
        phone: phone,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        ownerPassword: ownerPassword,
      );
      state = const AuthControllerState();
    } catch (e) {
      state = AuthControllerState(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      state = const AuthControllerState();
    } catch (e) {
      state = AuthControllerState(errorMessage: e.toString());
      rethrow;
    }
  }
}

// Provider for AuthController
final authControllerProvider = NotifierProvider<AuthController, AuthControllerState>(() {
  return AuthController();
});
