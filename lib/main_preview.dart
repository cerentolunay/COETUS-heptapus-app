import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'preview/preview_app.dart';
import 'preview/preview_mode.dart';
import 'features/auth/data/repositories/local_auth_repository.dart';

Future<void> main() async {
  if (!kDebugMode) {
    throw UnsupportedError('Bu giriş noktası yalnızca debug sürümü içindir.');
  }
  WidgetsFlutterBinding.ensureInitialized();
  PreviewMode.enable();
  await LocalAuthRepository().signUp(
    fullName: 'Deniz',
    email: 'deniz@example.invalid',
    password: 'preview-only',
  );
  // Deliberately never initializes Firebase or production routing.
  runApp(const PreviewApp());
}
