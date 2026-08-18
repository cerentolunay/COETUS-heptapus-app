import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coetus/app/theme/coetus_tokens.dart';

class OnboardingIntroPage extends StatefulWidget {
  const OnboardingIntroPage({super.key});

  @override
  State<OnboardingIntroPage> createState() => _OnboardingIntroPageState();
}

class _OnboardingIntroPageState extends State<OnboardingIntroPage> {
  late final TapGestureRecognizer _loginTapRecognizer;

  @override
  void initState() {
    super.initState();
    _loginTapRecognizer = TapGestureRecognizer()
      ..onTap = () => _completeOnboarding('/login');
  }

  @override
  void dispose() {
    _loginTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    if (FirebaseAuth.instance.currentUser != null) {
      context.go('/home');
      return;
    }

    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coetus',
                    style: textTheme.headlineSmall?.copyWith(
                      color: CoetusColors.navyInk,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _completeOnboarding('/register'),
                    child: const Text('Atla'),
                  ),
                ],
              ),
              const Spacer(),
              const _OnboardingDiagram(),
              const SizedBox(height: 36),
              Text(
                'Bildiğini öğret,\nöğrenmek istediğini al',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: CoetusColors.navyInk,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Para değil kredi dolaşır. Bir oturum öğrettiğinde '
                'kazandığın krediyi istediğin yetenekte harcarsın.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: CoetusColors.muted,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: CoetusColors.navy,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: CoetusColors.navy.withValues(alpha: .25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: CoetusColors.navy.withValues(alpha: .25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeOnboarding('/register'),
                  child: const Text('Başla'),
                ),
              ),
              const SizedBox(height: 14),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: textTheme.bodyMedium?.copyWith(
                    color: CoetusColors.muted,
                  ),
                  children: [
                    const TextSpan(text: 'Hesabım var · '),
                    TextSpan(
                      text: 'Giriş yap',
                      style: const TextStyle(
                        color: CoetusColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: _loginTapRecognizer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingDiagram extends StatelessWidget {
  const _OnboardingDiagram();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              color: CoetusColors.plateWarm,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: CoetusColors.navy.withValues(alpha: .30),
                width: 1.5,
              ),
            ),
          ),
          const Positioned(
            top: 0,
            child: _DiagramBadge(
              background: CoetusColors.navy,
              icon: Icons.school_outlined,
              iconColor: CoetusColors.oat,
              label: 'Öğret',
            ),
          ),
          const Positioned(
            bottom: 6,
            right: 6,
            child: _DiagramBadge(
              background: CoetusColors.coral,
              icon: Icons.add_circle_outline,
              iconColor: Colors.white,
              label: 'Kredi',
            ),
          ),
          const Positioned(
            bottom: 6,
            left: 6,
            child: _DiagramBadge(
              background: CoetusColors.navy,
              icon: Icons.menu_book_outlined,
              iconColor: CoetusColors.oat,
              label: 'Öğren',
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagramBadge extends StatelessWidget {
  const _DiagramBadge({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: CoetusShadow.raised,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: CoetusColors.navyInk,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
