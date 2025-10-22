import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../utils/supabase_config.dart';

class AuthService {
  static final SupabaseClient _client = SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.name,
        },
      );

      return response;
    } catch (e) {
      if (e is AuthException) {
        throw Exception('Authentication failed: ${e.message}');
      } else if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      } else {
        throw Exception('Sign up failed: ${e.toString()}');
      }
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) {
        return null;
      }

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        try {
          final userMetadata = user.userMetadata ?? {};
          final profile = UserProfile(
            id: user.id,
            email: user.email ?? '',
            fullName: userMetadata['full_name'] ?? '',
            role: UserRole.values.firstWhere(
              (r) => r.name == userMetadata['role'],
              orElse: () => UserRole.student,
            ),
            createdAt: DateTime.parse(user.createdAt),
          );

          await _client.from('profiles').insert(profile.toJson());
          return profile;
        } catch (createError) {
          return null;
        }
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String fullName,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _client.from('profiles').update({
        'full_name': fullName,
      }).eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  bool get isAuthenticated => currentUser != null;

  String? get userId => currentUser?.id;
}