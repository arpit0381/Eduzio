import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
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
    );
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
      return _mapToEntity(data);
    } catch (e) {
      // If profile row doesn't exist, we fall back to reading from user metadata
      final meta = user.userMetadata;
      if (meta != null) {
        return UserProfile(
          id: user.id,
          organizationId: meta['organization_id'] as String?,
          name: (meta['name'] ?? user.email?.split('@').first) as String,
          email: user.email ?? '',
          role: UserProfileRole.fromKey((meta['role'] ?? 'student') as String),
        );
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
    // 1. Sign up the owner admin account
    final authRes = await _client.auth.signUp(
      email: ownerEmail,
      password: ownerPassword,
      data: {
        'name': ownerName,
        'role': UserProfileRole.admin.key,
      },
    );

    if (authRes.user == null) {
      throw Exception('Failed to register owner admin credentials');
    }

    // 2. Create the Organization record
    // RLS bypass: insertion into organizations table is permitted for authenticated users
    final orgRes = await _client.from('organizations').insert({
      'name': orgName,
      'subdomain': subdomain,
      'settings': {'phone': phone},
    }).select().single();

    final orgId = orgRes['id'] as String;

    // 3. Link profile to the newly created organization
    await _client.from('profiles').update({
      'organization_id': orgId,
    }).eq('id', authRes.user!.id);
    
    // Sign out because auth metadata changes need a fresh login token to update the client's JWT claims
    await signOut();
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
