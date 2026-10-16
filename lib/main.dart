import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/firebase_setup_app.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await initializeCoetus());
}

/// Build Firebase-dependent routing only after initialization succeeds.
Future<Widget> initializeCoetus({
  Future<void> Function()? initializeFirebase,
  Widget Function()? buildApplication,
}) async {
  try {
    await (initializeFirebase ?? FirebaseBootstrap.initialize)();
  } catch (error) {
    return FirebaseSetupApp(error: error);
  }
  return buildApplication?.call() ?? const ProviderScope(child: CoetusApp());
}
