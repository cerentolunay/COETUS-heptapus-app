import 'dart:async';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  static AppUser? _currentUser;
  static final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  static AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() {
    return _authController.stream;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = AppUser(
      id: _buildUserId(normalizedEmail),
      name: _buildDisplayName(normalizedEmail),
      email: normalizedEmail,
      bio: 'Yeteneklerini paylaşmayı seven bir topluluk üyesi',
      trustScore: 12,
      credits: 200,
      verified: false,
      profileCompleted: true,
    );

    _currentUser = user;
    _authController.add(_currentUser);
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = AppUser(
      id: _buildUserId(normalizedEmail),
      name: fullName.trim(),
      email: normalizedEmail,
      bio: 'Birlikte öğrenmeye hazır',
      trustScore: 0,
      credits: 200,
      verified: false,
      profileCompleted: true,
    );

    _currentUser = user;
    _authController.add(_currentUser);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final user = AppUser(
      id: _buildUserId('google.user@example.com'),
      name: 'Google kullanıcısı',
      email: 'google.user@example.com',
      bio: 'Yeteneklerini paylaşmayı seven bir topluluk üyesi',
      trustScore: 12,
      credits: 200,
      verified: true,
      profileCompleted: true,
    );

    _currentUser = user;
    _authController.add(_currentUser);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(_currentUser);
  }

  String _buildUserId(String email) {
    return email.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  String _buildDisplayName(String email) {
    final localPart = email.split('@').first;
    if (localPart.isEmpty) {
      return 'COETUS User';
    }

    return localPart
        .split(RegExp(r'[._-]'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
