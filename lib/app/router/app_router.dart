import 'package:go_router/go_router.dart';

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
import 'package:coetus/features/matching/presentation/pages/matching_feed_page.dart';
import 'package:coetus/features/notifications/presentation/pages/notifications_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
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
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}
