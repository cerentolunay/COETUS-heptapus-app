import 'package:flutter/material.dart';
import '../app/theme/coetus_tokens.dart';

class CoetusDeleteDialog extends StatefulWidget {
  const CoetusDeleteDialog({
    super.key,
    required this.name,
    required this.onDelete,
  });
  final String name;
  final Future<void> Function() onDelete;
  @override
  State<CoetusDeleteDialog> createState() => _CoetusDeleteDialogState();
}

class _CoetusDeleteDialogState extends State<CoetusDeleteDialog> {
  bool _busy = false;
  String? _error;
  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Silinemedi. Bağlantını kontrol edip yeniden dene.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      backgroundColor: CoetusPalette.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      icon: const CircleAvatar(
        radius: 28,
        backgroundColor: CoetusPalette.redSoft,
        child: Icon(
          Icons.delete_outline_rounded,
          color: CoetusPalette.purple,
          size: 30,
        ),
      ),
      title: const Text('Bu yeteneği silelim mi?', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '“${widget.name}” profilinden kaldırılacak. Bu işlem geri alınamaz.',
            textAlign: TextAlign.center,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: CoetusColors.danger),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _delete,
          style: ElevatedButton.styleFrom(
            backgroundColor: CoetusPalette.red,
            foregroundColor: CoetusPalette.onRed,
            minimumSize: const Size(100, 48),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: Text(_busy ? 'Siliniyor…' : 'Evet, sil'),
        ),
      ],
    ),
  );
}
