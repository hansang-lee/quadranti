import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = LocalAuthService();

  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Check if user is already logged in (on app start)
  Future<void> checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  /// Sign up with email and password
  Future<String?> signUp({required String email, required String password, String? displayName}) async {
    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      notifyListeners();
      if (_currentUser == null) {
        return '이미 등록된 이메일입니다';
      }
      return null; // Success
    } catch (e) {
      return '회원가입에 실패했습니다';
    }
  }

  /// Sign in with email and password
  Future<String?> signIn({required String email, required String password}) async {
    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      notifyListeners();
      return null; // Success
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('EMAIL_NOT_FOUND')) {
        return '등록되지 않은 이메일입니다';
      } else if (msg.contains('WRONG_PASSWORD')) {
        return '비밀번호가 올바르지 않습니다';
      }
      return '로그인에 실패했습니다';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
