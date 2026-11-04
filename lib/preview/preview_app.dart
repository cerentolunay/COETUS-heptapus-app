import '../features/social/presentation/find_profile_page.dart';
import '../features/social/presentation/profile_qr.dart';
import '../features/premium/presentation/pages/premium_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import '../app/theme/coetus_theme.dart';
import '../app/theme/coetus_tokens.dart';
import '../features/auth/presentation/pages/auth_profile_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/widgets/delete_account_button.dart';
import '../features/chat/presentation/pages/chat_interface_page.dart';
import '../features/chat/presentation/pages/chat_list_page.dart';
import '../features/community/community.dart';
import '../features/exchange/presentation/pages/exchange_page.dart';
import '../features/matching/presentation/pages/match_success_page.dart';
import '../features/matching/presentation/pages/matching_feed_page.dart';
import '../features/matching/presentation/pages/skill_detail_page.dart';
import '../features/matching/services/matching_service.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/pages/discovery_test_page.dart';
import '../features/onboarding/presentation/pages/onboarding_intro_page.dart';
import '../features/onboarding/presentation/pages/splash_page.dart';
import '../features/onboarding/presentation/pages/welcome_page.dart';
import '../features/profile/presentation/pages/complete_profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/other_user_profile_page.dart';
import '../features/profile/presentation/pages/skill_profile_page.dart';
import '../features/verification/domain/skill_verification.dart';
import '../features/verification/presentation/verification_page.dart';
import '../widgets/coetus_mascot.dart';
import 'preview_mode.dart';
import 'preview_repositories.dart';

const previewScreens = <({String group, String name, String path})>[
  (
    group: 'İletişim',
    name: 'Kullanıcı adı ve QR ile bul',
    path: '/find-profile',
  ),
  (group: 'İletişim', name: 'Profil QR kodu okut', path: '/scan-profile'),
  (group: 'Profil', name: 'Premium ve token paketleri', path: '/premium'),
  (group: 'Başlangıç', name: 'Açılış', path: '/splash'),
  (group: 'Başlangıç', name: 'Karşılama', path: '/welcome'),
  (group: 'Başlangıç', name: 'Tanıtım', path: '/onboarding'),
  (group: 'Başlangıç', name: 'Giriş yap', path: '/login'),
  (group: 'Başlangıç', name: 'Kayıt ol', path: '/register'),
  (group: 'Başlangıç', name: 'Şifremi unuttum', path: '/forgot-password'),
  (group: 'Başlangıç', name: 'İlgi alanlarını keşfet', path: '/discovery'),
  (
    group: 'Başlangıç',
    name: 'Profili tamamla ve beceri ağacı',
    path: '/complete-profile',
  ),
  (group: 'Keşfet', name: 'Eşleşmeler ve topluluk akışı', path: '/matching'),
  (group: 'Keşfet', name: 'Yetenek detayı', path: '/skill-detail'),
  (group: 'Keşfet', name: 'Kişinin profili', path: '/other-profile'),
  (group: 'Keşfet', name: 'Eşleşme kutlaması', path: '/match-success'),
  (
    group: 'Topluluk',
    name: 'Paylaşım detayı',
    path: '/community-post/preview-post',
  ),
  (group: 'Topluluk', name: 'Paylaşım oluştur', path: '/compose'),
  (group: 'Topluluk', name: 'Yorumlar', path: '/comments'),
  (group: 'Topluluk', name: 'Token desteği', path: '/support'),
  (group: 'İletişim', name: 'Mesajlar', path: '/chat'),
  (group: 'İletişim', name: 'Sohbet', path: '/chat-detail/preview-chat'),
  (group: 'İletişim', name: 'Bildirimler', path: '/notifications'),
  (group: 'Oturumlar', name: 'Aktif, bekleyen ve geçmiş', path: '/exchange'),
  (
    group: 'Oturumlar',
    name: 'Oturum detayı',
    path: '/exchange-detail/preview-session',
  ),
  (group: 'Profil', name: 'Profilim ve beceriler', path: '/profile'),
  (group: 'Profil', name: 'Profili düzenle', path: '/profile/edit'),
  (group: 'Profil', name: 'Hesap profili', path: '/account'),
  (group: 'Profil', name: 'Çalışmalarım', path: '/verification'),
  (group: 'Profil', name: 'Çalışma detayı', path: '/work-detail'),
  (group: 'Profil', name: 'Hesap silme onayı', path: '/delete-account'),
];

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key, this.initialLocation = '/'});
  final String initialLocation;
  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    if (!kDebugMode || !PreviewMode.enabled) {
      throw UnsupportedError(
        'Önizleme ayrı debug giriş noktasından açılmalıdır.',
      );
    }
    _router = GoRouter(
      initialLocation: widget.initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => Column(
            children: [
              Material(
                color: CoetusPalette.purple,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ÖNİZLEME · ÇEVRİMDIŞI',
                            style: TextStyle(
                              color: CoetusPalette.lime,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.grid_view, size: 18),
                          label: const Text('Ekranlar'),
                          style: TextButton.styleFrom(
                            foregroundColor: CoetusPalette.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
          routes: [
            GoRoute(path: '/', builder: (_, state) => const _Gallery()),
            for (final screen in previewScreens)
              GoRoute(
                path: screen.path,
                builder: (context, state) => _page(screen.path, context),
              ),
            GoRoute(
              path: '/home',
              builder: (_, state) => const MatchingFeedPage(),
            ),
            GoRoute(
              path: '/profile-advanced',
              builder: (_, state) => const VerificationPage(),
            ),
            GoRoute(
              path: '/chat-detail',
              builder: (_, state) =>
                  const ChatInterfacePage(chatId: 'preview-chat'),
            ),
            GoRoute(
              path: '/chat-escrow',
              builder: (_, state) =>
                  const ExchangePage(sessionId: 'preview-session'),
            ),
            GoRoute(
              path: '/exchange-history',
              builder: (_, state) => const ExchangePage(),
            ),
            GoRoute(
              path: '/exchange-detail',
              builder: (_, state) =>
                  const ExchangePage(sessionId: 'preview-session'),
            ),
            GoRoute(
              path: '/exchange-detail/:sessionId',
              builder: (_, state) =>
                  ExchangePage(sessionId: state.pathParameters['sessionId']),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Coetus · Ekranları incele',
    theme: coetusTheme(useGoogleFonts: false),
    locale: const Locale('tr', 'TR'),
    supportedLocales: const [Locale('tr', 'TR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: _router,
  );

  Widget _page(String path, BuildContext context) => switch (path) {
    '/find-profile' => const FindProfilePage(),
    '/scan-profile' => const ScanProfileQrPage(),
    '/splash' => const SplashPage(),
    '/welcome' => const WelcomePage(),
    '/onboarding' => const OnboardingIntroPage(),
    '/login' => const LoginPage(),
    '/register' => const RegisterPage(),
    '/forgot-password' => const ForgotPasswordPage(),
    '/premium' => const PremiumPage(),
    '/discovery' => const DiscoveryTestPage(),
    '/complete-profile' => CompleteProfilePage(
      initialName: '',
      onSubmit: (_) async {},
      locateCity: () async => 'İstanbul, Türkiye',
      onCompleted: () => context.go('/home'),
    ),
    '/matching' => const MatchingFeedPage(),
    '/skill-detail' => SkillDetailPage(
      candidate: const MatchingService()
          .getRecommendedMatches(
            currentProfile: PreviewProfileRepository.initialProfile,
            candidateProfiles: PreviewProfileRepository.candidates,
          )
          .first,
      onSendOffer: () => context.go('/match-success'),
      onViewProfile: () => context.go('/other-profile'),
    ),
    '/other-profile' => const OtherUserProfilePage(
      profile: OtherUserProfileData(
        id: 'preview-partner',
        name: 'Ece',
        location: 'İstanbul, Türkiye',
        bio: 'Müziği birlikte keşfedelim.',
        trustScore: 94,
        verified: false,
        matchScore: 94,
        creditsRequired: 10,
        teachSkills: [
          OtherUserSkillData(name: 'Gitar', category: 'Müzik', level: 5),
        ],
        learnSkills: [OtherUserSkillData(name: 'Python', category: 'Yazılım')],
      ),
    ),
    '/match-success' => const MatchSuccessPage(
      user: MatchedUser(
        name: 'Ece',
        skills: [MatchedSkill(name: 'Gitar', emoji: '🎸')],
        learningGoals: [MatchedGoal(name: 'Python', emoji: '💻')],
      ),
    ),
    '/community-post/preview-post' => const CommunityPostPage(
      postId: 'preview-post',
    ),
    '/compose' => const CommunityComposer(),
    '/comments' => const Scaffold(
      body: CommunityComments(postId: 'preview-post'),
    ),
    '/support' => const Scaffold(
      body: Center(child: CommunitySupport(postId: 'preview-post')),
    ),
    '/chat' => const ChatListPage(),
    '/chat-detail/preview-chat' => const ChatInterfacePage(
      chatId: 'preview-chat',
    ),
    '/notifications' => const NotificationsPage(),
    '/exchange' => const ExchangePage(),
    '/exchange-detail/preview-session' => const ExchangePage(
      sessionId: 'preview-session',
    ),
    '/profile' => const SkillProfilePage(),
    '/profile/edit' => const EditProfilePage(),
    '/account' => const AuthProfilePage(),
    '/verification' => const VerificationPage(),
    '/work-detail' => const EvidenceDetailsPage(
      verification: SkillVerification(
        id: 'preview-work',
        ownerId: PreviewMode.userId,
        skillName: 'Gitar',
        status: 'published',
        type: 'portfolio',
        description: 'Akor geçişleri üzerine haftalık çalışmam.',
        files: [
          {'path': 'preview-media', 'contentType': 'image/jpeg'},
        ],
      ),
    ),
    '/delete-account' => Scaffold(
      body: Center(
        child: DeleteAccountDialog(
          requiresPassword: true,
          onDelete: (_) async =>
              throw StateError('Önizleme: gerçek hesap silinmez.'),
        ),
      ),
    ),
    _ => const Scaffold(body: Center(child: Text('Ekran bulunamadı.'))),
  };
}

class _Gallery extends StatefulWidget {
  const _Gallery();
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final screens = previewScreens
        .where(
          (s) => '${s.name} ${s.group}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(child: CoetusMascot(size: 100)),
            const Text(
              'Ekranları incele',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Örnek kişiler ve içerikler. Gösterilen token bakiyesi örnektir; gerçek bakiyen değildir. Firebase bağlantısı, gerçek ödeme veya hesap silme yapılmaz. Değişiklikler uygulama kapanınca sıfırlanır.',
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Ekran ara…',
              ),
            ),
            const SizedBox(height: 12),
            for (final group in screens.map((s) => s.group).toSet()) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  group,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final screen in screens.where((s) => s.group == group))
                Card(
                  child: ListTile(
                    title: Text(screen.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(screen.path),
                  ),
                ),
            ],
            if (screens.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Bu aramayla eşleşen ekran yok.'),
              ),
          ],
        ),
      ),
    );
  }
}
