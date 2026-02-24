import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class LocalAuthService implements AuthService {
  static const String _authBoxName = 'auth';
  static const String _usersBoxName = 'users';
  static const String _currentUserKey = 'current_user';

  Future<Box> _openAuthBox() async {
    return await Hive.openBox(_authBoxName);
  }

  Future<Box> _openUsersBox() async {
    return await Hive.openBox(_usersBoxName);
  }

  /// Simple hash for password (NOT production-safe, just for local testing)
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  @override
  Future<User?> signUp({required String email, required String password, String? displayName}) async {
    final usersBox = await _openUsersBox();

    // Check if email already registered
    if (usersBox.containsKey(email)) {
      return null; // Already exists
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      displayName: displayName ?? email.split('@').first,
    );

    // Store user with hashed password
    await usersBox.put(email, {
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'passwordHash': _hashPassword(password),
    });

    // Auto-login after signup
    final authBox = await _openAuthBox();
    await authBox.put(_currentUserKey, {
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
    });

    return user;
  }

  @override
  Future<User?> signIn({required String email, required String password}) async {
    final usersBox = await _openUsersBox();

    // Check if user exists
    final data = usersBox.get(email);
    if (data == null) {
      throw Exception('EMAIL_NOT_FOUND');
    }

    final map = Map<String, dynamic>.from(data);

    // Verify password
    if (map['passwordHash'] != _hashPassword(password)) {
      throw Exception('WRONG_PASSWORD');
    }

    final user = User(
      id: map['id'],
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
    );

    // Store current session
    final authBox = await _openAuthBox();
    await authBox.put(_currentUserKey, {
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
    });

    return user;
  }

  @override
  Future<void> signOut() async {
    final authBox = await _openAuthBox();
    await authBox.delete(_currentUserKey);
  }

  @override
  Future<User?> getCurrentUser() async {
    final authBox = await _openAuthBox();
    final data = authBox.get(_currentUserKey);

    if (data == null) return null;

    final map = Map<String, dynamic>.from(data);
    return User(
      id: map['id'],
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
    );
  }
}
