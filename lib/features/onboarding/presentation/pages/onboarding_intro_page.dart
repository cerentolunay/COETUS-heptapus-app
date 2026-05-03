import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingIntroPage extends StatefulWidget {
  const OnboardingIntroPage({super.key});

  @override
  State<OnboardingIntroPage> createState() => _OnboardingIntroPageState();
}

class _OnboardingIntroPageState extends State<OnboardingIntroPage>
    with SingleTickerProviderStateMixin {
  static const Color _bgStart = Color(0xFF0B1120);
  static const Color _bgMiddle = Color(0xFF0F172A);
  static const Color _bgEnd = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      id: 1,
      badge: '01',
      title: 'Build Your Skill Identity',
      description:
          'Create your profile, list the skills you can teach, and show people what kind of learning exchange you offer.',
    ),
    _OnboardingSlide(
      id: 2,
      badge: '02',
      title: 'Match and Learn Together',
      description:
          'Discover people with complementary goals, connect around shared interests, and turn skill exchange into real progress.',
    ),
    _OnboardingSlide(
      id: 3,
      badge: '03',
      title: 'Earn Credits, Unlock Growth',
      description:
          'Teach what you know, earn credits from the community, and spend them to learn the next skill on your roadmap.',
    ),
  ];

  int _currentSlide = 0;
  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
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

  void _handleNext() {
    if (_currentSlide < _slides.length - 1) {
      setState(() {
        _currentSlide++;
      });
      return;
    }

    _completeOnboarding('/register');
  }

  void _handleSkip() {
    _completeOnboarding('/register');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentSlide];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgStart, _bgMiddle, _bgEnd],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, _) {
                return Opacity(
                  opacity: 0.05,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) {
                      final angle =
                          math.sin(
                            (_backgroundController.value * 2 * math.pi) + i,
                          ) *
                          0.16;
                      return Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: 3,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [_cyan, _purple],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleSkip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.60),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0.10, 0),
                            end: Offset.zero,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: _SlideContent(
                          key: ValueKey(slide.id),
                          slide: slide,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ProgressIndicators(
                      slideCount: _slides.length,
                      currentSlide: _currentSlide,
                    ),
                    const SizedBox(height: 24),
                    _GradientButton(
                      text: _currentSlide == _slides.length - 1
                          ? 'Create Account'
                          : 'Continue',
                      icon: _currentSlide == _slides.length - 1
                          ? Icons.person_add_alt_1
                          : Icons.arrow_forward,
                      onTap: _handleNext,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => _completeOnboarding('/login'),
                      child: Text(
                        'I already have an account',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideContent({super.key, required this.slide});

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 136,
          height: 136,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_purple, _cyan],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(124, 58, 237, 0.30),
                blurRadius: 26,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              slide.badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 17,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _ProgressIndicators extends StatelessWidget {
  final int slideCount;
  final int currentSlide;

  const _ProgressIndicators({
    required this.slideCount,
    required this.currentSlide,
  });

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(slideCount, (index) {
        final isActive = index == currentSlide;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isActive
                ? const LinearGradient(colors: [_purple, _cyan])
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.20),
          ),
        );
      }),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_purple, _cyan]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(124, 58, 237, 0.30),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final int id;
  final String badge;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.id,
    required this.badge,
    required this.title,
    required this.description,
  });
}
