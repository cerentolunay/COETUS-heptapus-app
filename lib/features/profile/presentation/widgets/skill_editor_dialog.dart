import 'package:flutter/material.dart';
import '../../../../app/theme/coetus_tokens.dart';

class SkillEditorResult {
  const SkillEditorResult(this.name, this.level);
  final String name;
  final int level;
}

/// Shared by profile skill editors and interest selection. Cancel never saves.
class SkillEditorDialog extends StatefulWidget {
  const SkillEditorDialog({
    super.key,
    this.initialName = '',
    this.initialLevel = 1,
    this.editableName = true,
    this.title = 'Beceri ekle',
    this.confirmLabel = 'Kaydet',
  });
  final String initialName, title, confirmLabel;
  final int initialLevel;
  final bool editableName;
  @override
  State<SkillEditorDialog> createState() => _SkillEditorDialogState();
}

class _SkillEditorDialogState extends State<SkillEditorDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late double _level = widget.initialLevel.clamp(1, 7).toDouble();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: CoetusPalette.purple,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    scrollable: true,
    title: Text(
      widget.title,
      style: const TextStyle(
        color: CoetusPalette.cream,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            readOnly: !widget.editableName,
            maxLength: 80,
            style: const TextStyle(color: CoetusPalette.cream),
            cursorColor: CoetusPalette.lime,
            decoration: InputDecoration(
              labelText: 'Beceri adı',
              labelStyle: const TextStyle(color: CoetusPalette.lime),
              counterStyle: const TextStyle(color: CoetusPalette.cream),
              fillColor: CoetusPalette.purple,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: CoetusPalette.cream.withValues(alpha: .3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: CoetusPalette.lime,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: CoetusPalette.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: CoetusPalette.red),
              ),
              errorStyle: const TextStyle(color: CoetusPalette.red),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Beceri adını yaz.'
                : null,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bu becerideki seviyen',
                  style: TextStyle(
                    color: CoetusPalette.cream,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_level.round()}/7',
                style: const TextStyle(
                  color: CoetusPalette.lime,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: CoetusPalette.lime,
              inactiveTrackColor: CoetusPalette.cream.withValues(alpha: .2),
              thumbColor: CoetusPalette.lime,
              overlayColor: CoetusPalette.lime.withValues(alpha: .15),
              activeTickMarkColor: CoetusPalette.purple,
              inactiveTickMarkColor: CoetusPalette.cream,
              valueIndicatorColor: CoetusPalette.lime,
              valueIndicatorTextStyle: const TextStyle(
                color: CoetusPalette.purple,
              ),
            ),
            child: Slider(
              value: _level,
              min: 1,
              max: 7,
              divisions: 6,
              label: '${_level.round()}/7',
              semanticFormatterCallback: (value) =>
                  'Seviye ${value.round()}, 7 üzerinden',
              onChanged: (value) => setState(() => _level = value),
            ),
          ),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Başlangıç',
                  style: TextStyle(color: CoetusPalette.cream, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'İleri',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: CoetusPalette.cream, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(foregroundColor: CoetusPalette.cream),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: CoetusPalette.lime,
          foregroundColor: CoetusPalette.purple,
        ),
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              SkillEditorResult(_name.text.trim(), _level.round()),
            );
          }
        },
        child: Text(widget.confirmLabel),
      ),
    ],
  );
}
