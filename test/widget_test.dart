import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eduzio/main.dart';
import 'package:eduzio/features/auth/domain/repositories/auth_repository.dart';
import 'package:eduzio/features/auth/domain/entities/user_profile.dart';
import 'package:eduzio/features/auth/presentation/controllers/auth_controller.dart';

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> get authStateChanges => _controller.stream;

  @override
  Future<UserProfile?> getCurrentUserProfile() async => null;

  @override
  Future<UserProfile> signInWithEmailAndPassword(String email, String password) async {
    return const UserProfile(
      id: 'fake-id',
      name: 'Test User',
      email: 'test@eduzio.com',
      role: UserProfileRole.student,
    );
  }

  @override
  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserProfileRole role,
    String? organizationId,
  }) async {
    return UserProfile(
      id: 'fake-id',
      name: name,
      email: email,
      role: role,
      organizationId: organizationId,
    );
  }

  @override
  Future<void> signInWithOtp(String phone) async {}

  @override
  Future<UserProfile> verifyOtp(String phone, String token) async {
    return const UserProfile(
      id: 'fake-id',
      name: 'Test User',
      email: 'test@eduzio.com',
      role: UserProfileRole.student,
    );
  }

  @override
  Future<void> onboardOrganization({
    required String orgName,
    required String subdomain,
    required String phone,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {}

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }
}

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    final fakeAuthRepository = FakeAuthRepository();

    // Build our app and trigger a frame with the fake repository override.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        ],
        child: const EduzioApp(),
      ),
    );

    // Verify that the login screen is loaded and displays app name & subtitle
    expect(find.text('Eduzio'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
