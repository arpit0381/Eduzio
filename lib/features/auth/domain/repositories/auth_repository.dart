import '../entities/user_profile.dart';

abstract class AuthRepository {
  /// Stream of user profile updates when authentication state changes
  Stream<UserProfile?> get authStateChanges;

  /// Fetch the current user profile from database
  Future<UserProfile?> getCurrentUserProfile();

  /// Sign in with email and password
  Future<UserProfile> signInWithEmailAndPassword(String email, String password);

  /// Sign up with email and password
  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserProfileRole role,
    String? organizationId,
  });

  /// Trigger mobile OTP sending
  Future<void> signInWithOtp(String phone);

  /// Verify mobile OTP token
  Future<UserProfile> verifyOtp(String phone, String token);

  /// Onboard a new Coaching Institute (Organization) and create owner admin profile
  Future<void> onboardOrganization({
    required String orgName,
    required String subdomain,
    required String phone,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  });

  /// Update the user's avatar URL in database and emit updated profile
  Future<void> updateAvatarUrl(String avatarUrl);

  /// Sign out current user
  Future<void> signOut();
}
