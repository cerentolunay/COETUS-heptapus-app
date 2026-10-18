import 'package:coetus/preview/preview_mode.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/coetus_tokens.dart';
import '../../data/services/account_deletion_service.dart';

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({super.key, this.enabled = true});
  final bool enabled;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: TextButton.icon(
      onPressed: !enabled
          ? null
          : () async {
              try {
                if (PreviewMode.enabled) {
                  await showDialog<AccountDeletionResult>(
                    context: context,
                    builder: (_) => DeleteAccountDialog(
                      requiresPassword: true,
                      onDelete: (_) async => throw StateError(
                        'Bu bir önizleme. Gerçek hesap silinmez.',
                      ),
                    ),
                  );
                  return;
                }
                final service = AccountDeletionService();
                final messenger = ScaffoldMessenger.of(context);
                await showDialog<AccountDeletionResult>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => DeleteAccountDialog(
                    requiresPassword: service.requiresPassword,
                    google: service.usesGoogle,
                    onDelete: (password) async {
                      final result = await service.delete(password);
                      if (messenger.mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              result.pendingCleanup
                                  ? 'Hesabın kapatıldı. Veri temizliği arka planda tamamlanıyor.'
                                  : 'Hesabın silindi.',
                            ),
                          ),
                        );
                      }
                      return result;
                    },
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(accountDeletionError(e))),
                  );
                }
              }
            },
      icon: const Icon(Icons.person_remove_outlined),
      label: const Text('Hesabını sil'),
      style: TextButton.styleFrom(
        foregroundColor: CoetusPalette.onRed,
        backgroundColor: CoetusPalette.redSoft,
      ),
    ),
  );
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({
    super.key,
    required this.onDelete,
    this.requiresPassword = false,
    this.google = false,
  });
  final Future<AccountDeletionResult> Function(String password) onDelete;
  final bool requiresPassword, google;
  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _agreed = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy || !_agreed) return;
    if (widget.requiresPassword && _password.text.isEmpty) {
      setState(() => _error = 'Devam etmek için şifreni yaz.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onDelete(_password.text);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) setState(() => _error = accountDeletionError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      backgroundColor: CoetusPalette.cream,
      scrollable: true,
      icon: const Icon(
        Icons.person_remove_outlined,
        color: CoetusPalette.onRed,
        size: 36,
      ),
      title: const Text('Hesabını kalıcı olarak sil?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Profilin, paylaşımların, çalışma örneklerin ve kişisel medyan silinir. Kalan tokenların kaybolur. Bu işlem geri alınamaz.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Kilitli token bulunan oturumlarını önce sonuçlandırmalısın. Diğer kişilerdeki işlem geçmişi, kimlik bilgilerin kaldırılarak kalabilir.',
          ),
          if (widget.requiresPassword) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Hesap şifren',
                hintText: 'Kimliğini doğrulamak için şifreni yaz.',
              ),
            ),
          ],
          if (widget.google)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Devam ettiğinde aynı Google hesabınla yeniden doğrulama istenecek.',
              ),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreed,
            onChanged: _busy
                ? null
                : (v) => setState(() => _agreed = v ?? false),
            title: const Text(
              'Hesabımın kalıcı silineceğini ve tokenlarımı kaybedeceğimi anlıyorum.',
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: CoetusPalette.onRed)),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _busy || !_agreed ? null : _delete,
          style: FilledButton.styleFrom(
            backgroundColor: CoetusPalette.red,
            foregroundColor: CoetusPalette.onRed,
          ),
          child: Text(_busy ? 'Hesabın siliniyor…' : 'Evet, hesabımı sil'),
        ),
      ],
    ),
  );
}
