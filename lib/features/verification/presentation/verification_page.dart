import 'package:coetus/preview/preview_mode.dart';
import 'package:coetus/preview/preview_media.dart';
import 'package:coetus/features/community/community.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/profile/data/repositories/profile_repository_factory.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import '../data/verification_service.dart';
import '../domain/skill_verification.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key, this.skillId});
  final String? skillId;
  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _service = VerificationService();
  late final _history = _service.watch();
  final _description = TextEditingController();
  final _files = <XFile>[];
  List<SkillModel> _skills = [];
  String? _skillId;
  String? _error;
  bool _loading = true, _sending = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileRepositoryFactory.create().loadProfile();
      final lost =
          !PreviewMode.enabled &&
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android
          ? await ImagePicker().retrieveLostData()
          : null;
      if (!mounted) return;
      setState(() {
        _skills = profile.teachSkills;
        _skillId =
            _skills.where((s) => s.id == widget.skillId).firstOrNull?.id ??
            _skills.firstOrNull?.id;
        if (lost?.files != null) {
          _files.addAll(lost!.files!.take(3 - _files.length));
        }
        _loading = false;
        _error = lost?.exception == null
            ? null
            : 'Seçilen dosya kurtarılamadı. Lütfen yeniden seç.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = verificationError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in [
              (Icons.photo_library_outlined, 'Galeriden fotoğraf'),
              (Icons.photo_camera_outlined, 'Fotoğraf çek'),
            ].indexed)
              ListTile(
                leading: Icon(item.$2.$1),
                title: Text(item.$2.$2),
                onTap: () => Navigator.pop(context, item.$1),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      final picker = ImagePicker();
      final source = choice.isOdd ? ImageSource.camera : ImageSource.gallery;
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 90,
      );
      if (file != null && mounted) {
        setState(() {
          if (_files.length < 3) _files.add(file);
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Kamera veya galeri açılamadı. Uygulama izinlerini kontrol et.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_sending || _skillId == null) return;
    setState(() {
      _sending = true;
      _error = null;
      _progress = 0;
    });
    try {
      await _service.submit(
        skillId: _skillId!,
        description: _description.text,
        files: List.of(_files),
        onProgress: (v) {
          if (mounted) setState(() => _progress = v);
        },
      );
      if (!mounted) return;
      setState(() {
        _files.clear();
        _description.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Çalışman portföyüne eklendi. İnceleme beklemeden profilinde görünür.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = verificationError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Çalışmalarım')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CoetusPalette.purple,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: CoetusPalette.lime,
                      size: 36,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Çalışmalarını paylaş.',
                      style: TextStyle(
                        color: CoetusPalette.cream,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Çalışma örneklerini yeteneğinin altına ekleyebilirsin. Fotoğraf tamamen isteğe bağlı; eklemeden de eşleşebilirsin. Yayımladığın çalışmalar giriş yapan kişilerce görülebilir.',
                      style: TextStyle(color: CoetusPalette.cream, height: 1.5),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Çalışma örnekleri en fazla +6 güven katkısı sağlar; token kazandırmaz.',
                      style: TextStyle(
                        color: CoetusPalette.lime,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (_skills.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Çalışma eklemek için önce profiline bir yetenek ekle. Medya yüklemek yetenek eklemenin şartı değildir.',
                    ),
                  ),
                )
              else ...[
                const Text('İlgili yetenek'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _skillId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Yetenek seç',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: _skills
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _skillId = v),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _description,
                  enabled: !_sending,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Çalışmanı anlat',
                    hintText:
                        'Ne yaptın, neler öğrendin? İstersen yalnızca yazıyla anlat.',
                  ),
                ),
                for (final entry in _files.indexed)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.perm_media_outlined),
                      title: Text(
                        entry.$2.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Dosyayı kaldır',
                        color: CoetusPalette.onRed,
                        icon: const Icon(Icons.close),
                        onPressed: _sending
                            ? null
                            : () => setState(() => _files.removeAt(entry.$1)),
                      ),
                    ),
                  ),
                if (_files.length < 3)
                  OutlinedButton.icon(
                    onPressed: _sending ? null : _pick,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Fotoğraf ekle (isteğe bağlı)'),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'En fazla 3 fotoğraf · Fotoğraf başına 10 MB',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (_sending) ...[
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  child: Text(
                    _sending
                        ? 'Yükleniyor · %${(_progress * 100).round()}'
                        : 'Çalışmamı yayımla',
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: CoetusColors.danger),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Çalışmaların',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<SkillVerification>>(
                stream: _history,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(verificationError(snapshot.error!));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Text(
                      'Henüz çalışma örneğin yok. Çalışma eklemek zorunlu değil.',
                    );
                  }
                  return Column(
                    children: snapshot.data!
                        .where(
                          (v) =>
                              v.type == 'portfolio' && v.status == 'published',
                        )
                        .map(
                          (v) => VerificationCard(
                            verification: v,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    EvidenceDetailsPage(verification: v),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
  );
}

class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key, required this.verification, this.onTap});
  final SkillVerification verification;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final v = verification;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        onTap: onTap,
        leading: Icon(
          v.type == 'peer'
              ? Icons.people_alt_outlined
              : Icons.perm_media_outlined,
          color: v.status == 'approved'
              ? CoetusColors.success
              : CoetusPalette.purple,
        ),
        title: Text(
          v.skillName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${v.statusLabel}\n${v.type == 'peer' ? '${v.studentName} tarafından onaylandı' : 'Çalışma örneği · Kimlik veya yetenek doğrulaması değildir'}'
          '${v.reward > 0 ? '\n+${v.reward} token' : ''}${v.reason.isNotEmpty ? '\n${v.reason}' : ''}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _EvidenceMedia extends StatefulWidget {
  const _EvidenceMedia({required this.path});
  final String path;
  @override
  State<_EvidenceMedia> createState() => _EvidenceMediaState();
}

class _EvidenceMediaState extends State<_EvidenceMedia> {
  late final Future<String>? _url = PreviewMode.enabled
      ? null
      : VerificationService().mediaUrl(widget.path);
  @override
  Widget build(BuildContext context) => PreviewMode.enabled
      ? const PreviewMedia()
      : FutureBuilder<String>(
          future: _url,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Fotoğraf açılamadı.');
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Image.network(
              snapshot.data!,
              height: 260,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stack) =>
                  const Text('Fotoğraf açılamadı.'),
            );
          },
        );
}

class VerifiedSkillsPanel extends StatefulWidget {
  const VerifiedSkillsPanel({super.key, required this.ownerId});
  final String ownerId;
  @override
  State<VerifiedSkillsPanel> createState() => _VerifiedSkillsPanelState();
}

class _VerifiedSkillsPanelState extends State<VerifiedSkillsPanel> {
  late final _stream = VerificationService().watch(ownerId: widget.ownerId);
  @override
  Widget build(BuildContext context) => StreamBuilder<List<SkillVerification>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text(verificationError(snapshot.error!));
      final verified = (snapshot.data ?? [])
          .where((v) => v.type == 'portfolio' && v.status == 'published')
          .toList();
      if (verified.isEmpty) {
        return const Text('Henüz çalışma örneği yok.');
      }
      return Column(
        children: [
          ...verified.map(
            (v) => VerificationCard(
              verification: v,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => EvidenceDetailsPage(verification: v),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class EvidenceDetailsPage extends StatelessWidget {
  const EvidenceDetailsPage({super.key, required this.verification});
  final SkillVerification verification;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Çalışma örneği')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        VerificationCard(verification: verification),
        Text(
          verification.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (verification.type == 'portfolio')
          PortfolioEntryActions(entry: verification),
        for (final file in verification.files.where(
          (file) => (file['contentType'] as String? ?? '').startsWith('image/'),
        ))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _EvidenceMedia(path: file['path'] as String),
          ),
      ],
    ),
  );
}

class PortfolioEntryActions extends StatefulWidget {
  const PortfolioEntryActions({super.key, required this.entry});
  final SkillVerification entry;
  @override
  State<PortfolioEntryActions> createState() => _PortfolioEntryActionsState();
}

class _PortfolioEntryActionsState extends State<PortfolioEntryActions> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final own = VerificationService().userId == widget.entry.ownerId;
    return TextButton.icon(
      onPressed: _busy
          ? null
          : () async {
              var reason = '';
              final result = await showDialog<String>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(own ? 'Çalışmayı sil?' : 'Çalışmayı şikâyet et'),
                  content: own
                      ? const Text(
                          'Çalışma profilinden kaldırılır. Varsa bu örneğe bağlı portföy güven katkısı güncellenir.',
                        )
                      : TextField(
                          onChanged: (value) => reason = value,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText:
                                'Uygunsuz veya çalıntı içerik nedenini anlat.',
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(c, own ? 'delete' : reason),
                      child: Text(own ? 'Sil' : 'Şikâyeti gönder'),
                    ),
                  ],
                ),
              );
              if (result == null || !mounted) return;
              setState(() => _busy = true);
              try {
                await communityCall(
                  own ? 'deletePortfolioEntry' : 'reportPortfolioEntry',
                  {'entryId': widget.entry.id, if (!own) 'reason': result},
                );
                if (!context.mounted) return;
                if (own) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şikâyetin kaydedildi.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(verificationError(e))));
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      icon: Icon(
        own ? Icons.delete_outline : Icons.flag_outlined,
        color: CoetusPalette.red,
      ),
      label: Text(own ? 'Çalışmayı sil' : 'Şikâyet et'),
    );
  }
}
