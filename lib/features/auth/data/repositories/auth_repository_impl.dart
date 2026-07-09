import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../upload/presentation/controllers/cloudinary_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final sb.SupabaseClient _client;
  
  // Controller to emit user profile changes
  final StreamController<UserProfile?> _authController = StreamController<UserProfile?>.broadcast();

  AuthRepositoryImpl(this._client) {
    // Listen to Supabase auth state changes and map them to our UserProfile
    _client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user == null) {
        _authController.add(null);
      } else {
        try {
          final profile = await getCurrentUserProfile();
          _authController.add(profile);
        } catch (e) {
          _authController.add(null);
        }
      }
    });
  }

  @override
  Stream<UserProfile?> get authStateChanges => _authController.stream;

  UserProfile _mapToEntity(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: UserProfileRole.fromKey(json['role'] as String),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Future<void> _checkAndGenerateAvatar(UserProfile profile) async {
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) return;

    unawaited(Future(() async {
      try {
        final dicebearUrl = 'https://api.dicebear.com/7.x/shapes/png?seed=${profile.id}';
        
        // 1. Download image bytes
        final response = await http.get(Uri.parse(dicebearUrl));
        if (response.statusCode != 200) return;

        // 2. Save to a temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/avatar_${profile.id}.png');
        await tempFile.writeAsBytes(response.bodyBytes);

        // 3. Upload to Cloudinary using CloudinaryService
        final cloudinary = CloudinaryService();
        final cloudinaryUrl = await cloudinary.uploadFile(
          filePath: tempFile.path,
          fileName: 'avatar_${profile.id}.png',
          folder: 'avatars',
          onProgress: (_) {},
        );

        // 4. Update in Supabase profiles
        await _client.from('profiles').update({
          'avatar_url': cloudinaryUrl,
        }).eq('id', profile.id);

        // Clean up temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        // Trigger auth state change to update UI
        final updatedProfile = profile.copyWith(avatarUrl: cloudinaryUrl);
        _authController.add(updatedProfile);
      } catch (e) {
        // fail silently in background
      }
    }));
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      final profile = _mapToEntity(data);
      _checkAndGenerateAvatar(profile);
      return profile;
    } catch (e) {
      // If profile row doesn't exist, we fall back to reading from user metadata
      final meta = user.userMetadata;
      if (meta != null) {
        final profile = UserProfile(
          id: user.id,
          organizationId: meta['organization_id'] as String?,
          name: (meta['name'] ?? user.email?.split('@').first) as String,
          email: user.email ?? '',
          role: UserProfileRole.fromKey((meta['role'] ?? 'student') as String),
          avatarUrl: meta['avatar_url'] as String?,
        );
        _checkAndGenerateAvatar(profile);
        return profile;
      }
      return null;
    }
  }

  @override
  Future<UserProfile> signInWithEmailAndPassword(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Authentication failed');
    }

    final profile = await getCurrentUserProfile();
    if (profile == null) {
      throw Exception('Profile not found');
    }
    return profile;
  }

  @override
  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserProfileRole role,
    String? organizationId,
  }) async {
    final data = {
      'name': name,
      'role': role.key,
    };
    if (organizationId != null) {
      data['organization_id'] = organizationId;
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );

    if (response.user == null) {
      throw Exception('Registration failed');
    }

    // Wait a brief moment for the DB triggers to complete
    await Future.delayed(const Duration(milliseconds: 500));

    if (response.session == null) {
      // Email confirmation is likely enabled. We cannot get the profile yet because the user is not logged in.
      // Return a basic profile to avoid throwing an error, so the UI can redirect them to login.
      return UserProfile(
        id: response.user!.id,
        organizationId: organizationId,
        name: name,
        email: email,
        role: role,
      );
    }

    final profile = await getCurrentUserProfile();
    if (profile == null) {
      throw Exception('Failed to retrieve registered profile');
    }
    return profile;
  }

  @override
  Future<void> signInWithOtp(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  @override
  Future<UserProfile> verifyOtp(String phone, String token) async {
    final response = await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: sb.OtpType.sms,
    );

    if (response.user == null) {
      throw Exception('OTP Verification failed');
    }

    final profile = await getCurrentUserProfile();
    if (profile == null) {
      throw Exception('Profile not found after OTP verification');
    }
    return profile;
  }

  @override
  Future<void> onboardOrganization({
    required String orgName,
    required String subdomain,
    required String phone,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    // 1. Create the Organization using a secure RPC that bypasses RLS
    final response = await _client.rpc(
      'create_organization_unauthenticated',
      params: {
        'org_name': orgName,
        'org_subdomain': subdomain,
        'org_phone': phone,
      },
    );
    final String orgId = response.toString();

    // 2. Officially sign up the user using GoTrue API (fixes all schema errors)
    final authResponse = await _client.auth.signUp(
      email: ownerEmail,
      password: ownerPassword,
      data: {
        'name': ownerName,
        'role': 'admin',
        'organization_id': orgId,
      },
    );

    // If Supabase email confirmation is enabled, session is null initially.
    // Try to sign in just in case it's disabled, or to trigger a proper 'please confirm email' error.
    if (authResponse.session == null) {
      await signInWithEmailAndPassword(ownerEmail, ownerPassword);
    }
  }

  @override
  Future<void> updateAvatarUrl(String avatarUrl) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').update({
      'avatar_url': avatarUrl,
    }).eq('id', user.id);

    final profile = await getCurrentUserProfile();
    if (profile != null) {
      _authController.add(profile);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
