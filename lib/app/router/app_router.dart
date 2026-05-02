import 'package:go_router/go_router.dart';

import 'auth_route_guard.dart';

// Auth
import 'package:coetus/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:coetus/features/auth/presentation/pages/login_page.dart';
import 'package:coetus/features/auth/presentation/pages/register_page.dart';

// Onboarding
import 'package:coetus/features/onboarding/presentation/pages/discovery_test_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/onboarding_intro_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/splash_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/welcome_page.dart';

// Profile
import 'package:coetus/features/profile/presentation/pages/advanced_skill_profile_page.dart';
import 'package:coetus/features/profile/presentation/pages/skill_profile_page.dart';

// Matching & Notifications (Klasör yapına göre ekledim, eğer dosya isimleri farklıysa kontrol et)
import 'package:coetus/features/chat/presentation/pages/chat_list_page.dart';
import 'package:coetus/features/chat/presentation/pages/secure_chat_escrow_page.dart';
import 'package:coetus/features/exchange/presentation/pages/exchange_page.dart';
import 'package:coetus/features/matching/presentation/pages/matching_feed_page.dart';
import 'package:coetus/features/notifications/presentation/pages/notifications_page.dart';

class AppRouter {
  static final AuthRouteGuard _authGuard = AuthRouteGuard();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _authGuard,
    redirect: (context, state) async {
      if (!_authGuard.isEnabled) {
        return null;
      }

      final path = state.uri.path;
      final isSignedIn = _authGuard.isSignedIn;
      final isPublicRoute = _publicRoutes.contains(path);
      final isAuthEntryRoute = _authEntryRoutes.contains(path);

      if (!isSignedIn) {
        if (_protectedRoutes.contains(path)) {
          return '/login';
        }

        return null;
      }

      final profileCompleted = await _authGuard.isProfileCompleted();
      if (!profileCompleted && _requiresCompletedProfile(path)) {
        return '/profile';
      }

      if (isPublicRoute && isAuthEntryRoute) {
        return profileCompleted ? '/home' : '/profile';
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
      // --- REGISTER SONRASI HATAYI ÇÖZEN KISIM ---
      // RegisterPage içinde context.go('/home') dediğin için burayı ekliyoruz.
      // Şimdilik seni MatchingFeedPage'e veya Profile'a atsın:
      GoRoute(
        path: '/home',
        builder: (context, state) => const SkillProfilePage(),
      ),
      // -------------------------------------------
      GoRoute(
        path: '/profile',
        builder: (context, state) => const SkillProfilePage(),
      ),
      GoRoute(
        path: '/profile-advanced',
        builder: (context, state) => const AdvancedSkillProfilePage(),
      ),
      GoRoute(
        path: '/matching',
        builder: (context, state) => const MatchingFeedPage(),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatListPage()),
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) => const SecureChatEscrowPage(),
      ),
      GoRoute(
        path: '/chat-escrow',
        builder: (context, state) => const SecureChatEscrowPage(),
      ),
      GoRoute(
        path: '/exchange',
        builder: (context, state) => const ExchangePage(),
      ),
      GoRoute(
        path: '/exchange-history',
        builder: (context, state) => const ExchangePage(),
      ),
      GoRoute(
        path: '/exchange-detail',
        builder: (context, state) => const ExchangePage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );

  static const Set<String> _publicRoutes = {
    '/',
    '/welcome',
    '/onboarding',
    '/discovery',
    '/login',
    '/register',
    '/forgot-password',
  };

  static const Set<String> _authEntryRoutes = {
    '/',
    '/welcome',
    '/onboarding',
    '/discovery',
    '/login',
    '/register',
    '/forgot-password',
  };

  static const Set<String> _protectedRoutes = {
    '/home',
    '/profile',
    '/profile-advanced',
    '/matching',
    '/chat',
    '/chat-detail',
    '/chat-escrow',
    '/exchange',
    '/exchange-history',
    '/exchange-detail',
    '/notifications',
  };

  static bool _requiresCompletedProfile(String path) {
    return _protectedRoutes.contains(path) && path != '/profile';
  }
}
