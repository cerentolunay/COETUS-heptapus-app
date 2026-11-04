import 'dart:async';
import '../features/chat/data/repositories/local_chat_repository.dart';
import '../features/chat/domain/models/chat_message.dart';
import '../features/chat/domain/models/chat_thread.dart';
import '../features/exchange/data/repositories/local_exchange_repository.dart';
import '../features/exchange/domain/models/exchange_session.dart';
import '../features/exchange/domain/models/match_offer.dart';
import '../features/notifications/data/repositories/local_notification_repository.dart';
import '../features/notifications/domain/models/app_notification.dart';
import 'preview_mode.dart';
import '../features/auth/domain/models/app_user.dart';
import '../features/profile/domain/models/profile_data.dart';
import '../features/profile/domain/models/skill_model.dart';
import '../features/profile/domain/repositories/profile_repository.dart';

class PreviewProfileRepository implements ProfileRepository {
  static const guitar = SkillModel(
    id: 'gitar',
    name: 'Gitar',
    level: 5,
    category: 'Müzik',
    teachable: true,
  );
  static const python = SkillModel(
    id: 'python',
    name: 'Python',
    level: 4,
    category: 'Yazılım',
    teachable: true,
  );
  static const initialProfile = ProfileData(
    user: AppUser(
      id: PreviewMode.userId,
      name: 'Deniz',
      username: 'deniz',
      email: 'deniz@example.invalid',
      bio: 'Birlikte öğrenmeyi ve üretmeyi seviyorum.',
      credits: 200,
      trustScore: 82,
      profileCompleted: true,
      location: 'İstanbul, Türkiye',
    ),
    teachSkills: [python],
    learnSkills: [
      SkillModel(id: 'gitar', name: 'Gitar', level: 1, learnable: true),
    ],
    availabilitySlots: ['Pazartesi akşam'],
  );
  static ProfileData profile = initialProfile;
  static final candidates = [
    for (final person in [
      ('preview-partner', 'Ece', 94),
      ('preview-partner-2', 'Can', 87),
      ('preview-partner-3', 'İpek', 91),
    ])
      ProfileData(
        user: AppUser(
          id: person.$1,
          name: person.$2,
          username: {'Ece': 'ece', 'Can': 'can', 'İpek': 'ipek'}[person.$2]!,
          email: '',
          bio:
              'Müziği birlikte keşfedelim. Akorlar ve ritim üzerine çalışabiliriz.',
          trustScore: person.$3,
          location: 'İstanbul, Türkiye',
        ),
        teachSkills: const [guitar],
        learnSkills: const [
          SkillModel(id: 'python', name: 'Python', level: 1, learnable: true),
        ],
        availabilitySlots: const ['Pazartesi akşam'],
      ),
  ];
  @override
  Future<ProfileData> loadProfile() async => profile;
  @override
  Future<List<ProfileData>> loadDiscoverableProfiles({int limit = 50}) async =>
      candidates.take(limit).toList();
  @override
  Future<ProfileData> updateProfile(AppUser user) async =>
      profile = profile.copyWith(user: user);
  @override
  Future<ProfileData> saveTeachSkill(SkillModel skill) async =>
      profile = profile.copyWith(
        teachSkills: [
          ...profile.teachSkills.where((s) => s.id != skill.id),
          skill,
        ],
      );
  @override
  Future<ProfileData> saveLearnSkill(SkillModel skill) async =>
      profile = profile.copyWith(
        learnSkills: [
          ...profile.learnSkills.where((s) => s.id != skill.id),
          skill,
        ],
      );
  @override
  Future<ProfileData> deleteTeachSkill(String skillId) async =>
      profile = profile.copyWith(
        teachSkills: profile.teachSkills.where((s) => s.id != skillId).toList(),
      );
  @override
  Future<ProfileData> deleteLearnSkill(String skillId) async =>
      profile = profile.copyWith(
        learnSkills: profile.learnSkills.where((s) => s.id != skillId).toList(),
      );
}

// Memory only. No Firebase, network images, preferences or disk persistence.
class PreviewChatRepository extends LocalChatRepository {
  static final messages = ValueNotifierMessages();
  static final thread = ChatThread(
    id: 'preview-chat',
    sessionId: 'preview-session',
    matchId: 'preview-offer',
    participants: const [PreviewMode.userId, 'preview-partner'],
    participantNames: const {
      PreviewMode.userId: 'Deniz',
      'preview-partner': 'Ece',
    },
    skillName: 'Gitar',
    lastMessage: 'Yarın akorlarla başlayalım mı?',
    lastSenderId: 'preview-partner',
    credits: 10,
    lastMessageAt: DateTime.now(),
  );
  @override
  Stream<List<ChatThread>> streamUserChats(String userId) =>
      Stream.value([thread]);
  @override
  Stream<List<ChatMessage>> streamMessages(String chatId) async* {
    yield List.of(messages.items);
    yield* messages.changes.stream;
  }

  @override
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    messages.items.add(
      ChatMessage(
        id: 'message-${messages.items.length}',
        senderId: senderId,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    messages.changes.add(List.of(messages.items));
  }
}

class ValueNotifierMessages {
  final changes = StreamController<List<ChatMessage>>.broadcast();
  final items = <ChatMessage>[
    ChatMessage(
      id: 'a',
      senderId: 'preview-partner',
      text: 'Merhaba! Birlikte gitar çalışmaya ne dersin?',
      createdAt: DateTime.now(),
    ),
    ChatMessage(
      id: 'b',
      senderId: PreviewMode.userId,
      text: 'Harika olur, akor geçişlerini öğrenmek istiyorum.',
      createdAt: DateTime.now(),
    ),
    ChatMessage(
      id: 'c',
      senderId: 'preview-partner',
      text: 'Yarın akorlarla başlayalım mı?',
      createdAt: DateTime.now(),
    ),
  ];
}

class PreviewExchangeRepository extends LocalExchangeRepository {
  @override
  Stream<List<MatchOffer>> streamUserOffers(String userId) => Stream.value([
    MatchOffer(
      id: 'preview-offer',
      requesterId: 'preview-partner',
      receiverId: PreviewMode.userId,
      requesterName: 'Ece',
      receiverName: 'Deniz',
      participants: const [PreviewMode.userId, 'preview-partner'],
      skill: 'Gitar',
      credits: 10,
      createdAt: DateTime.now(),
    ),
  ]);
  @override
  Stream<List<ExchangeSession>> streamUserSessions(String userId) =>
      Stream.value([
        for (final status in [
          ExchangeSessionStatus.active,
          ExchangeSessionStatus.completed,
        ])
          ExchangeSession(
            id: status == ExchangeSessionStatus.active
                ? 'preview-session'
                : 'preview-completed',
            matchId: 'preview-offer',
            teacherId: 'preview-partner',
            studentId: PreviewMode.userId,
            participants: const [PreviewMode.userId, 'preview-partner'],
            skill: 'Gitar',
            credits: 10,
            funded: true,
            status: status,
            createdAt: DateTime.now(),
          ),
      ]);
}

class PreviewNotificationRepository extends LocalNotificationRepository {
  @override
  Stream<List<AppNotification>> streamUserNotifications(String userId) =>
      Stream.value([
        for (final entry in [
          (
            AppNotificationType.newMessage,
            'Ece sana mesaj gönderdi',
            'Yarın akorlarla başlayalım mı?',
            '/chat-detail',
            'preview-chat',
          ),
          (
            AppNotificationType.offerReceived,
            'Yeni öğrenme teklifi',
            'Ece seninle gitar çalışmak istiyor.',
            '/exchange',
            'preview-offer',
          ),
          (
            AppNotificationType.communityActivity,
            'Paylaşımına kalp geldi',
            'Ürettiklerin topluluğa ilham veriyor.',
            '/community-post',
            'preview-post',
          ),
          (
            AppNotificationType.learningCompleted,
            'Birlikte öğrendiniz',
            'Örnek oturum tamamlandı.',
            '/exchange',
            'preview-completed',
          ),
        ].indexed)
          AppNotification(
            id: 'notification-${entry.$1}',
            userId: PreviewMode.userId,
            senderId: 'preview-partner',
            type: entry.$2.$1,
            title: entry.$2.$2,
            message: entry.$2.$3,
            targetRoute: entry.$2.$4,
            targetId: entry.$2.$5,
            createdAt: DateTime.now(),
          ),
      ]);
}
