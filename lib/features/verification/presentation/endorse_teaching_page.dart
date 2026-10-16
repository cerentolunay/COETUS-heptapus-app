import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import '../data/verification_service.dart';

class EndorseTeachingPage extends StatefulWidget {
  const EndorseTeachingPage({
    super.key,
    required this.teacherId,
    this.sessionId,
  });
  final String teacherId;
  final String? sessionId;
  @override
  State<EndorseTeachingPage> createState() => _EndorseTeachingPageState();
}

class _EndorseTeachingPageState extends State<EndorseTeachingPage> {
  final _comment = TextEditingController();
  late final _sessions = FirebaseFirestore.instance
      .collection('sessions')
      .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get();
  String? _selected, _error;
  bool _sending = false;
  @override
  void initState() {
    super.initState();
    _selected = widget.sessionId;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send(Map<String, dynamic> session, String id) async {
    if (_comment.text.trim().length < 10) {
      setState(() => _error = 'Öğrenme deneyimini en az 10 karakterle anlat.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await VerificationService().endorse(
        sessionId: id,
        teacherId: widget.teacherId,
        skillName: (session['skill'] ?? session['skillName']) as String,
        comment: _comment.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eşleştiğin kişiyi onayladın. Teşekkürler!'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = verificationError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bu kişi bana öğretti')),
    body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _sessions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(verificationError(snapshot.error!)),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data!.docs
            .where(
              (s) =>
                  s.data()['teacherId'] == widget.teacherId &&
                  ['completed'].contains(s.data()['status']),
            )
            .toList();
        if (sessions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Bu kişiden öğrendiğin bir takas henüz bulunmuyor. Birlikte öğrenme oturumunuz tamamlandıktan sonra onay verebilirsin.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final selected =
            sessions.where((s) => s.id == _selected).firstOrNull ??
            sessions.first;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.favorite_rounded,
              size: 48,
              color: CoetusPalette.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Öğrendiklerine kefil ol.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Yalnızca gerçekten öğrendiğin yeteneği onayla. Yorumun eşleştiğin kişinin profilinde görünür. Aynı kişiye aynı yetenek için bir kez onay verebilirsin.',
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: selected.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Öğrendiğin yetenek',
              ),
              items: sessions
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        (s.data()['skill'] ??
                                s.data()['skillName'] ??
                                'Takas oturumu')
                            as String,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _sending ? null : (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              enabled: !_sending,
              minLines: 4,
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Deneyimini anlat',
                hintText: 'Ne öğrendin? Bu kişi sana nasıl yardımcı oldu?',
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: CoetusColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _sending
                  ? null
                  : () => _send(selected.data(), selected.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: CoetusPalette.red,
                foregroundColor: CoetusPalette.onRed,
              ),
              icon: const Icon(Icons.favorite_rounded),
              label: Text(
                _sending ? 'Onaylanıyor…' : 'Evet, bu kişi bana öğretti',
              ),
            ),
          ],
        );
      },
    ),
  );
}
