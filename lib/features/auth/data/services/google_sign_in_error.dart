import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

String googleSignInError(Object error) {
  if (error is TimeoutException) {
    return 'Google oturumu zaman aşımına uğradı. Yeniden dene.';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'operation-not-allowed' =>
        'Google ile giriş Firebase Authentication ayarlarında etkin değil.',
      'account-exists-with-different-credential' =>
        'Bu e-posta başka bir giriş yöntemiyle kayıtlı. Önce o yöntemle giriş yap.',
      'invalid-credential' =>
        'Google giriş ayarları doğrulanamadı. Uygulama yapılandırması kontrol edilmeli.',
      'network-request-failed' =>
        'Bağlantı kurulamadı. İnternet bağlantını kontrol et.',
      'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
      _ => 'Google ile giriş tamamlanamadı. (${error.code})',
    };
  }
  if (error is FirebaseException) {
    return error.code == 'permission-denied'
        ? 'Giriş sonrası profil veya token işlemi engellendi. Firebase güvenlik kuralları kontrol edilmeli.'
        : 'Giriş sonrası profil yüklenemedi. (${error.code})';
  }
  if (error is PlatformException) {
    if (error.code == 'sign_in_canceled' || error.code == 'sign_in_cancelled') {
      return 'Google ile giriş iptal edildi.';
    }
    if (error.code == 'network_error') {
      return 'Bağlantı kurulamadı. İnternet bağlantını kontrol et.';
    }
    if (error.code == 'sign_in_failed' &&
        (error.message?.contains('ApiException: 10') ?? false)) {
      return 'Google giriş yapılandırması eksik. Android imza sertifikası ve Firebase SHA ayarları kontrol edilmeli.';
    }
    return 'Google ile giriş tamamlanamadı. (${error.code})';
  }
  if (error is StateError) return error.message.toString();
  return 'Google ile giriş tamamlanamadı. Lütfen yeniden dene.';
}
