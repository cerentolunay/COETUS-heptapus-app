import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/coetus_tokens.dart';
import '../../../../widgets/coetus_mascot.dart';
import '../../domain/services/profile_completion_service.dart';
import '../../domain/services/profile_location_service.dart';
import '../../domain/onboarding/interest_catalog.dart';
import '../../domain/onboarding/profile_setup_data.dart';
import '../widgets/interest_tree.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({
    super.key,
    this.onSubmit,
    this.initialName,
    this.locateCity,
    this.onCompleted,
  });
  final Future<void> Function(ProfileSetupData)? onSubmit;
  final Future<String> Function()? locateCity;
  final VoidCallback? onCompleted;
  final String? initialName;
  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _bio = TextEditingController(),
      _location = TextEditingController(),
      _photo = TextEditingController();
  final _selection = InterestSelection();
  bool _busy = false, _locating = false, _settings = false;
  int _step = 0;
  String? _error, _locationMessage;
  @override
  void initState() {
    super.initState();
    _name.text =
        widget.initialName ??
        (Firebase.apps.isNotEmpty
            ? FirebaseAuth.instance.currentUser?.displayName
            : null) ??
        '';
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _location.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationMessage = null;
      _settings = false;
    });
    try {
      final city =
          await (widget.locateCity?.call() ??
              ProfileLocationService().locateCity());
      if (mounted) _location.text = city;
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationMessage = e is LocationFailure
              ? e.message
              : 'Şehir belirlenemedi. Şehrini elle yazabilir veya boş bırakabilirsin.';
          _settings = e is LocationFailure && e.settings;
        });
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_selection.skills.values.any((s) => !s.learn && !s.teach)) {
      setState(
        () => _error =
            'Seçtiğin her beceri için bir amaç seç veya beceriyi kaldır.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final data = ProfileSetupData(
      displayName: _name.text.trim(),
      bio: _bio.text.trim(),
      location: _location.text.trim(),
      photoUrl: _photo.text.trim(),
      interests: _selection.selectedInterestIds,
      skills: _selection.selectedSkills,
    );
    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(data);
      } else {
        await ProfileCompletionService().completeProfile(
          displayName: data.displayName,
          bio: data.bio,
          location: data.location,
          photoUrl: data.photoUrl,
          interests: data.interests,
          skills: data.skills,
        );
      }
      if (!mounted) return;
      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Profil kaydedilemedi. Bilgilerin korunuyor; bağlantını kontrol edip yeniden dene.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CoetusPalette.cream,
    appBar: AppBar(
      title: Text('Profilini tamamla · ${_step + 1}/2'),
      automaticallyImplyLeading: false,
      leading: _step == 1
          ? IconButton(
              tooltip: 'Temel bilgilere dön',
              onPressed: _busy ? null : () => setState(() => _step = 0),
              icon: const Icon(Icons.arrow_back),
            )
          : null,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: CoetusMascot(size: 100, interactive: false)),
            const SizedBox(height: 16),
            if (_step == 0)
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Seni tanıyalım',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Yalnızca görünen adın gerekli. Diğer bilgileri daha sonra da ekleyebilirsin.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      enabled: !_busy,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Görünen ad',
                        hintText: 'Sana nasıl hitap edelim?',
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? 'En az 2 karakterlik bir görünen ad yaz.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bio,
                      enabled: !_busy,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Hakkında (isteğe bağlı)',
                        hintText: 'İlgilendiğin şeylerden bahsedebilirsin.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _location,
                      enabled: !_busy && !_locating,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Şehir (isteğe bağlı)',
                        hintText:
                            'Şehrini yazabilir veya konum izni verebilirsin.',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _locating || _busy ? null : _locate,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        _locating ? 'Şehir bulunuyor…' : 'Konumumdan şehri bul',
                      ),
                    ),
                    const Text(
                      'Yalnızca bu butona bastığında konum izni istenir. Profile sadece şehir/ülke kaydedilir; canlı konum paylaşılmaz.',
                      style: TextStyle(fontSize: 12),
                    ),
                    if (_locationMessage != null) Text(_locationMessage!),
                    if (_settings)
                      TextButton(
                        onPressed: Geolocator.openAppSettings,
                        child: const Text('Uygulama ayarlarını aç'),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _photo,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Profil fotoğrafı bağlantısı (isteğe bağlı)',
                        hintText: 'https://',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final uri = Uri.tryParse(v.trim());
                        return uri != null &&
                                uri.scheme == 'https' &&
                                uri.host.isNotEmpty
                            ? null
                            : 'Geçerli bir HTTPS bağlantısı yaz veya boş bırak.';
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (_form.currentState!.validate()) {
                          setState(() => _step = 1);
                        }
                      },
                      child: const Text('İlgi alanlarına devam et'),
                    ),
                  ],
                ),
              )
            else ...[
              InterestTree(
                selection: _selection,
                enabled: !_busy,
                onChanged: () => setState(() => _error = null),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: CoetusPalette.lime,
                  foregroundColor: CoetusPalette.purple,
                ),
                child: Text(_busy ? 'Kaydediliyor…' : 'Profilimi tamamla'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: CoetusPalette.red),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
