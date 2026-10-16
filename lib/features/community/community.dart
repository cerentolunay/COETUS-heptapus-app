import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';

Future<void> communityCall(String name, Map<String, dynamic> data) async {
  await FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  ).httpsCallable(name).call(data);
}

String communityError(Object e) => e is FirebaseFunctionsException
    ? e.code == 'not-found'
          ? 'Bu özellik için Firebase sunucu güncellemesi gerekli veya paylaşım artık yayında değil.'
          : e.message ?? 'İşlem tamamlanamadı. Tekrar dene.'
    : 'Bağlantını kontrol edip tekrar dene.';

/// Sliver so the orbit and posts share one scroll position.
class CommunityFeed extends StatefulWidget {
  const CommunityFeed({
    super.key,
    required this.onLearn,
    required this.onProfile,
    this.query = '',
    this.skill,
    this.scores = const {},
  });
  final void Function(String authorId, String skillId) onLearn;
  final void Function(String authorId, String skillId) onProfile;
  final String query;
  final String? skill;
  final Map<String, int> scores;
  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed> {
  int _limit = 20;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _stream = FirebaseFirestore.instance
        .collection('communityPosts')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots();
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Paylaşımlar yüklenemedi. Bağlantını ve Firebase yayın ayarlarını kontrol et.',
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final docs = snapshot.data!.docs.where((d) {
        final p = d.data();
        final searchable =
            '${p['caption']} ${p['authorName']} ${p['skillName']}'
                .toLowerCase();
        return searchable.contains(widget.query.toLowerCase().trim()) &&
            (widget.skill == null || p['skillName'] == widget.skill);
      }).toList();
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          if (i == docs.length) {
            return Column(
              children: [
                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Henüz paylaşım yok. Öğrendiğin veya ürettiğin bir şeyi paylaş!',
                    ),
                  ),
                if (snapshot.data!.docs.length >= _limit)
                  TextButton(
                    onPressed: () => setState(() {
                      _limit += 20;
                      _listen();
                    }),
                    child: const Text('Daha fazla göster'),
                  ),
                const SizedBox(height: 20),
              ],
            );
          }
          final d = docs[i];
          final p = d.data();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CommunityPost(
              key: ValueKey(d.id),
              postId: d.id,
              data: p,
              score: widget.scores[p['authorId']],
              onLearn: () => widget.onLearn(
                p['authorId'] as String,
                p['skillId'] as String,
              ),
              onProfile: () => widget.onProfile(
                p['authorId'] as String,
                p['skillId'] as String,
              ),
            ),
          );
        }, childCount: docs.length + 1),
      );
    },
  );
}

class CommunityPost extends StatefulWidget {
  const CommunityPost({
    super.key,
    required this.postId,
    required this.data,
    required this.onLearn,
    required this.onProfile,
    this.score,
  });
  final String postId;
  final Map<String, dynamic> data;
  final VoidCallback onLearn, onProfile;
  final int? score;
  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(communityError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.data;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final own = uid == p['authorId'];
    final media = p['media'] as Map<String, dynamic>?;
    return Container(
      decoration: BoxDecoration(
        color: CoetusPalette.cream,
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onProfile,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: CoetusPalette.lime,
                  backgroundImage:
                      (p['authorPhotoUrl'] as String?)?.isNotEmpty == true
                      ? NetworkImage(p['authorPhotoUrl'] as String)
                      : null,
                  child: (p['authorPhotoUrl'] as String?)?.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person, color: CoetusPalette.purple),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['authorName'] as String? ?? 'Kullanıcı',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        p['skillName'] as String? ?? '',
                        style: const TextStyle(color: CoetusPalette.purple),
                      ),
                    ],
                  ),
                ),
                if (widget.score != null)
                  Chip(
                    label: Text('%${widget.score} uyum'),
                    backgroundColor: CoetusPalette.lime,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(p['authorId'] as String)
                .snapshots(),
            builder: (_, s) =>
                ((s.data?.data()?['peerApprovalCount'] as num?)?.toInt() ?? 0) >
                    0
                ? Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: CoetusPalette.purple,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${s.data?.data()?["peerApprovalCount"]} eşleşme onayı',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Text(p['caption'] as String? ?? ''),
          if (media != null) ...[
            const SizedBox(height: 12),
            CommunityMedia(
              path: media['path'] as String,
              video: (media['contentType'] as String).startsWith('video/'),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('communityPosts')
                    .doc(widget.postId)
                    .collection('likes')
                    .doc(uid)
                    .snapshots(),
                builder: (context, s) {
                  final liked = s.data?.exists == true;
                  return TextButton.icon(
                    onPressed: _busy || !s.hasData
                        ? null
                        : () => _run(
                            () => communityCall('setCommunityLike', {
                              'postId': widget.postId,
                              'liked': !liked,
                            }),
                          ),
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: CoetusPalette.red,
                    ),
                    label: Text(
                      '${p['likeCount'] ?? 0}',
                      style: const TextStyle(color: CoetusPalette.purple),
                    ),
                  );
                },
              ),
              TextButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CommunityComments(postId: widget.postId),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text('${p['commentCount'] ?? 0}'),
              ),
              if (!own)
                FilledButton(
                  onPressed: widget.onLearn,
                  style: FilledButton.styleFrom(
                    backgroundColor: CoetusPalette.lime,
                    foregroundColor: CoetusPalette.purple,
                  ),
                  child: const Text('Birlikte öğren'),
                ),
            ],
          ),
          const Text(
            'Kalp, yorum ve teklif göndermek ücretsiz.',
            style: TextStyle(fontSize: 11, color: CoetusPalette.purple),
          ),
          if (!own)
            TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CommunitySupport(postId: widget.postId),
              ),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text('Token ile destekle · ${p['supportTotal'] ?? 0}'),
            ),
          if (own)
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Paylaşımı sil?'),
                          content: const Text(
                            'Bu paylaşım topluluk akışından kaldırılacak.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Vazgeç'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text(
                                'Sil',
                                style: TextStyle(color: CoetusPalette.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (yes == true) {
                        await _run(
                          () => communityCall('deleteCommunityPost', {
                            'postId': widget.postId,
                          }),
                        );
                      }
                    },
              icon: const Icon(Icons.delete_outline, color: CoetusPalette.red),
              label: const Text('Paylaşımı sil'),
            ),
        ],
      ),
    );
  }
}

class CommunityMedia extends StatefulWidget {
  const CommunityMedia({super.key, required this.path, required this.video});
  final String path;
  final bool video;
  @override
  State<CommunityMedia> createState() => _CommunityMediaState();
}

class _CommunityMediaState extends State<CommunityMedia>
    with WidgetsBindingObserver {
  late Future<String> _url;
  VideoPlayerController? _controller;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _url = FirebaseStorage.instance.ref(widget.path).getDownloadURL();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: FutureBuilder<String>(
      future: _url,
      builder: (context, s) {
        if (s.hasError) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Medya yüklenemedi.'),
          );
        }
        if (!s.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!widget.video) {
          return Image.network(
            s.data!,
            width: double.infinity,
            height: 280,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Text('Fotoğraf yüklenemedi.'),
          );
        }
        final c = _controller;
        return Column(
          children: [
            if (c?.value.isInitialized == true)
              AspectRatio(
                aspectRatio: c!.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            TextButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        if (_controller == null) {
                          final controller = VideoPlayerController.networkUrl(
                            Uri.parse(s.data!),
                          );
                          _controller = controller;
                          await controller.initialize();
                        }
                        if (!mounted) return;
                        final controller = _controller!;
                        controller.value.isPlaying
                            ? await controller.pause()
                            : await controller.play();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Video oynatılamadı.'),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              icon: Icon(
                c?.value.isPlaying == true
                    ? Icons.pause_circle
                    : Icons.play_circle,
              ),
              label: Text(
                _loading
                    ? 'Video yükleniyor…'
                    : c?.value.isPlaying == true
                    ? 'Duraklat'
                    : 'Videoyu izle',
              ),
            ),
          ],
        );
      },
    ),
  );
}

class CommunityComments extends StatefulWidget {
  const CommunityComments({super.key, required this.postId});
  final String postId;
  @override
  State<CommunityComments> createState() => _CommunityCommentsState();
}

class _CommunityCommentsState extends State<CommunityComments> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _retryId;
  late final _comments = FirebaseFirestore.instance
      .collection('communityPosts')
      .doc(widget.postId)
      .collection('comments');
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Column(
          children: [
            const Text(
              'Yorumlar · Ücretsiz',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _comments
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, s) {
                  if (s.hasError) {
                    return const Center(child: Text('Yorumlar yüklenemedi.'));
                  }
                  if (!s.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (s.data!.docs.isEmpty) {
                    return const Center(child: Text('İlk yorumu sen yaz.'));
                  }
                  return ListView(
                    children: s.data!.docs
                        .map(
                          (d) => ListTile(
                            title: Text(
                              d.data()['authorName'] as String? ?? 'Kullanıcı',
                            ),
                            subtitle: Text(d.data()['text'] as String? ?? ''),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
            TextField(
              controller: _text,
              enabled: !_busy,
              maxLength: 500,
              onChanged: (_) => _retryId = null,
              decoration: const InputDecoration(hintText: 'Bir yorum yaz…'),
            ),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      if (_text.text.trim().isEmpty) return;
                      setState(() => _busy = true);
                      _retryId ??= _comments.doc().id;
                      try {
                        await communityCall('addCommunityComment', {
                          'postId': widget.postId,
                          'commentId': _retryId,
                          'text': _text.text.trim(),
                        });
                        _text.clear();
                        _retryId = null;
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(communityError(e))),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(_busy ? 'Gönderiliyor…' : 'Yorumu gönder'),
            ),
          ],
        ),
      ),
    ),
  );
}

class CommunitySupport extends StatefulWidget {
  const CommunitySupport({super.key, required this.postId});
  final String postId;
  @override
  State<CommunitySupport> createState() => _CommunitySupportState();
}

class _CommunitySupportState extends State<CommunitySupport> {
  int _amount = 3;
  bool _busy = false, _attempted = false;
  String? _error;
  final _requestId = FirebaseFirestore.instance
      .collection('transactions')
      .doc()
      .id;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('İçerik sahibini destekle'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Seçtiğin token bakiyenden düşer ve doğrudan paylaşım sahibine aktarılır.',
        ),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (_, s) => Text(
            'Kullanılabilir: ${s.data?.data()?['credits'] ?? '…'} token',
          ),
        ),
        Wrap(
          spacing: 8,
          children: [1, 3, 5]
              .map(
                (n) => ChoiceChip(
                  label: Text('$n token'),
                  selected: _amount == n,
                  onSelected: _attempted
                      ? null
                      : (_) => setState(() => _amount = n),
                ),
              )
              .toList(),
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: CoetusPalette.red)),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        onPressed: _busy
            ? null
            : () async {
                setState(() {
                  _busy = true;
                  _attempted = true;
                  _error = null;
                });
                try {
                  await communityCall('supportCommunityPost', {
                    'postId': widget.postId,
                    'requestId': _requestId,
                    'amount': _amount,
                  });
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) setState(() => _error = communityError(e));
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
        child: Text(_busy ? 'Gönderiliyor…' : '$_amount token gönder'),
      ),
    ],
  );
}

class CommunityComposer extends StatefulWidget {
  const CommunityComposer({super.key});
  @override
  State<CommunityComposer> createState() => _CommunityComposerState();
}

class _CommunityComposerState extends State<CommunityComposer> {
  final _caption = TextEditingController();
  late final _postId = FirebaseFirestore.instance
      .collection('communityPosts')
      .doc()
      .id;
  late final _skills = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('teachSkills')
      .get();
  String? _skillId, _path, _error;
  XFile? _file;
  bool _video = false, _busy = false, _attempted = false;
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(bool video) async {
    try {
      final picker = ImagePicker();
      final file = video
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery);
      if (file != null && mounted) {
        setState(() {
          _file = file;
          _video = video;
          _path = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Medya seçilemedi. Galeri iznini kontrol et.');
      }
    }
  }

  Future<void> _publish() async {
    if (_skillId == null || _caption.text.trim().isEmpty) {
      setState(() => _error = 'Bir yetenek seç ve paylaşımını yaz.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = _file;
      if (file != null && _path == null) {
        final bytes = await file.readAsBytes();
        if (bytes.length > (_video ? 50 : 10) * 1024 * 1024) {
          throw FirebaseFunctionsException(
            code: 'invalid-argument',
            message: 'Fotoğraf en fazla 10 MB, video 50 MB olabilir.',
          );
        }
        final ext = file.name.split('.').last.toLowerCase();
        final types = {
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'webp': 'image/webp',
          'mp4': 'video/mp4',
          'mov': 'video/quicktime',
          'webm': 'video/webm',
        };
        final type = types[ext];
        if (type == null) {
          throw FirebaseFunctionsException(
            code: 'invalid-argument',
            message: 'JPG, PNG, WebP, MP4, MOV veya WebM seç.',
          );
        }
        final path =
            'communityMedia/${FirebaseAuth.instance.currentUser!.uid}/$_postId/media.$ext';
        await FirebaseStorage.instance
            .ref(path)
            .putData(bytes, SettableMetadata(contentType: type));
        _path = path;
      }
      _attempted = true;
      await communityCall('publishCommunityPost', {
        'postId': _postId,
        'skillId': _skillId,
        'caption': _caption.text.trim(),
        if (_path != null) 'mediaPath': _path,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Toplulukta paylaş')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Öğrendiğin, öğrettiğin veya ürettiğin bir şeyi paylaş. Bu içerik toplulukta görünür; doğrulama kanıtların otomatik paylaşılmaz.',
          ),
          const SizedBox(height: 20),
          FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: _skills,
            builder: (context, s) {
              if (s.hasError) {
                return const Text(
                  'Yeteneklerin yüklenemedi. Sayfayı yeniden aç.',
                );
              }
              if (!s.hasData) return const LinearProgressIndicator();
              if (s.data!.docs.isEmpty) {
                return const Text(
                  'Paylaşmak için önce profiline öğretebileceğin bir yetenek ekle.',
                );
              }
              return DropdownButtonFormField<String>(
                initialValue: _skillId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'İlgili yetenek'),
                items: s.data!.docs
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.data()['name'] as String? ?? 'Yetenek'),
                      ),
                    )
                    .toList(),
                onChanged: _busy || _attempted
                    ? null
                    : (v) => setState(() => _skillId = v),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            enabled: !_busy && !_attempted,
            maxLength: 2000,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Neler öğrendin, neler ürettin?',
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy || _attempted ? null : () => _pick(false),
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Fotoğraf'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _attempted ? null : () => _pick(true),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Video'),
              ),
            ],
          ),
          if (_file != null)
            ListTile(
              leading: Icon(_video ? Icons.videocam : Icons.photo),
              title: Text(_file!.name),
              trailing: IconButton(
                onPressed: _busy || _attempted
                    ? null
                    : () => setState(() {
                        _file = null;
                        _path = null;
                      }),
                icon: const Icon(Icons.close),
              ),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: CoetusPalette.red)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _publish,
            style: FilledButton.styleFrom(
              backgroundColor: CoetusPalette.lime,
              foregroundColor: CoetusPalette.purple,
            ),
            child: Text(_busy ? 'Paylaşılıyor…' : 'Ücretsiz paylaş'),
          ),
        ],
      ),
    ),
  );
}

class CommunityPostPage extends StatelessWidget {
  const CommunityPostPage({super.key, required this.postId});
  final String postId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Topluluk paylaşımı')),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communityPosts')
          .doc(postId)
          .snapshots(),
      builder: (context, s) {
        if (s.hasError) {
          return const Center(child: Text('Paylaşım yüklenemedi.'));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (!s.data!.exists || s.data!.data()?['status'] != 'published') {
          return const Center(child: Text('Bu paylaşım artık yayında değil.'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: CommunityPost(
            postId: postId,
            data: s.data!.data()!,
            onLearn: () => context.go(
              Uri(
                path: '/matching',
                queryParameters: {
                  'author': s.data!.data()!['authorId'] as String,
                  'skill': s.data!.data()!['skillId'] as String,
                  'learn': '1',
                },
              ).toString(),
            ),
            onProfile: () => context.go(
              Uri(
                path: '/matching',
                queryParameters: {
                  'author': s.data!.data()!['authorId'] as String,
                  'skill': s.data!.data()!['skillId'] as String,
                },
              ).toString(),
            ),
          ),
        );
      },
    ),
  );
}
