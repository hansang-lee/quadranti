import '../models/user_model.dart';

/// Abstract auth service interface.
/// Swap LocalAuthService → GoogleAuthService later.
abstract class AuthService {
  Future<User?> signUp({required String email, required String password, String? displayName});
  Future<User?> signIn({required String email, required String password});
  Future<void> signOut();
  Future<User?> getCurrentUser();
}
