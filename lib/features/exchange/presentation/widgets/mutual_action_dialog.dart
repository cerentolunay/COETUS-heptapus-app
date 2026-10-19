import 'package:flutter/material.dart';
import '../../domain/mutual_exchange.dart';

class MutualActionDialog extends StatefulWidget {
  const MutualActionDialog({super.key, required this.action});
  final MutualAction action;
  @override
  State<MutualActionDialog> createState() => _MutualActionDialogState();
}

class _MutualActionDialogState extends State<MutualActionDialog> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return AlertDialog(
      title: Text(
        action == MutualAction.dispute
            ? 'Takas tamamlanmadı'
            : action == MutualAction.cancel
            ? 'İptali onayla'
            : action == MutualAction.expire
            ? 'Yanıt süresini kontrol et'
            : 'Tamamlanmayı onayla',
      ),
      content: SingleChildScrollView(
        child: action == MutualAction.dispute
            ? Form(
                key: _form,
                child: TextFormField(
                  controller: _reason,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  validator: (v) => (v?.trim().length ?? 0) < 10
                      ? 'En az 10 karakterle açıkla.'
                      : null,
                  decoration: const InputDecoration(
                    hintText: 'Neden tamamlanmadığını açıkla.',
                  ),
                ),
              )
            : Text(
                action == MutualAction.expire
                    ? 'Sunucu 72 saatin dolduğunu ve itiraz olmadığını doğrularsa herkesin katkısı kendisine iade edilir.'
                    : action == MutualAction.cancel
                    ? 'İkiniz de iptali onaylayınca herkes kendi katkısını geri alır. İlk onay tek başına iade yapmaz.'
                    : 'İkiniz de hem öğretiyor hem öğreniyorsunuz. İkinci onayda herkesin kendi katkısı geri döner. İlk onay 72 saatlik yanıt süresini başlatır.',
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            if (action != MutualAction.dispute ||
                _form.currentState!.validate()) {
              Navigator.pop(context, _reason.text.trim());
            }
          },
          child: const Text('Onayla'),
        ),
      ],
    );
  }
}
