import 'package:coetus/preview/preview_mode.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/widgets/coetus_mascot.dart';

class OnboardingIntroPage extends StatefulWidget {
  const OnboardingIntroPage({super.key});

  @override
  State<OnboardingIntroPage> createState() => _OnboardingIntroPageState();
}

class _OnboardingIntroPageState extends State<OnboardingIntroPage> {
  bool _continuing = false;

  Future<void> _completeOnboarding(String route) async {
    if (_continuing) return;
    setState(() => _continuing = true);
    if (PreviewMode.enabled) {
      context.go(route);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    context.go(FirebaseAuth.instance.currentUser != null ? '/home' : route);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('coetus', style: text.headlineSmall),
                      ),
                      TextButton(
                        onPressed: _continuing
                            ? null
                            : () => _completeOnboarding('/register'),
                        child: const Text('Atla'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CoetusPalette.purple,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Column(
                      children: [
                        const CoetusMascot(size: 180),
                        Text(
                          'Bir yetenek ver.\nYeni bir dünya keşfet.',
                          textAlign: TextAlign.center,
                          style: text.headlineMedium?.copyWith(
                            color: CoetusPalette.cream,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Burada para değil, bilgi dolaşır. Öğreterek kazandığın kredilerle öğrenmeye devam et.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: CoetusPalette.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Step(
                    number: '01',
                    title: 'Bildiğini paylaş',
                    subtitle: 'Öğretebileceğin yetenekleri profiline ekle.',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 12),
                  const _Step(
                    number: '02',
                    title: 'Doğru kişiyle eşleş',
                    subtitle: 'Yetenek ve zaman uyumuna göre keşfet.',
                    icon: Icons.auto_awesome_outlined,
                  ),
                  const SizedBox(height: 12),
                  const _Step(
                    number: '03',
                    title: 'Kazan ve öğren',
                    subtitle:
                        'Oturumdan kazandığın krediyi yeni bir yetenekte kullan.',
                    icon: Icons.swap_horiz_rounded,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _continuing
                        ? null
                        : () => _completeOnboarding('/register'),
                    child: const Text('Birlikte başlayalım'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _continuing
                        ? null
                        : () => _completeOnboarding('/login'),
                    child: const Text('Hesabım var · Giriş yap'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CoetusPalette.cream,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: CoetusPalette.lime,
          foregroundColor: CoetusPalette.purple,
          child: Icon(icon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number  $title',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}
