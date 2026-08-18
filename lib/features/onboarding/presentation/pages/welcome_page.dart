import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:coetus/app/theme/coetus_tokens.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: CoetusColors.navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coetus',
                          style: textTheme.headlineSmall?.copyWith(
                            color: CoetusColors.oat,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Yeteneğin\nsenin paran.',
                          style: textTheme.displaySmall?.copyWith(
                            color: CoetusColors.oat,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            fontSize: 38,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Coetus'ta bir konuyu öğretip kredi kazanırsın, "
                          'o krediyle sana lazım olan başka bir yeteneği '
                          'öğrenirsin.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: CoetusColors.oat.withValues(alpha: .70),
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _WelcomeFeatureRow(
                          iconBackground: CoetusColors.plateWarm,
                          icon: Icons.school_outlined,
                          iconColor: CoetusColors.navy,
                          title: 'Öğret',
                          subtitle: 'Bildiğin konuyu bir oturumda anlat',
                        ),
                        const SizedBox(height: 14),
                        const _WelcomeFeatureRow(
                          iconBackground: CoetusColors.coral,
                          icon: Icons.add_circle_outline,
                          iconColor: Colors.white,
                          title: 'Kredi kazan',
                          subtitle:
                              'Oturum onaylanınca kredi hesabına geçer',
                        ),
                        const SizedBox(height: 14),
                        const _WelcomeFeatureRow(
                          iconBackground: CoetusColors.plateWarm,
                          icon: Icons.menu_book_outlined,
                          iconColor: CoetusColors.navy,
                          title: 'Öğren',
                          subtitle: 'Krediyi istediğin yetenekte harca',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/onboarding'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CoetusColors.oat,
                              foregroundColor: CoetusColors.navy,
                            ),
                            child: const Text('Ücretsiz hesap aç'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('/login'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: CoetusColors.oat,
                              side: BorderSide(
                                color: CoetusColors.oat.withValues(alpha: .45),
                                width: 1.5,
                              ),
                            ),
                            child: const Text('Giriş yap'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeFeatureRow extends StatelessWidget {
  const _WelcomeFeatureRow({
    required this.iconBackground,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final Color iconBackground;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CoetusColors.oat.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(CoetusRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: CoetusColors.oat,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: CoetusColors.oat.withValues(alpha: .65),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
