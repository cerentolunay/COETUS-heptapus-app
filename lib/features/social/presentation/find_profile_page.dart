import 'dart:async';
import 'package:flutter/material.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/matching/presentation/pages/match_success_page.dart';
import 'package:coetus/features/profile/domain/models/profile_data.dart';
import 'package:coetus/features/profile/presentation/pages/other_user_profile_page.dart';
import 'package:coetus/features/profile/presentation/widgets/profile_photo_avatar.dart';
import '../data/profile_identity_service.dart';
import 'profile_qr.dart';

class FindProfilePage extends StatefulWidget {
  const FindProfilePage({super.key, this.userId, this.service});
  final String? userId;
  final ProfileIdentityService? service;
  @override
  State<FindProfilePage> createState() => _FindProfilePageState();
}

class _FindProfilePageState extends State<FindProfilePage> {
  late final _service = widget.service ?? ProfileIdentityService();
  final _name = TextEditingController();
  ProfileData? _profile;
  bool _busy = false, _waiting = false, _celebrating = false;
  String? _error, _chatId;
  StreamSubscription<bool>? _connection;
  @override
  void initState() {
    super.initState();
    if (widget.userId != null) _find(userId: widget.userId);
  }

  @override
  void dispose() {
    _connection?.cancel();
    _name.dispose();
    super.dispose();
  }

  Future<void> _find({String? userId}) async {
    if (_busy) return;
    _connection?.cancel();
    setState(() {
      _busy = true;
      _error = null;
      _profile = null;
      _waiting = false;
    });
    try {
      if (userId == null && _name.text.trim().isEmpty) {
        throw StateError('Bir kullanıcı adı yaz.');
      }
      final profile = await _service.find(
        userId: userId,
        username: userId == null ? _name.text.trim() : null,
      );
      if (!mounted) return;
      if (profile.user.id == _service.currentUserId) {
        throw StateError(
          'Bu senin profilin. Başka bir kişinin kodunu okutabilirsin.',
        );
      }
      setState(() => _profile = profile);
    } catch (error) {
      if (mounted) setState(() => _error = identityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() async {
    if (_busy || _profile == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.connect(_profile!.user.id);
      if (!mounted) return;
      _chatId = result.chatId;
      if (result.confirmed) {
        _celebrate();
      } else {
        setState(() => _waiting = true);
        _connection = _service
            .watchConnection(result.id)
            .listen(
              (confirmed) {
                if (confirmed && mounted) _celebrate();
              },
              onError: (Object error) {
                if (mounted) setState(() => _error = identityError(error));
              },
            );
      }
    } catch (error) {
      if (mounted) setState(() => _error = identityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _celebrate() {
    if (_celebrating || _profile == null) return;
    _celebrating = true;
    _connection?.cancel();
    final profile = _profile!;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MatchSuccessPage(
          claimGift: false,
          chatId: _chatId,
          user: MatchedUser(
            name: profile.user.name,
            skills: profile.teachSkills
                .map((s) => MatchedSkill(name: s.name, emoji: '✨'))
                .toList(),
            learningGoals: profile.learnSkills
                .map((s) => MatchedGoal(name: s.name, emoji: '🌱'))
                .toList(),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _celebrating = false;
          _waiting = false;
        });
      }
    });
  }

  void _showProfile() {
    final p = _profile!;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OtherUserProfilePage(
          profile: OtherUserProfileData(
            id: p.user.id,
            username: p.user.username,
            name: p.user.name,
            bio: p.user.bio,
            location: p.user.location ?? '',
            photoUrl: p.user.photoUrl,
            trustScore: p.user.trustScore,
            verified: false,
            matchScore: 0,
            hasCompatibilityScore: false,
            creditsRequired: 0,
            teachSkills: p.teachSkills
                .map((s) => OtherUserSkillData(name: s.name, level: s.level))
                .toList(),
            learnSkills: p.learnSkills
                .map((s) => OtherUserSkillData(name: s.name))
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Birbirinizi bulun')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _name,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Kullanıcı adı',
            prefixText: '@',
          ),
          onSubmitted: (_) => _find(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : () => _find(),
          child: const Text('Kullanıcı adıyla bul'),
        ),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final uid = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanProfileQrPage(),
                    ),
                  );
                  if (uid != null && mounted) await _find(userId: uid);
                },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('QR kod okut'),
        ),
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: CoetusColors.danger),
            ),
          ),
        if (_profile != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ProfilePhotoAvatar(
                    photoUrl: _profile!.user.photoUrl,
                    initials: _profile!.user.name.isEmpty
                        ? '?'
                        : _profile!.user.name.substring(0, 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profile!.user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_profile!.user.username.isNotEmpty)
                    Text('@${_profile!.user.username}'),
                  Text(_profile!.user.bio, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _showProfile,
                    child: const Text('Profili görüntüle'),
                  ),
                  FilledButton(
                    onPressed: _busy || _waiting ? null : _connect,
                    child: Text(
                      _waiting
                          ? 'Karşı tarafın onayı bekleniyor'
                          : 'Tanışmayı onayla',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İkiniz de onayladığınızda eşleşme ekranınız ve sohbetiniz açılır. Tanışma onayı token bakiyesini değiştirmez.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
