import 'package:coetus/preview/preview_mode.dart';
import 'package:coetus/core/text/skill_normalization.dart';
import 'package:coetus/features/community/community.dart';
import 'package:coetus/features/auth/domain/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/match_discovery_widgets.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/matching/models/match_candidate.dart';
import 'package:coetus/features/matching/models/match_explanation.dart';
import 'package:coetus/features/matching/presentation/pages/skill_detail_page.dart';
import 'package:coetus/features/matching/services/matching_service.dart';
import 'package:coetus/features/profile/data/repositories/profile_repository_factory.dart';
import 'package:coetus/features/profile/domain/models/profile_data.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import 'package:coetus/features/profile/domain/repositories/profile_repository.dart';
import 'package:coetus/features/profile/presentation/pages/other_user_profile_page.dart';
import 'package:coetus/widgets/coetus_bottom_nav.dart';
import 'package:coetus/widgets/coetus_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Keşfet / eşleşme akışı — gerçek eşleşme algoritmasının sonuçlarını
/// 2 sütunlu bir kart gridinde tarar. Kart açıldığında [SkillDetailPage]
/// üzerinden takas teklifi gönderilir.
class MatchingFeedPage extends StatefulWidget {
  const MatchingFeedPage({
    super.key,
    this.authorId,
    this.skillId,
    this.learn = false,
  });
  final String? authorId, skillId;
  final bool learn;

  @override
  State<MatchingFeedPage> createState() => _MatchingFeedPageState();
}

class _MatchingFeedPageState extends State<MatchingFeedPage> {
  final TextEditingController _searchController = TextEditingController();
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final ProfileRepository _profileRepository =
      ProfileRepositoryFactory.create();

  List<MatchCandidate> _candidates = [];
  List<String> _skillFilters = [];
  ProfileData? _currentProfile;
  bool _isLoading = true;
  String? _selectedSkill;
  String? _errorMessage;
  _MatchSortOption _sortOption = _MatchSortOption.bestMatch;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadMatches().then((_) {
      if (mounted && widget.authorId != null && widget.skillId != null) {
        _openCommunityAuthor(
          widget.authorId!,
          widget.skillId!,
          learn: widget.learn,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MatchCandidate> get _visibleCandidates {
    final query = normalizeText(_searchController.text);

    final filtered = _candidates.where((candidate) {
      final location = candidate.user.location ?? '';
      final matchesSearch =
          query.isEmpty ||
          normalizeText(candidate.user.name).contains(query) ||
          normalizeText(location).contains(query) ||
          normalizeText(candidate.user.bio).contains(query) ||
          normalizeText(candidate.teacherSkill.name).contains(query) ||
          normalizeText(candidate.studentSkill.name).contains(query);

      final matchesSkill =
          _selectedSkill == null ||
          skillKey(candidate.teacherSkill.name) == skillKey(_selectedSkill!) ||
          skillKey(candidate.studentSkill.name) == skillKey(_selectedSkill!);

      return matchesSearch && matchesSkill;
    }).toList();

    filtered.sort((first, second) {
      switch (_sortOption) {
        case _MatchSortOption.bestMatch:
          return second.matchScore.compareTo(first.matchScore);
        case _MatchSortOption.trust:
          return second.trustScore.compareTo(first.trustScore);
        case _MatchSortOption.lowCredit:
          return first.creditsRequired.compareTo(second.creditsRequired);
      }
    });

    return filtered;
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentProfile = await _profileRepository.loadProfile();
      final candidateProfiles = await _profileRepository
          .loadDiscoverableProfiles();

      final matches = const MatchingService().getRecommendedMatches(
        currentProfile: currentProfile,
        candidateProfiles: candidateProfiles,
      );

      final candidates = matches.isEmpty
          ? candidateProfiles.expand(_mapProfileToCandidates).toList()
          : matches;

      final filters =
          candidates
              .expand(
                (candidate) => [
                  candidate.teacherSkill.name,
                  candidate.studentSkill.name,
                ],
              )
              .where((name) => name.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (!mounted) return;
      setState(() {
        _currentProfile = currentProfile;
        _candidates = candidates;
        _skillFilters = filters;
        _isLoading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _mapFirestoreError(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Discovery yüklenemedi. Lütfen tekrar dene.';
      });
    }
  }

  /// Algoritmik eşleşme boşsa, ham discovery profillerinden gösterilecek
  /// bir liste türetir (her öğretilebilir skill için bir kart).
  Iterable<MatchCandidate> _mapProfileToCandidates(ProfileData profile) {
    if (profile.teachSkills.isEmpty) return const [];

    final studentSkill = profile.learnSkills.isNotEmpty
        ? profile.learnSkills.first
        : const SkillModel(id: '', name: 'Genel', level: 1);
    final trust = profile.user.trustScore.clamp(0, 100) / 100.0;

    return profile.teachSkills.map(
      (teacherSkill) => MatchCandidate(
        user: profile.user,
        teacherSkill: teacherSkill,
        studentSkill: studentSkill,
        partnerLearnSkills: profile.learnSkills,
        matchScore: 0,
        skillLevelScore: 0,
        trustScore: trust,
        availabilityScore: 0,
        profileCompleteness: _calculateProfileCompleteness(profile),
        fairnessScore: 0,
        creditsRequired: 50,
        explanation: MatchExplanation(
          skillMatchType: SkillMatchType.related,
          skillCompatibilityScore: 0,
          hasAvailabilityOverlap: false,
          averageTrustScore: trust,
          profileCompleteness: _calculateProfileCompleteness(profile),
        ),
      ),
    );
  }

  double _calculateProfileCompleteness(ProfileData profile) {
    var score = 0.0;
    const step = 0.25;
    if (profile.user.name.trim().isNotEmpty) score += step;
    if (profile.user.bio.trim().isNotEmpty) score += step;
    if (profile.teachSkills.isNotEmpty) score += step;
    if (profile.learnSkills.isNotEmpty) score += step;
    return score;
  }

  String _buildMatchReason(MatchExplanation explanation) {
    final skillPart = explanation.skillMatchType == SkillMatchType.exact
        ? 'Öğrenmek istediğin yetenek ile birebir eşleşiyor'
        : 'İlişkili bir yetenek üzerinden önerildi';
    final trustPart =
        'ortalama güven ${(explanation.averageTrustScore * 100).round()}%';
    final profilePart =
        'profil doluluğu ${(explanation.profileCompleteness * 100).round()}%';
    final availabilityPart = explanation.hasAvailabilityOverlap
        ? 'uygun zaman çakışması var'
        : 'zaman uygunluğu henüz net değil';

    return '$skillPart; $trustPart, $profilePart ve $availabilityPart.';
  }

  Future<void> _sendOffer(MatchCandidate candidate) async {
    if (PreviewMode.enabled) {
      _showSnack(
        'Örnek teklif gösterildi. Gerçek teklif veya token işlemi yapılmadı.',
      );
      return;
    }
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      _showSnack('Teklif göndermek için önce giriş yapmalısın.');
      return;
    }

    final partnerName = candidate.user.name.isEmpty
        ? 'Kullanıcı'
        : candidate.user.name;
    final skillName = candidate.teacherSkill.name;

    try {
      final matchRef = _firestore.collection('matches').doc();
      final sessionRef = _firestore.collection('sessions').doc(matchRef.id);
      final participants = [currentUser.uid, candidate.user.id]..sort();
      final chatRef = _firestore.collection('chats').doc(matchRef.id);
      final currentUserName =
          currentUser.displayName ??
          currentUser.email?.split('@').first ??
          'Kullanıcı';

      await _firestore.runTransaction((transaction) async {
        transaction.set(matchRef, {
          'id': matchRef.id,
          'participants': participants,
          'requesterId': currentUser.uid,
          'receiverId': candidate.user.id,
          'requesterName': currentUserName,
          'receiverName': partnerName,
          'participantNames': {
            currentUser.uid: currentUserName,
            candidate.user.id: partnerName,
          },
          'skillName': skillName,
          'skillId': candidate.teacherSkill.id,
          'sessionId': sessionRef.id,
          'chatId': chatRef.id,
          'status': 'pending',
          'credits': candidate.creditsRequired,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(sessionRef, {
          'id': sessionRef.id,
          'matchId': matchRef.id,
          'teacherId': candidate.user.id,
          'studentId': currentUser.uid,
          'participants': participants,
          'skillName': skillName,
          'status': 'requested',
          'credits': candidate.creditsRequired,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(chatRef, {
          'id': chatRef.id,
          'participants': participants,
          'participantNames': {
            currentUser.uid: currentUserName,
            candidate.user.id: partnerName,
          },
          'participantSkills': {
            candidate.user.id: [skillName],
          },
          'matchId': matchRef.id,
          'sessionId': sessionRef.id,
          'skillName': skillName,
          'lastMessage': '$skillName için teklif gönderildi.',
          'lastSenderId': currentUser.uid,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
          'credits': candidate.creditsRequired,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(_firestore.collection('notifications').doc(), {
          'userId': candidate.user.id,
          'senderId': currentUser.uid,
          'type': 'match_offer',
          'title': 'Yeni yetenek teklifi',
          'message':
              '${currentUser.displayName ?? 'Bir kullanıcı'} $skillName için teklif gönderdi.',
          'matchId': matchRef.id,
          'sessionId': sessionRef.id,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      _showSnack('$partnerName için teklif gönderildi.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(_mapFirestoreError(error));
    } catch (_) {
      if (!mounted) return;
      _showSnack('Teklif gönderilemedi. Lütfen tekrar dene.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapFirestoreError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Bu işlem için erişim izni bulunmuyor. Lütfen daha sonra tekrar dene.';
    }
    if (error.code == 'unavailable') {
      return 'Bağlantı şu an kullanılamıyor. İnternet bağlantını kontrol et.';
    }
    if (error.code == 'failed-precondition') {
      return 'Veriler şu anda getirilemiyor. Lütfen daha sonra tekrar dene.';
    }
    return 'İşlem tamamlanamadı. Lütfen yeniden dene.';
  }

  void _showProfileDetails(MatchCandidate candidate) {
    final profileData = OtherUserProfileData(
      id: candidate.user.id,
      name: candidate.user.name.isEmpty
          ? 'İsimsiz Kullanıcı'
          : candidate.user.name,
      location: candidate.user.location?.trim().isNotEmpty == true
          ? candidate.user.location!
          : 'Konum belirtilmedi',
      bio: candidate.user.bio,
      trustScore: candidate.user.trustScore,
      verified: candidate.user.verified,
      matchScore: (candidate.matchScore * 100).round(),
      photoUrl: candidate.user.photoUrl,
      hasCompatibilityScore: candidate.explanation.skillCompatibilityScore > 0,
      creditsRequired: candidate.creditsRequired,
      matchReason: _buildMatchReason(candidate.explanation),
      teachSkills: [
        OtherUserSkillData(
          name: candidate.teacherSkill.name,
          category: candidate.teacherSkill.category,
          level: candidate.teacherSkill.level,
          verified: candidate.teacherSkill.verified,
          peerApprovalCount: candidate.teacherSkill.peerApprovalCount,
        ),
      ],
      learnSkills: candidate.partnerLearnSkills
          .map(
            (skill) =>
                OtherUserSkillData(name: skill.name, category: skill.category),
          )
          .toList(),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtherUserProfilePage(profile: profileData),
      ),
    );
  }

  void _openSkillDetail(MatchCandidate candidate) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SkillDetailPage(
          candidate: candidate,
          onSendOffer: () => _sendOffer(candidate),
          onViewProfile: () => _showProfileDetails(candidate),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoetusPalette.lavender,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
      bottomNavigationBar: const CoetusBottomNav(currentIndex: 0),
    );
  }

  Future<void> _openCommunityAuthor(
    String authorId,
    String skillId, {
    bool learn = false,
  }) async {
    try {
      MatchCandidate? candidate;
      for (final c in _candidates) {
        if (c.user.id == authorId && c.teacherSkill.id == skillId) {
          candidate = c;
          break;
        }
      }
      if (candidate == null && PreviewMode.enabled) {
        _showSnack('Bu örnek profil için detay menüden açılabilir.');
        return;
      }
      if (candidate == null) {
        final ref = _firestore.collection('users').doc(authorId);
        final user = await ref.get();
        final skills = await ref.collection('teachSkills').get();
        if (!user.exists) throw StateError('Profil bulunamadı');
        final profile = ProfileData(
          user: AppUser.fromMap({'id': authorId, ...user.data()!}),
          teachSkills: skills.docs
              .map((d) => SkillModel.fromMap({'id': d.id, ...d.data()}))
              .toList(),
          learnSkills: const [],
        );
        for (final c in _mapProfileToCandidates(profile)) {
          if (c.teacherSkill.id == skillId) candidate = c;
        }
      }
      if (!mounted) return;
      if (candidate == null && PreviewMode.enabled) {
        _showSnack('Bu örnek profil için detay menüden açılabilir.');
        return;
      }
      if (candidate == null) {
        _showSnack('Bu yetenek artık profilde bulunmuyor.');
        return;
      }
      if (learn) {
        _openSkillDetail(candidate);
      } else {
        _showProfileDetails(candidate);
      }
    } catch (_) {
      if (mounted) _showSnack('Profil yüklenemedi. Tekrar dene.');
    }
  }

  Widget _buildBody(BuildContext context) {
    final visible = _visibleCandidates;
    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading) const LinearProgressIndicator(),
                  if (_errorMessage != null) ...[
                    Text(_errorMessage!),
                    TextButton(
                      onPressed: _loadMatches,
                      child: const Text('Eşleşmeleri yeniden yükle'),
                    ),
                  ],
                  if (visible.isNotEmpty)
                    MatchOrbit(
                      candidates: visible,
                      onSelected: _openSkillDetail,
                    ),
                  if (!_isLoading && visible.isEmpty && _errorMessage == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Henüz eşleşme yok. Profiline yetenek ekleyerek başlayabilirsin.',
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Topluluktan keşfet',
                          style: TextStyle(
                            color: CoetusPalette.purple,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const CommunityComposer(),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        tooltip: 'Paylaşım oluştur',
                      ),
                    ],
                  ),
                  const Text('Öğrenilenler, üretilenler ve yeni başlangıçlar.'),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: CommunityFeed(
              query: _searchController.text,
              skill: _selectedSkill,
              scores: {
                for (final c in _candidates)
                  if (c.explanation.skillCompatibilityScore > 0)
                    c.user.id: (c.matchScore * 100).round(),
              },
              onLearn: (a, s) => _openCommunityAuthor(a, s, learn: true),
              onProfile: (a, s) => _openCommunityAuthor(a, s),
            ),
          ),
          if (visible.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Senin için eşleşmeler',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: MatchProfileCard(
                  candidate: visible[i],
                  highlighted: visible[i].user.id == bestMatchUserId(visible),
                  onTap: () => _openSkillDetail(visible[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CoetusPalette.purple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Keşfet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: CoetusPalette.cream),
                ),
              ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: PreviewMode.enabled
                    ? null
                    : _firestore
                          .collection('users')
                          .doc(_firebaseAuth.currentUser?.uid)
                          .snapshots(),
                builder: (_, s) => CreditBadge(
                  amount:
                      (s.data?.data()?['credits'] as num?)?.toInt() ??
                      _currentProfile?.user.credits ??
                      0,
                  background: CoetusPalette.lime,
                  foreground: CoetusPalette.purple,
                ),
              ),
              const SizedBox(width: 10),
              _CircleIconButton(
                icon: Icons.notifications_outlined,
                onTap: () => context.go('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: CoetusPalette.cream),
            decoration: InputDecoration(
              hintText: 'Yetenek, isim veya şehir ara...',
              hintStyle: TextStyle(
                color: CoetusPalette.cream.withValues(alpha: .6),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: CoetusPalette.cream.withValues(alpha: .7),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CoetusRadius.input),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CoetusRadius.input),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CoetusRadius.input),
                borderSide: BorderSide(
                  color: CoetusPalette.cream.withValues(alpha: .5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.sort,
                color: CoetusPalette.cream.withValues(alpha: .7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Sırala',
                style: TextStyle(
                  color: CoetusPalette.cream.withValues(alpha: .7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<_MatchSortOption>(
                  value: _sortOption,
                  dropdownColor: CoetusPalette.purple,
                  borderRadius: BorderRadius.circular(14),
                  iconEnabledColor: CoetusPalette.cream,
                  style: const TextStyle(
                    color: CoetusPalette.cream,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _MatchSortOption.values
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (option) {
                    if (option == null) return;
                    setState(() => _sortOption = option);
                  },
                ),
              ),
            ],
          ),
          if (_skillFilters.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: CoetusPalette.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _skillFilters.length + 1,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final skill = index == 0 ? null : _skillFilters[index - 1];
                    return ChoiceChip(
                      label: Text(skill ?? 'Tümü'),
                      selected: _selectedSkill == skill,
                      showCheckmark: false,
                      backgroundColor: CoetusPalette.cream,
                      selectedColor: CoetusPalette.lime,
                      labelStyle: const TextStyle(
                        color: CoetusPalette.purple,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onSelected: (_) => setState(() => _selectedSkill = skill),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kategori/skill adına göre bir Material ikonu döndürür. [SkillDetailPage]
/// aynı kartın ikonunu göstermek için bu eşlemeyi kendi kopyasıyla tekrar
/// eder (bkz. skill_detail_page.dart).
IconData categoryIcon(String category, String name) {
  final key = '$category $name'.toLowerCase();
  if (key.contains('muzik') || key.contains('müzik') || key.contains('music')) {
    return Icons.music_note_outlined;
  }
  if (key.contains('yazilim') ||
      key.contains('yazılım') ||
      key.contains('software') ||
      key.contains('code') ||
      key.contains('kod') ||
      key.contains('programlama')) {
    return Icons.code;
  }
  if (key.contains('dil') || key.contains('language')) {
    return Icons.public;
  }
  if (key.contains('tasarim') ||
      key.contains('tasarım') ||
      key.contains('design')) {
    return Icons.brush_outlined;
  }
  if (key.contains('el sanat') || key.contains('craft')) {
    return Icons.content_cut;
  }
  if (key.contains('fotograf') ||
      key.contains('fotoğraf') ||
      key.contains('photo')) {
    return Icons.photo_camera_outlined;
  }
  return Icons.star_outline;
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: CoetusPalette.cream, size: 18),
        ),
      ),
    );
  }
}

enum _MatchSortOption {
  bestMatch('En yüksek uyum'),
  trust('Güven puanı'),
  lowCredit('Düşük token');

  final String label;

  const _MatchSortOption(this.label);
}
