import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.isAuthenticated;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((AuthState data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _loadUserProfile();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _userProfile = null;
        notifyListeners();
      }
    });


    if (_authService.isAuthenticated) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _authService.getUserProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Помилка завантаження профілю: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      if (response.user != null) {
        await _loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Помилка реєстрації: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Помилка входу: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _userProfile = null;
    } catch (e) {
      _errorMessage = 'Помилка виходу: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email: email);
      return true;
    } catch (e) {
      _errorMessage = 'Помилка скидання пароля: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({required String fullName}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserProfile(fullName: fullName);
      await _loadUserProfile();
      return true;
    } catch (e) {
      _errorMessage = 'Помилка оновлення профіля: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }


  Future<void> reloadUserProfile() async {
    await _loadUserProfile();
  }
}