import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

// Auth
import 'package:coetus/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:coetus/features/auth/presentation/pages/login_page.dart';
import 'package:coetus/features/auth/presentation/pages/register_page.dart';
import 'package:coetus/features/auth/presentation/notifiers/auth_state_notifier.dart';

// Profile
import 'package:coetus/features/profile/presentation/notifiers/profile_completion_notifier.dart';
import 'package:coetus/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:coetus/features/profile/presentation/pages/advanced_skill_profile_page.dart';
import 'package:coetus/features/profile/presentation/pages/complete_profile_page.dart';
import 'package:coetus/features/profile/presentation/pages/skill_profile_page.dart';

// Onboarding
import 'package:coetus/features/onboarding/presentation/pages/discovery_test_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/onboarding_intro_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/splash_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/welcome_page.dart';

// Matching & Notifications
import 'package:coetus/features/chat/presentation/pages/chat_interface_page.dart';
import 'package:coetus/features/chat/presentation/pages/chat_list_page.dart';
import 'package:coetus/features/chat/presentation/pages/secure_chat_escrow_page.dart';
import 'package:coetus/features/exchange/presentation/pages/exchange_page.dart';
import 'package:coetus/features/matching/presentation/pages/matching_feed_page.dart';
import 'package:coetus/features/matching/presentation/pages/match_success_page.dart';
import 'package:coetus/features/notifications/presentation/pages/notifications_page.dart';

/// Global notifiers for router
final _authStateNotifier = AuthStateNotifier();
final _profileCompletionNotifier = ProfileCompletionNotifier();

/// Custom Listenable combining both auth and profile notifiers
class _CombinedNotifier extends Listenable {
  final AuthStateNotifier authNotifier;
  final ProfileCompletionNotifier profileNotifier;

  _CombinedNotifier({
    required this.authNotifier,
    required this.profileNotifier,
  });

  @override
  void addListener(VoidCallback listener) {
    authNotifier.addListener(listener);
    profileNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    authNotifier.removeListener(listener);
    profileNotifier.removeListener(listener);
  }
}

final _combinedNotifier = _CombinedNotifier(
  authNotifier: _authStateNotifier,
  profileNotifier: _profileCompletionNotifier,
);

class AppRouter {
  /// Public routes - authentication gerekmiyor
  static const List<String> publicRoutes = [
    '/',
    '/welcome',
    '/onboarding',
    '/login',
    '/register',
    '/forgot-password',
    '/discovery',
  ];

  /// Protected routes - authentication gerekli
  static const List<String> protectedRoutes = [
    '/home',
    '/profile',
    '/profile-advanced',
    '/matching',
    '/chat',
    '/chat/',
    '/chat-detail',
    '/chat-escrow',
    '/exchange',
    '/exchange-history',
    '/exchange-detail',
    '/notifications',
  ];

  /// Profile completion route - sadece incomplete profilliler erişebilir
  static const String profileCompletionRoute = '/complete-profile';

  static bool _isProtectedRoute(String path) {
    return protectedRoutes.any((route) => path.startsWith(route));
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/matching',
    debugLogDiagnostics: true,

    /// Hem auth hem profile notifier'larını dinle
    refreshListenable: _combinedNotifier,

    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isSignedIn = user != null;
      final isGoingToProtectedRoute = _isProtectedRoute(state.uri.path);
      final isGoingToProfileCompletion =
          state.uri.path == profileCompletionRoute;

      // 1. UNAUTHENTICATED + PROTECTED ROUTE → LOGIN
      if (!isSignedIn && isGoingToProtectedRoute) {
        return '/login';
      }

      // 2. UNAUTHENTICATED + PROFILE COMPLETION → LOGIN
      if (!isSignedIn && isGoingToProfileCompletion) {
        return '/login';
      }

      // 3. AUTHENTICATED + INCOMPLETE PROFILE + PROTECTED ROUTE → COMPLETE PROFILE
      // Profile loading middle while checking...
      if (isSignedIn &&
          isGoingToProtectedRoute &&
          !_profileCompletionNotifier.isLoading &&
          !_profileCompletionNotifier.isProfileCompleted) {
        return profileCompletionRoute;
      }

      // 4. AUTHENTICATED + INCOMPLETE PROFILE + HOME SPECIFICALLY → COMPLETE PROFILE
      if (isSignedIn &&
          state.uri.path == '/home' &&
          !_profileCompletionNotifier.isLoading &&
          !_profileCompletionNotifier.isProfileCompleted) {
        return profileCompletionRoute;
      }

      // 5. AUTHENTICATED + INCOMPLETE PROFILE + PUBLIC AUTH ROUTES → ALLOW
      // (Let them stay on login/register/splash if incomplete, they'll be forced to complete
      // when trying to access protected routes)

      // 6. AUTHENTICATED + COMPLETE PROFILE + PROFILE COMPLETION → HOME
      if (isSignedIn &&
          isGoingToProfileCompletion &&
          !_profileCompletionNotifier.isLoading &&
          _profileCompletionNotifier.isProfileCompleted) {
        return '/home';
      }

      // 7. AUTHENTICATED + PUBLIC AUTH ROUTES → HOME or COMPLETE PROFILE
      if (isSignedIn &&
          (state.uri.path == '/' ||
              state.uri.path == '/welcome' ||
              state.uri.path == '/login' ||
              state.uri.path == '/register' ||
              state.uri.path == '/forgot-password')) {
        // If profile not completed yet and not loading, go to complete-profile
        if (!_profileCompletionNotifier.isLoading &&
            !_profileCompletionNotifier.isProfileCompleted) {
          return profileCompletionRoute;
        }
        return '/home';
      }

      // 8. Yönlendirme yok
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
      // Profile completion route
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      // --- REGISTER SONRASI HATAYI ÇÖZEN KISIM ---
      // RegisterPage içinde context.go('/home') dediğin için burayı ekliyoruz.
      // Şimdilik seni MatchingFeedPage'e veya Profile'a atsın:
      GoRoute(
        path: '/home',
        builder: (context, state) => const MatchingFeedPage(),
      ),
      // -------------------------------------------
      GoRoute(
        path: '/profile',
        builder: (context, state) => const SkillProfilePage(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfilePage(),
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
        path: '/chat-detail/:chatId',
        builder: (context, state) =>
            ChatInterfacePage(chatId: state.pathParameters['chatId']),
      ),
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) => const ChatInterfacePage(),
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
        path: '/exchange-detail/:sessionId',
        builder: (context, state) =>
            ExchangePage(sessionId: state.pathParameters['sessionId']),
      ),
      GoRoute(
        path: '/exchange-detail',
        builder: (context, state) => const ExchangePage(),
      ),
      GoRoute(
        path: '/match-success',
        builder: (context, state) {
          final user = state.extra as MatchedUser?;

          if (user == null) {
            return const MatchingFeedPage();
          }

          return MatchSuccessPage(user: user);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}
