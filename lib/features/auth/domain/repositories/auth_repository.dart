import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser?> getCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}
