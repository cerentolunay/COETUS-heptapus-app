import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountDeletionResult {
  const AccountDeletionResult({this.pendingCleanup = false});
  final bool pendingCleanup;
}

class AccountDeletionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool get usesGoogle =>
      _auth.currentUser?.providerData.any(
        (p) => p.providerId == 'google.com',
      ) ==
      true;
  bool get requiresPassword =>
      !usesGoogle &&
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ==
          true;
  Future<AccountDeletionResult> delete(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Hesabını silmek için önce giriş yapmalısın.');
    }
    final wasGoogle = usesGoogle;
    if (wasGoogle) {
      final account = await GoogleSignIn().signIn();
      if (account == null) {
        throw StateError('Google doğrulaması iptal edildi. Hesabın silinmedi.');
      }
      final google = await account.authentication;
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(
          accessToken: google.accessToken,
          idToken: google.idToken,
        ),
      );
    } else if (requiresPassword) {
      if (password.isEmpty) throw StateError('Devam etmek için şifreni yaz.');
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    }
    await user.getIdToken(true);
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable(
          'deleteAccount',
          options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
        )
        .call({'confirm': true});
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['deleted'] != true) {
      throw StateError('Hesap silme tamamlanamadı. Yeniden dene.');
    }
    await _auth.signOut();
    try {
      if (wasGoogle) await GoogleSignIn().signOut();
    } catch (_) {
      /* Firebase account is already deleted and signed out. */
    }
    return AccountDeletionResult(
      pendingCleanup: data['pendingCleanup'] == true,
    );
  }
}

String accountDeletionError(Object error) {
  if (error is StateError) return error.message;
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'wrong-password' || 'invalid-credential' || 'invalid-login-credentials' =>
        'Şifre doğrulanamadı. Hesabın silinmedi; yeniden dene.',
      'user-mismatch' =>
        'Hesabını silmek için aynı Google hesabıyla doğrulama yapmalısın.',
      'requires-recent-login' =>
        'Güvenlik için yeniden giriş yapıp hesap silmeyi tekrar dene.',
      'network-request-failed' => 'Bağlantı kurulamadı. Yeniden dene.',
      _ => 'Kimlik doğrulaması tamamlanamadı. Yeniden giriş yapıp tekrar dene.',
    };
  }
  if (error is FirebaseFunctionsException) {
    if (error.code == 'not-found' || error.code == 'unimplemented') {
      return 'Hesap silme hizmeti bu sürüm için henüz yayımlanmadı.';
    }
    if (error.code == 'unauthenticated') {
      return 'Güvenlik için yeniden giriş yapıp hesap silmeyi tekrar dene.';
    }
    return error.message ?? 'Hesap silinemedi. Yeniden dene.';
  }
  return 'İşlem tamamlanamadı. Yeniden dene.';
}
