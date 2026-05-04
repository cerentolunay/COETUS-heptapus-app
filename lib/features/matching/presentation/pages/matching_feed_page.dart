import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MatchingFeedPage extends StatefulWidget {
  const MatchingFeedPage({super.key});

  @override
  State<MatchingFeedPage> createState() => _MatchingFeedPageState();
}

class _MatchingFeedPageState extends State<MatchingFeedPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<_UserMatch> _users = [];
  List<String> _skillFilters = [];
  int _currentIndex = 0;
  int _swipeDirection = 0;
  bool _isLoading = true;
  bool _isSendingOffer = false;
  String? _selectedSkill;
  String? _errorMessage;

  static const Color _bgTop = Color(0xFF0B1120);
  static const Color _bgMid = Color(0xFF0F172A);
  static const Color _bgBottom = Color(0xFF1E1B4B);

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _violetSoft = Color(0xFFA78BFA);

  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _textSoft = Color(0xFFCBD5E1);
  static const Color _textDarkMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_resetIndexForFilters);
    _loadMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_UserMatch> get _visibleUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesSearch =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.location.toLowerCase().contains(query) ||
          user.bio.toLowerCase().contains(query) ||
          user.canTeach.any(
            (skill) => skill.name.toLowerCase().contains(query),
          ) ||
          user.wantToLearn.any(
            (goal) => goal.name.toLowerCase().contains(query),
          );

      final matchesSkill =
          _selectedSkill == null ||
          user.canTeach.any((skill) => skill.name == _selectedSkill) ||
          user.wantToLearn.any((goal) => goal.name == _selectedSkill);

      return matchesSearch && matchesSkill;
    }).toList();
  }

  Future<void> _loadMatches() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Discover icin once giris yapmalisin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserDoc = _firestore
          .collection('users')
          .doc(currentUser.uid);
      final myTeachSkills = await _readSkills(
        currentUserDoc.collection('teachSkills'),
      );
      final myLearnSkills = await _readSkills(
        currentUserDoc.collection('learnSkills'),
      );

      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();

      final matches = <_UserMatch>[];
      for (final doc in usersSnapshot.docs) {
        if (doc.id == currentUser.uid) continue;

        final data = doc.data();
        final teachSkills = await _readSkills(
          doc.reference.collection('teachSkills'),
        );
        final learnSkills = await _readSkills(
          doc.reference.collection('learnSkills'),
        );

        matches.add(
          _UserMatch.fromFirestore(
            id: doc.id,
            data: data,
            teachSkills: teachSkills,
            learnSkills: learnSkills,
            matchPercentage: _calculateMatchPercentage(
              myTeachSkills: myTeachSkills,
              myLearnSkills: myLearnSkills,
              theirTeachSkills: teachSkills,
              theirLearnSkills: learnSkills,
            ),
          ),
        );
      }

      final filters =
          matches
              .expand(
                (user) => [
                  ...user.canTeach.map((skill) => skill.name),
                  ...user.wantToLearn.map((goal) => goal.name),
                ],
              )
              .where((name) => name.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (!mounted) return;
      setState(() {
        _users = matches;
        _skillFilters = filters;
        _currentIndex = 0;
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

  Future<List<_TeachSkill>> _readSkills(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return _TeachSkill(
            name: data['name'] as String? ?? '',
            level: _readInt(data['level'], fallback: 1).clamp(1, 7),
            category: data['category'] as String? ?? '',
          );
        })
        .where((skill) => skill.name.trim().isNotEmpty)
        .toList();
  }

  int _calculateMatchPercentage({
    required List<_TeachSkill> myTeachSkills,
    required List<_TeachSkill> myLearnSkills,
    required List<_TeachSkill> theirTeachSkills,
    required List<_TeachSkill> theirLearnSkills,
  }) {
    final myTeach = myTeachSkills
        .map((skill) => skill.name.toLowerCase())
        .toSet();
    final myLearn = myLearnSkills
        .map((skill) => skill.name.toLowerCase())
        .toSet();
    final theirTeach = theirTeachSkills
        .map((skill) => skill.name.toLowerCase())
        .toSet();
    final theirLearn = theirLearnSkills
        .map((skill) => skill.name.toLowerCase())
        .toSet();

    final theyTeachWhatILearn = theirTeach.intersection(myLearn).length;
    final iTeachWhatTheyLearn = myTeach.intersection(theirLearn).length;
    final score = 72 + (theyTeachWhatILearn * 10) + (iTeachWhatTheyLearn * 8);
    return score.clamp(72, 98);
  }

  void _resetIndexForFilters() {
    setState(() => _currentIndex = 0);
  }

  void _handleSwipe(String direction) {
    if (_currentIndex >= _visibleUsers.length) return;

    setState(() {
      _swipeDirection = direction == 'right' ? 1 : -1;
    });

    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() {
        _currentIndex += 1;
        _swipeDirection = 0;
      });
    });
  }

  Future<void> _sendOffer(_UserMatch user, _TeachSkill skill) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      _showSnack('Teklif gondermek icin once giris yapmalisin.');
      return;
    }

    setState(() => _isSendingOffer = true);
    try {
      final matchRef = _firestore.collection('matches').doc();
      final sessionRef = _firestore.collection('sessions').doc();
      final participants = [currentUser.uid, user.id]..sort();
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
          'receiverId': user.id,
          'skillName': skill.name,
          'status': 'pending',
          'credits': user.creditsRequired,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(sessionRef, {
          'id': sessionRef.id,
          'matchId': matchRef.id,
          'teacherId': user.id,
          'studentId': currentUser.uid,
          'skillName': skill.name,
          'status': 'requested',
          'credits': user.creditsRequired,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(chatRef, {
          'id': chatRef.id,
          'participants': participants,
          'participantNames': {
            currentUser.uid: currentUserName,
            user.id: user.name,
          },
          'participantSkills': {
            user.id: [skill.name],
          },
          'matchId': matchRef.id,
          'sessionId': sessionRef.id,
          'skillName': skill.name,
          'lastMessage': '${skill.name} icin teklif gonderildi.',
          'lastSenderId': currentUser.uid,
          'unreadCount': 0,
          'credits': user.creditsRequired,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(_firestore.collection('notifications').doc(), {
          'userId': user.id,
          'senderId': currentUser.uid,
          'type': 'match_offer',
          'title': 'Yeni skill teklifi',
          'message':
              '${currentUser.displayName ?? 'Bir kullanici'} ${skill.name} icin teklif gonderdi.',
          'matchId': matchRef.id,
          'sessionId': sessionRef.id,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack('${user.name} icin teklif gonderildi.');
      _handleSwipe('right');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(_mapFirestoreError(error));
    } catch (_) {
      if (!mounted) return;
      _showSnack('Teklif gonderilemedi. Lutfen tekrar dene.');
    } finally {
      if (mounted) setState(() => _isSendingOffer = false);
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

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _visibleUsers;
    final bool isFinished = _currentIndex >= visibleUsers.length;
    final _UserMatch? currentUser = isFinished
        ? null
        : visibleUsers[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgMid, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _cyan))
              : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildHeader(visibleUsers.length),
                    _buildFilters(),
                    Expanded(
                      child: isFinished
                          ? _buildFinishedState(context)
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: AnimatedSlide(
                                duration: const Duration(milliseconds: 260),
                                offset: Offset(
                                  _swipeDirection == 0
                                      ? 0
                                      : (_swipeDirection == 1 ? 1.2 : -1.2),
                                  0,
                                ),
                                child: AnimatedRotation(
                                  duration: const Duration(milliseconds: 260),
                                  turns: _swipeDirection == 0
                                      ? 0
                                      : (_swipeDirection == 1 ? 0.04 : -0.04),
                                  child: _MatchCard(
                                    user: currentUser!,
                                    onOpenDetails: () =>
                                        _showProfileDetails(currentUser),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (currentUser != null)
                      _buildActionButtons(context, currentUser),
                    _buildBottomNav(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: _cyan, size: 46),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 15,
                height: 1.5,
              ),
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

  Widget _buildFinishedState(BuildContext context) {
    final hasFilters =
        _searchController.text.trim().isNotEmpty || _selectedSkill != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_violet, _cyan]),
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              child: Icon(
                hasFilters ? Icons.filter_alt_off_outlined : Icons.auto_awesome,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'Sonuc bulunamadi' : 'Herkese baktin',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Filtreyi temizleyip tekrar deneyebilirsin.'
                  : 'Yeni profiller geldiginde burada gorunecek.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: hasFilters
                  ? () {
                      _searchController.clear();
                      setState(() {
                        _selectedSkill = null;
                        _currentIndex = 0;
                      });
                    }
                  : _loadMatches,
              child: Text(hasFilters ? 'Filtreleri temizle' : 'Yenile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int remaining) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discover Matches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$remaining profil bulundu',
                style: const TextStyle(color: _textMuted, fontSize: 13),
              ),
            ],
          ),
          IconButton(
            onPressed: _loadMatches,
            icon: const Icon(Icons.refresh, color: _cyan),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Skill, isim veya sehir ara...',
              hintStyle: const TextStyle(color: _textMuted),
              prefixIcon: const Icon(Icons.search, color: _textMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _cyan),
              ),
            ),
          ),
          if (_skillFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _skillFilters.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final String? filter = index == 0
                      ? null
                      : _skillFilters[index - 1];
                  final selected = filter == _selectedSkill;
                  return ChoiceChip(
                    label: Text(filter ?? 'All'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedSkill = filter;
                        _currentIndex = 0;
                      });
                    },
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _textSoft,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: _violet,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    side: BorderSide(
                      color: selected
                          ? _violetSoft
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, _UserMatch user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                size: 64,
                borderColor: Colors.white.withValues(alpha: 0.10),
                icon: Icons.close,
                iconColor: Colors.redAccent,
                onTap: () => _handleSwipe('left'),
              ),
              const SizedBox(width: 24),
              _GradientActionButton(
                size: 80,
                icon: Icons.favorite,
                isBusy: _isSendingOffer,
                onTap: () => _showOfferSheet(user),
              ),
              const SizedBox(width: 24),
              _ActionButton(
                size: 64,
                borderColor: _cyan.withValues(alpha: 0.35),
                icon: Icons.info_outline,
                iconColor: _cyan,
                onTap: () => _showProfileDetails(user),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Teklif ${user.creditsRequired} HC ile olusturulur',
            style: const TextStyle(color: _textDarkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showProfileDetails(_UserMatch user) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: _textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(user.location, style: const TextStyle(color: _textMuted)),
                const SizedBox(height: 16),
                Text(
                  user.bio,
                  style: const TextStyle(color: _textSoft, height: 1.5),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ogretir',
                  style: TextStyle(color: _cyan, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.canTeach
                      .map((skill) => _SkillChip(label: skill.name))
                      .toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ogrenmek istiyor',
                  style: TextStyle(
                    color: _violetSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.wantToLearn
                      .map((goal) => _SkillChip(label: goal.name))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOfferSheet(_UserMatch user) {
    if (user.canTeach.isEmpty) {
      _showSnack('Bu kullanicinin henuz ogretecegi skill yok.');
      return;
    }

    _TeachSkill selectedSkill = user.canTeach.first;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teklif Gonder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${user.name} sana hangi skill icin yardim etsin?',
                      style: const TextStyle(color: _textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    ...user.canTeach.map(
                      (skill) => _OfferSkillOption(
                        skill: skill,
                        selected: skill == selectedSkill,
                        onTap: () => setSheetState(() => selectedSkill = skill),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSendingOffer
                            ? null
                            : () => _sendOffer(user, selectedSkill),
                        icon: _isSendingOffer
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          '${user.creditsRequired} HC ile teklif gonder',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgMid.withValues(alpha: 0.86),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => context.go('/profile'),
          ),
          _BottomNavItem(
            icon: Icons.trending_up,
            label: 'Discover',
            isActive: true,
            onTap: () {},
          ),
          _BottomNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chats',
            showDot: true,
            onTap: () => context.go('/chat'),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final _UserMatch user;
  final VoidCallback onOpenDetails;

  const _MatchCard({required this.user, required this.onOpenDetails});

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _violetSoft = Color(0xFFA78BFA);
  static const Color _green = Color(0xFF4ADE80);

  static const Color _surface = Color(0x14FFFFFF);
  static const Color _surfaceBorder = Color(0x1AFFFFFF);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _textSoft = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _surfaceBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopSection(),
                        const SizedBox(height: 22),
                        _buildTeachSection(),
                        const SizedBox(height: 22),
                        _buildLearnSection(),
                        const SizedBox(height: 22),
                        _buildTraitsSection(),
                      ],
                    ),
                  ),
                ),
                _buildSessionCost(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (user.verified) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _cyan,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.location,
                    style: const TextStyle(color: _textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        label: '${user.matchPercentage}% Match',
                        color: _violetSoft,
                        borderColor: _violet,
                      ),
                      _MetricChip(
                        label: '${user.trustScore}% Trust',
                        color: _green,
                        borderColor: _green,
                        icon: Icons.shield_outlined,
                      ),
                      _MetricChip(
                        label: '${user.totalSwaps} Swaps',
                        color: _cyan,
                        borderColor: _cyan,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.bio.isEmpty ? 'Bu kullanici henuz bio eklememis.' : user.bio,
          style: const TextStyle(color: _textSoft, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildTeachSection() {
    return _SkillSection(
      icon: Icons.trending_up,
      iconColor: _cyan,
      title: 'CAN TEACH YOU',
      emptyText: 'Henuz ogretecegi skill eklememis.',
      children: user.canTeach
          .map(
            (skill) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TeachSkillCard(skill: skill),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLearnSection() {
    return _SkillSection(
      icon: Icons.gps_fixed,
      iconColor: _violet,
      title: 'WANTS TO LEARN',
      emptyText: 'Henuz ogrenmek istedigi skill yok.',
      children: [
        GridView.builder(
          itemCount: user.wantToLearn.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (context, index) {
            final goal = user.wantToLearn[index];
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Text(
                goal.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTraitsSection() {
    return _SkillSection(
      icon: Icons.auto_awesome,
      iconColor: _cyan,
      title: 'PROFILE TAGS',
      emptyText: '',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: user.personalityTraits
              .map((trait) => _SkillChip(label: trait))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSessionCost() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _violet.withValues(alpha: 0.20),
              _cyan.withValues(alpha: 0.20),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _violet.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: _cyan, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Session Cost',
                style: TextStyle(
                  color: _textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${user.creditsRequired} HC',
              style: const TextStyle(
                color: _cyan,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String emptyText;
  final List<Widget> children;

  const _SkillSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.emptyText,
    required this.children,
  });

  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (children.isEmpty && emptyText.isNotEmpty)
          Text(emptyText, style: const TextStyle(color: _textMuted))
        else
          ...children,
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final IconData? icon;

  const _MetricChip({
    required this.label,
    required this.color,
    required this.borderColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _OfferSkillOption extends StatelessWidget {
  final _TeachSkill skill;
  final bool selected;
  final VoidCallback onTap;

  const _OfferSkillOption({
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? _cyan.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _cyan : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? _cyan : _textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Level ${skill.level}/7',
                        style: const TextStyle(color: _textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeachSkillCard extends StatelessWidget {
  final _TeachSkill skill;

  const _TeachSkillCard({required this.skill});

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _cyan]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      skill.category.isEmpty ? 'Skill' : skill.category,
                      style: const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _cyan]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${skill.level}/7',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              final active = index < skill.level;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == 6 ? 0 : 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: active
                        ? const LinearGradient(colors: [_violet, _cyan])
                        : null,
                    color: active ? null : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final double size;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.size,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onTap;

  const _GradientActionButton({
    required this.size,
    required this.icon,
    required this.onTap,
    this.isBusy = false,
  });

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_violet, _cyan]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _violet.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isBusy
              ? const Padding(
                  padding: EdgeInsets.all(26),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.showDot = false,
  });

  static const Color _active = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _active : Colors.white.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (showDot)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _active,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMatch {
  final String id;
  final String name;
  final String location;
  final int trustScore;
  final String bio;
  final bool verified;
  final List<_TeachSkill> canTeach;
  final List<_LearnGoal> wantToLearn;
  final List<String> personalityTraits;
  final int matchPercentage;
  final int creditsRequired;
  final int totalSwaps;

  const _UserMatch({
    required this.id,
    required this.name,
    required this.location,
    required this.trustScore,
    required this.bio,
    required this.verified,
    required this.canTeach,
    required this.wantToLearn,
    required this.personalityTraits,
    required this.matchPercentage,
    required this.creditsRequired,
    required this.totalSwaps,
  });

  factory _UserMatch.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required List<_TeachSkill> teachSkills,
    required List<_TeachSkill> learnSkills,
    required int matchPercentage,
  }) {
    final name = data['name'] as String? ?? 'Isimsiz Kullanici';
    final location = data['location'] as String? ?? 'Konum belirtilmedi';
    final traits = <String>[
      if ((data['verified'] as bool? ?? false)) 'Verified',
      if (teachSkills.isNotEmpty) '${teachSkills.length} teach skill',
      if (learnSkills.isNotEmpty) '${learnSkills.length} learn goal',
    ];

    return _UserMatch(
      id: id,
      name: name,
      location: location,
      trustScore: _readInt(data['trustScore'], fallback: 80).clamp(0, 100),
      bio: data['bio'] as String? ?? '',
      verified: data['verified'] as bool? ?? false,
      canTeach: teachSkills,
      wantToLearn: learnSkills
          .map(
            (skill) => _LearnGoal(name: skill.name, category: skill.category),
          )
          .toList(),
      personalityTraits: traits.isEmpty ? const ['New member'] : traits,
      matchPercentage: matchPercentage,
      creditsRequired: 50,
      totalSwaps: _readInt(data['totalSwaps'], fallback: 0),
    );
  }
}

class _TeachSkill {
  final String name;
  final int level;
  final String category;

  const _TeachSkill({
    required this.name,
    required this.level,
    required this.category,
  });
}

class _LearnGoal {
  final String name;
  final String category;

  const _LearnGoal({required this.name, required this.category});
}

int _readInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
