import 'package:cloud_firestore/cloud_firestore.dart';
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
  const MatchingFeedPage({super.key});

  @override
  State<MatchingFeedPage> createState() => _MatchingFeedPageState();
}

class _MatchingFeedPageState extends State<MatchingFeedPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    _loadMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MatchCandidate> get _visibleCandidates {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _candidates.where((candidate) {
      final location = candidate.user.location ?? '';
      final matchesSearch =
          query.isEmpty ||
          candidate.user.name.toLowerCase().contains(query) ||
          location.toLowerCase().contains(query) ||
          candidate.user.bio.toLowerCase().contains(query) ||
          candidate.teacherSkill.name.toLowerCase().contains(query) ||
          candidate.studentSkill.name.toLowerCase().contains(query);

      final matchesSkill =
          _selectedSkill == null ||
          candidate.teacherSkill.name == _selectedSkill ||
          candidate.studentSkill.name == _selectedSkill;

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
        _errorMessage = 'Discovery yuklenemedi. Lutfen tekrar dene.';
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
        ? 'Ogrenmek istedigin skill ile birebir eslesiyor'
        : 'Iliskili bir skill uzerinden onerildi';
    final trustPart =
        'ortalama trust ${(explanation.averageTrustScore * 100).round()}%';
    final profilePart =
        'profil dolulugu ${(explanation.profileCompleteness * 100).round()}%';
    final availabilityPart = explanation.hasAvailabilityOverlap
        ? 'uygun zaman cakismasi var'
        : 'zaman uygunlugu henuz net degil';

    return '$skillPart; $trustPart, $profilePart ve $availabilityPart.';
  }

  Future<void> _sendOffer(MatchCandidate candidate) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      _showSnack('Teklif gondermek icin once giris yapmalisin.');
      return;
    }

    final partnerName = candidate.user.name.isEmpty
        ? 'Kullanici'
        : candidate.user.name;
    final skillName = candidate.teacherSkill.name;

    try {
      final matchRef = _firestore.collection('matches').doc();
      final sessionRef = _firestore.collection('sessions').doc();
      final participants = [currentUser.uid, candidate.user.id]..sort();
      final chatRef = _firestore
          .collection('chats')
          .doc(participants.join('_'));
      final currentUserName =
          currentUser.displayName ??
          currentUser.email?.split('@').first ??
          'Kullanici';

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
          'lastMessage': '$skillName icin teklif gonderildi.',
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
          'title': 'Yeni skill teklifi',
          'message':
              '${currentUser.displayName ?? 'Bir kullanici'} $skillName icin teklif gonderdi.',
          'matchId': matchRef.id,
          'sessionId': sessionRef.id,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      _showSnack('$partnerName icin teklif gonderildi.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(_mapFirestoreError(error));
    } catch (_) {
      if (!mounted) return;
      _showSnack('Teklif gonderilemedi. Lutfen tekrar dene.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapFirestoreError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Firestore izinleri bu islem icin uygun degil. Kurallari yayinladigindan emin ol.';
    }
    if (error.code == 'unavailable') {
      return 'Firestore su an kullanilamiyor. Internet baglantini kontrol et.';
    }
    if (error.code == 'failed-precondition') {
      return 'Firestore index veya veritabani ayari eksik gorunuyor.';
    }
    return 'Firestore hatasi: ${error.message ?? error.code}';
  }

  void _showProfileDetails(MatchCandidate candidate) {
    final profileData = OtherUserProfileData(
      id: candidate.user.id,
      name: candidate.user.name.isEmpty
          ? 'Isimsiz Kullanici'
          : candidate.user.name,
      location: candidate.user.location?.trim().isNotEmpty == true
          ? candidate.user.location!
          : 'Konum belirtilmedi',
      bio: candidate.user.bio,
      trustScore: candidate.user.trustScore,
      verified: candidate.user.verified,
      matchScore: (candidate.matchScore * 100).round(),
      creditsRequired: candidate.creditsRequired,
      matchReason: _buildMatchReason(candidate.explanation),
      teachSkills: [
        OtherUserSkillData(
          name: candidate.teacherSkill.name,
          category: candidate.teacherSkill.category,
          level: candidate.teacherSkill.level,
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
      backgroundColor: CoetusColors.oat,
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

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final visible = _visibleCandidates;
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CoetusSpace.xl),
          child: CoetusEmptyState(
            title: 'Henuz eslesme yok',
            message:
                'Ogretebilecegin bir yetenek ekle, sana uygun kisileri getirelim.',
            icon: Icons.search_off,
            actionLabel: 'Yetenek ekle',
            onAction: () => context.go('/profile'),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: .78,
      ),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final candidate = visible[index];
        return SkillCard(
          title: candidate.teacherSkill.name,
          subtitle:
              '${candidate.teacherSkill.category.isNotEmpty ? candidate.teacherSkill.category : "Genel"} '
              '· ${candidate.user.name}',
          icon: categoryIcon(
            candidate.teacherSkill.category,
            candidate.teacherSkill.name,
          ),
          credits: candidate.creditsRequired,
          statusLabel: candidate.explanation.hasAvailabilityOverlap
              ? 'Musait'
              : null,
          plate: index.isEven
              ? CoetusColors.plateWarm
              : CoetusColors.plateWarmAlt,
          onTap: () => _openSkillDetail(candidate),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: CoetusColors.navy,
              size: 46,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadMatches,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final credits = _currentProfile?.user.credits ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: CoetusColors.navy,
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
                  'Coetus',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: CoetusColors.oat,
                  ),
                ),
              ),
              CreditBadge(
                amount: credits,
                background: Colors.white.withValues(alpha: .16),
                foreground: CoetusColors.oat,
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
            style: const TextStyle(color: CoetusColors.oat),
            decoration: InputDecoration(
              hintText: 'Skill, isim veya sehir ara...',
              hintStyle: TextStyle(color: CoetusColors.oat.withValues(alpha: .6)),
              prefixIcon: Icon(
                Icons.search,
                color: CoetusColors.oat.withValues(alpha: .7),
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
                  color: CoetusColors.oat.withValues(alpha: .5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.sort,
                color: CoetusColors.oat.withValues(alpha: .7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Sirala',
                style: TextStyle(
                  color: CoetusColors.oat.withValues(alpha: .7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<_MatchSortOption>(
                  value: _sortOption,
                  dropdownColor: CoetusColors.navyInk,
                  borderRadius: BorderRadius.circular(14),
                  iconEnabledColor: CoetusColors.oat,
                  style: const TextStyle(
                    color: CoetusColors.oat,
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
                color: CoetusColors.oat,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CategoryTabs(
                items: ['Tumu', ..._skillFilters],
                selected: _selectedSkill == null
                    ? 0
                    : _skillFilters.indexOf(_selectedSkill!) + 1,
                onChanged: (index) {
                  setState(() {
                    _selectedSkill = index == 0
                        ? null
                        : _skillFilters[index - 1];
                  });
                },
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
          child: Icon(icon, color: CoetusColors.oat, size: 18),
        ),
      ),
    );
  }
}

enum _MatchSortOption {
  bestMatch('En iyi match'),
  trust('Trust score'),
  lowCredit('Dusuk kredi');

  final String label;

  const _MatchSortOption(this.label);
}
