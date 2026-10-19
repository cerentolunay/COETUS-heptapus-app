import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../../core/text/skill_normalization.dart';
import '../../../../preview/preview_mode.dart';
import '../../domain/onboarding/interest_catalog.dart';

/// Shared live catalog. Preview never contacts production Firebase.
class InterestCatalogPanel extends StatefulWidget {
  const InterestCatalogPanel({
    super.key,
    required this.builder,
    this.enabled = true,
  });
  final Widget Function(List<InterestBranch>) builder;
  final bool enabled;
  @override
  State<InterestCatalogPanel> createState() => _InterestCatalogPanelState();
}

class _InterestCatalogPanelState extends State<InterestCatalogPanel> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _approved;
  bool _moderator = false;
  @override
  void initState() {
    super.initState();
    if (!PreviewMode.enabled &&
        Firebase.apps.isNotEmpty &&
        FirebaseAuth.instance.currentUser != null) {
      _approved = FirebaseFirestore.instance
          .collection('interestSuggestions')
          .where('status', isEqualTo: 'approved')
          .snapshots();
      _loadRole();
    }
  }

  Future<void> _loadRole() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
      if (mounted) {
        setState(
          () => _moderator = token?.claims?['interestModerator'] == true,
        );
      }
    } catch (_) {
      /* Catalog remains usable without moderator controls. */
    }
  }

  Future<void> _suggest(List<InterestBranch> branches) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _SuggestionDialog(),
    );
    if (name == null || !mounted) return;
    if (branches.any((b) => normalizeText(b.label) == normalizeText(name))) {
      _message('Bu ilgi alanı zaten listede.');
      return;
    }
    if (PreviewMode.enabled || Firebase.apps.isEmpty) {
      _message(
        'Önizlemede öneri gönderilmez. Gerçek hesabınla giriş yapmalısın.',
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _message('Öneri göndermek için giriş yapmalısın.');
      return;
    }
    // Same user/name always has the same ID, preventing repeated submissions.
    final key = Uri.encodeComponent(normalizeText(name));
    try {
      await FirebaseFirestore.instance
          .collection('interestSuggestions')
          .doc('${uid}_$key')
          .set({
            'name': name,
            'ownerId': uid,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
      _message('Önerin gönderildi. Onaylandıktan sonra herkes görebilecek.');
    } catch (_) {
      _message(
        'Öneri gönderilemedi. Daha önce göndermiş olabilirsin; bağlantını kontrol et.',
      );
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _approved,
    builder: (context, snapshot) {
      final branches = [...interestBranches];
      for (final doc
          in snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
        final name = doc.data()['name'] as String;
        if (!branches.any(
          (b) => normalizeText(b.label) == normalizeText(name),
        )) {
          branches.add(InterestBranch('community_${doc.id}', name, [name]));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: widget.enabled ? () => _suggest(branches) : null,
                icon: const Icon(Icons.add),
                label: const Text('Ekle'),
              ),
              if (_moderator)
                TextButton.icon(
                  onPressed: widget.enabled
                      ? () => showDialog<void>(
                          context: context,
                          builder: (_) => const _ModerationDialog(),
                        )
                      : null,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Önerileri incele'),
                ),
            ],
          ),
          const Text(
            'Aradığın alan yok mu? Öner; onaylandıktan sonra listeye eklensin.',
          ),
          if (snapshot.hasError)
            const Text('Topluluk alanları yüklenemedi. Bağlantını kontrol et.'),
          const SizedBox(height: 12),
          widget.builder(branches),
        ],
      );
    },
  );
}

class _SuggestionDialog extends StatefulWidget {
  const _SuggestionDialog();
  @override
  State<_SuggestionDialog> createState() => _SuggestionDialogState();
}

class _SuggestionDialogState extends State<_SuggestionDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('İlgi alanı öner'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        decoration: const InputDecoration(
          labelText: 'İlgi alanı',
          hintText: 'Örneğin: Astronomi',
        ),
        validator: (v) =>
            (v?.trim().length ?? 0) < 2 ? 'En az 2 karakter yaz.' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: const Text('Öneriyi gönder'),
      ),
    ],
  );
}

class _ModerationDialog extends StatefulWidget {
  const _ModerationDialog();
  @override
  State<_ModerationDialog> createState() => _ModerationDialogState();
}

class _ModerationDialogState extends State<_ModerationDialog> {
  late final _pending = FirebaseFirestore.instance
      .collection('interestSuggestions')
      .where('status', isEqualTo: 'pending')
      .snapshots();
  final Set<String> _busy = {};
  String? _error;
  Future<void> _review(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool approve,
  ) async {
    setState(() {
      _busy.add(doc.id);
      _error = null;
    });
    try {
      await doc.reference.update({
        'status': approve ? 'approved' : 'rejected',
        'reviewedBy': FirebaseAuth.instance.currentUser!.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'İşlem kaydedilemedi. Yetkini ve bağlantını kontrol et.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(doc.id));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('İlgi alanı önerileri'),
    content: SizedBox(
      width: 480,
      height: 400,
      child: Column(
        children: [
          if (_error != null) Text(_error!),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _pending,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Öneriler yüklenemedi. Yetkini ve bağlantını kontrol et.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Bekleyen öneri yok.'));
                }
                return ListView(
                  children: [
                    for (final doc in snapshot.data!.docs)
                      ListTile(
                        title: Text(doc.data()['name'] as String),
                        subtitle: Wrap(
                          children: [
                            TextButton(
                              onPressed: _busy.contains(doc.id)
                                  ? null
                                  : () => _review(doc, true),
                              child: const Text('Onayla'),
                            ),
                            TextButton(
                              onPressed: _busy.contains(doc.id)
                                  ? null
                                  : () => _review(doc, false),
                              child: const Text('Reddet'),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Kapat'),
      ),
    ],
  );
}
