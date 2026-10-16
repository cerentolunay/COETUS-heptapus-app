import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:coetus/app/router/app_router.dart';
import 'package:coetus/app/theme/coetus_theme.dart';

class CoetusApp extends StatelessWidget {
  const CoetusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'COETUS',
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: coetusTheme(),
      routerConfig: AppRouter.router,
    );
  }
}
