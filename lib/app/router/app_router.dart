import 'dart:async';

import 'package:coetus/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:coetus/features/auth/presentation/pages/login_page.dart';
import 'package:coetus/features/auth/presentation/pages/auth_profile_page.dart';
import 'package:coetus/features/auth/presentation/pages/register_page.dart';
import 'package:coetus/features/chat/presentation/pages/chat_list_page.dart';
import 'package:coetus/features/matching/presentation/pages/match_success_page.dart';
import 'package:coetus/features/matching/presentation/pages/matching_feed_page.dart';
import 'package:coetus/features/matching/presentation/pages/skill_discovery_page.dart';
import 'package:coetus/features/notifications/presentation/pages/notifications_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/discovery_test_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/onboarding_intro_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/splash_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:coetus/features/profile/presentation/pages/advanced_skill_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRouter {
  static const String _onboardingSeenKey = 'has_seen_onboarding';

  static final List<String> _guestOnlyRoutes = <String>[
    '/login',
    '/register',
    '/forgot-password',
  ];

  static final List<String> _onboardingRoutes = <String>['/onboarding'];

  static final List<String> _protectedRoutes = <String>[
    '/home',
    '/profile',
    '/profile-advanced',
    '/matching',
    '/matching-feed',
    '/match-success',
    '/chat',
    '/notifications',
  ];

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool(_onboardingSeenKey) ?? false;
      final currentUser = FirebaseAuth.instance.currentUser;
      final location = state.uri.path;
      final isGuestRoute = _guestOnlyRoutes.contains(location);
      final isOnboardingRoute = _onboardingRoutes.contains(location);
      final isProtectedRoute = _protectedRoutes.contains(location);

      if (!hasSeenOnboarding && !isOnboardingRoute) {
        return '/onboarding';
      }

      if (hasSeenOnboarding && isOnboardingRoute) {
        return currentUser == null ? '/login' : '/home';
      }

      if (currentUser != null && isGuestRoute) {
        return '/home';
      }

      if (currentUser == null && isProtectedRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingIntroPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/discovery',
        builder: (context, state) => const DiscoveryTestPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SkillDiscoveryPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const AuthProfilePage(),
      ),
      GoRoute(
        path: '/profile-advanced',
        builder: (context, state) => const AdvancedSkillProfilePage(),
      ),
      GoRoute(
        path: '/matching',
        builder: (context, state) => const SkillDiscoveryPage(),
      ),
      GoRoute(
        path: '/matching-feed',
        builder: (context, state) => const MatchingFeedPage(),
      ),
      GoRoute(
        path: '/match-success',
        builder: (context, state) => const MatchSuccessPage(
          user: MatchedUser(
            name: 'Zeynep Karaca',
            skills: [
              MatchedSkill(name: 'UI Tasarimi', emoji: 'UI'),
              MatchedSkill(name: 'Figma', emoji: 'FG'),
            ],
            learningGoals: [
              MatchedGoal(name: 'Flutter', emoji: 'FL'),
              MatchedGoal(name: 'Sunum', emoji: 'SP'),
            ],
          ),
        ),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatListPage()),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
