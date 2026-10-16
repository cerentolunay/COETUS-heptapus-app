import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _handleStartupFlow();
  }

  Future<void> _handleStartupFlow() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      context.go('/welcome');
      return;
    }

    context.go(currentUser == null ? '/login' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: CoetusPalette.purple,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoetusMascot(size: 190, interactive: false),
              SizedBox(height: 16),
              Text(
                'coetus',
                style: TextStyle(
                  color: CoetusPalette.cream,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Birlikte öğren. Birlikte geliş.',
                style: TextStyle(color: CoetusPalette.lavender),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
