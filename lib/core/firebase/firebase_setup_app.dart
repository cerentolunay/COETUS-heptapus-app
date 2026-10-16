import 'package:flutter/material.dart';
import '../../app/theme/coetus_theme.dart';
import '../../app/theme/coetus_tokens.dart';
import '../../widgets/coetus_mascot.dart';

/// A setup failure must not construct the Firebase-dependent application router.
class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: coetusTheme(useGoogleFonts: false),
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CoetusMascot(
                      size: 140,
                      animate: false,
                      interactive: false,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    error is UnsupportedError
                        ? 'Firebase platform ayarı eksik'
                        : 'Firebase başlatılamadı',
                    style: const TextStyle(
                      color: CoetusPalette.purple,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Uygulamanın bağlantı ayarı tamamlanmadan hesap ve mesaj ekranları açılamaz.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CoetusPalette.cream,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chrome için kurulum',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Firebase Console → coetus-bc9c6 → Proje ayarları bölümünü aç.\n\n'
                          '2. Web (</>) uygulaması ekle veya mevcut web uygulamasını seç.\n\n'
                          '3. Web bağlantı bilgilerini lib/firebase_options.dart dosyasına ekle. FlutterFire CLI ile de yapılandırabilirsin.\n\n'
                          '4. Uygulamayı terminalde durdurup yeniden çalıştır.',
                        ),
                        const SizedBox(height: 18),
                        const SelectableText(
                          'flutterfire configure --project=coetus-bc9c6 --platforms=android,ios,web',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Teknik ayrıntı'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(error.toString()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
