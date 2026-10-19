import 'package:coetus/core/text/skill_normalization.dart';

String normalizeUsername(String value) =>
    normalizeText(value.trim().replaceFirst(RegExp(r'^@'), ''));
const reservedUsernames = {
  'admin',
  'administrator',
  'coetus',
  'support',
  'destek',
  'moderator',
  'system',
};
String? usernameError(String? input) {
  final value = normalizeUsername(input ?? '');
  if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(value)) {
    return '3–24 karakter kullan: harf, rakam ve alt çizgi.';
  }
  if (reservedUsernames.contains(value)) {
    return 'Bu kullanıcı adı kullanılamaz.';
  }
  return null;
}

String suggestUsername(String name, String suffix) {
  var base = normalizeText(
    name,
  ).replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  if (base.isEmpty) base = 'birlikte';
  if (base.length > 17) base = base.substring(0, 17);
  return '${base}_${suffix.replaceAll(RegExp(r'[^a-z0-9]'), '').padRight(5, '0').substring(0, 5)}';
}

String profileQrData(String userId) =>
    Uri(scheme: 'coetus', host: 'profile', pathSegments: [userId]).toString();
String parseProfileQr(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme != 'coetus' ||
      uri.host != 'profile' ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      uri.pathSegments.length != 1 ||
      !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(uri.pathSegments.single)) {
    throw const FormatException('Bu bir COETUS profil QR kodu değil.');
  }
  return uri.pathSegments.single;
}
