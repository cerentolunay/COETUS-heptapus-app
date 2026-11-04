import 'package:coetus/app/theme/coetus_theme.dart';
import 'package:coetus/features/social/domain/profile_identity.dart';
import 'package:coetus/features/social/presentation/find_profile_page.dart';
import 'package:coetus/features/social/presentation/profile_qr.dart';
import 'package:coetus/features/chat/domain/conversation_heart.dart';
import 'package:coetus/features/chat/domain/models/chat_message.dart';
import 'package:coetus/features/matching/presentation/pages/match_success_page.dart';
import 'package:coetus/features/profile/domain/onboarding/interest_catalog.dart';
import 'package:coetus/features/profile/presentation/widgets/interest_tree.dart';
import 'package:coetus/features/auth/presentation/pages/register_page.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:coetus/features/verification/presentation/verification_page.dart';
import 'package:coetus/features/profile/presentation/pages/skill_profile_page.dart';

Widget app(Widget child) => MaterialApp(
  theme: coetusTheme(useGoogleFonts: false),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: child,
);

void main() {
  setUp(PreviewMode.enable);
  testWidgets(
    'portfolio label stays above the picker and media choices contain only photos',
    (tester) async {
      await tester.pumpWidget(app(const VerificationPage()));
      await tester.pumpAndSettle();
      final label = find.text('İlgili yetenek');
      final picker = find.byType(DropdownButtonFormField<String>);
      expect(
        tester.getBottomLeft(label).dy,
        lessThan(tester.getTopLeft(picker).dy),
      );
      final add = find.text('Fotoğraf ekle (isteğe bağlı)');
      await tester.scrollUntilVisible(add, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.text('Galeriden fotoğraf'), findsOneWidget);
      expect(find.text('Fotoğraf çek'), findsOneWidget);
      expect(find.text('Galeriden video'), findsNothing);
      expect(find.text('Video çek'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'profile finder is a round header action beside QR, with no list entry',
    (tester) async {
      await tester.pumpWidget(app(const SkillProfilePage()));
      await tester.pumpAndSettle();
      final finder = find.byIcon(Icons.person_search_outlined);
      final qr = find.byIcon(Icons.qr_code_2);
      expect(finder, findsOneWidget);
      expect(find.text('Birbirinizi bulun'), findsNothing);
      expect(tester.getCenter(finder).dy, tester.getCenter(qr).dy);
      expect(
        (tester.getCenter(qr).dx - tester.getCenter(finder).dx).abs(),
        lessThan(60),
      );
      expect(
        find.ancestor(
          of: finder,
          matching: find.byWidgetPredicate(
            (w) => w is Material && w.shape is CircleBorder,
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'usernames normalize Turkish and case while preserving identity and rejecting reserved or invalid names',
    () {
      expect(normalizeUsername('@İPEK_Çağrı'), 'ipek_cagri');
      expect(usernameError('İPEK_Çağrı'), isNull);
      expect(usernameError('admin'), isNotNull);
      expect(usernameError('a b'), isNotNull);
      expect(usernameError('ab'), isNotNull);
      expect(suggestUsername('Çağrı Öztürk', 'abc12'), 'cagri_ozturk_abc12');
    },
  );
  test(
    'profile QR contains a stable UID and rejects external, malformed and payment payloads',
    () {
      final code = profileQrData('user-123');
      expect(parseProfileQr(code), 'user-123');
      for (final invalid in [
        'https://example.com/profile/user-123',
        'coetus://profile/a/b',
        'coetus://profile/a?amount=50',
        'coetus://profile/a%2Fb',
        'coetus://profile/a#grant',
        'coetus://user:pass@profile/a',
      ]) {
        expect(() => parseProfileQr(invalid), throwsFormatException);
      }
    },
  );
  test(
    'conversation milestones require reciprocal text messages and ignore duplicates or system messages',
    () {
      List<ChatMessage> messages(int mine, int theirs) => [
        for (var i = 0; i < mine; i++)
          ChatMessage(id: 'm$i', senderId: 'me', text: 'Merhaba'),
        for (var i = 0; i < theirs; i++)
          ChatMessage(id: 'p$i', senderId: 'partner', text: 'Selam'),
        const ChatMessage(
          id: 'system',
          senderId: 'partner',
          text: 'Oturum açıldı',
          type: ChatMessageType.system,
        ),
        const ChatMessage(id: 'blank', senderId: 'partner', text: ' '),
        const ChatMessage(id: 'm0', senderId: 'me', text: 'Yinelenen kayıt'),
      ];
      expect(ConversationHeart.fromMessages(messages(1000, 0), 'me').level, 0);
      expect(ConversationHeart.fromMessages(messages(50, 49), 'me').level, 0);
      expect(ConversationHeart.fromMessages(messages(50, 50), 'me').level, 1);
      final heart = ConversationHeart.fromMessages(messages(500, 500), 'me');
      expect(heart.level, 2);
      expect(heart.mine, 500);
      expect(heart.theirs, 500);
    },
  );
  testWidgets(
    'registration suggests a username but preserves the user choice',
    (tester) async {
      await tester.pumpWidget(app(const RegisterPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Çağrı Öztürk');
      await tester.pump();
      final username = find.byKey(const ValueKey('registration-username'));
      expect(
        tester.widget<TextFormField>(username).controller!.text,
        startsWith('cagri_ozturk_'),
      );
      await tester.ensureVisible(username);
      await tester.enterText(username, 'kitap_sever');
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'Deniz');
      expect(
        tester.widget<TextFormField>(username).controller!.text,
        'kitap_sever',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'username lookup and QR discovery open the same mutual match screen without a token gift',
    (tester) async {
      await tester.pumpWidget(app(const FindProfilePage()));
      await tester.enterText(find.byType(TextField), '@ECE');
      await tester.tap(find.text('Kullanıcı adıyla bul'));
      await tester.pumpAndSettle();
      expect(find.text('@ece'), findsOneWidget);
      await tester.tap(find.text('QR kod okut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Örnek QR okut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tanışmayı onayla'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchSuccessPage), findsOneWidget);
      expect(find.byKey(const ValueKey('first-match-gift')), findsNothing);
      expect(
        tester
            .widget<MatchSuccessPage>(find.byType(MatchSuccessPage))
            .claimGift,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('own QR uses the UID instead of mutable username', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showProfileQr(context, 'stable-id', 'old_name'),
              child: const Text('QR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('@old_name'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'expanded interest branches add personal skills and reject existing equivalents',
    (tester) async {
      final selection = InterestSelection()..toggleBranch('books');
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => InterestTree(
                  selection: selection,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ),
        ),
      );
      final add = find.byKey(const ValueKey('add-skill-books'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Deneme yazarlığı');
      await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
      await tester.pumpAndSettle();
      expect(
        selection.selectedSkills.any((s) => s.name == 'Deneme yazarlığı'),
        isTrue,
      );
      expect(
        find.widgetWithText(FilterChip, 'Deneme yazarlığı'),
        findsOneWidget,
      );
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'YARATICI YAZARLIK');
      await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
      await tester.pumpAndSettle();
      expect(find.text('Bu beceri zaten listede.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
