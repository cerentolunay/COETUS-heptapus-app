import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_factory.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../notifiers/auth_state_notifier.dart';

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryFactory.create();
});

/// Auth state notifier provider - UI'da auth state'i dinlemek için
/// Örn: ref.watch(authStateNotifierProvider).isSignedIn
final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  // Global notifier'ı kullan (app_router.dart'ta oluşturulan)
  // Not: Ideal olarak bu singleton pattern yerine InheritedNotifier
  // kullanmak daha iyi olurdu, fakat minimal implementation için böyle yeterli
  return AuthStateNotifier();
});

/// Auth state stream provider - kullanıcı giriş durumunu izler
/// Real-time auth changes'i stream eder
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

/// Async auth state - loading/error states için tam kontrol sağlar
final asyncAuthStateProvider = FutureProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getCurrentUser();
});

/// Kullanıcının giriş yapıp yapmadığını kontrol eden provider
/// Loading state'de false döndürerek kullanıcıyı giriş sayfasında tutmaz
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.maybeWhen(data: (user) => user != null, orElse: () => false);
});

/// Şu anki kullanıcıyı döndüren provider
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.maybeWhen(data: (user) => user, orElse: () => null);
});
