import 'package:flutter/material.dart';
import '../../../../app/theme/coetus_tokens.dart';
import '../../domain/onboarding/interest_catalog.dart';
import '../../../../core/text/skill_normalization.dart';

class InterestTree extends StatelessWidget {
  const InterestTree({
    super.key,
    required this.selection,
    required this.onChanged,
    this.enabled = true,
  });
  final InterestSelection selection;
  final VoidCallback onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'İlgi alanlarını keşfet',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: CoetusPalette.purple,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Birden fazla alan seçebilirsin. Dalları aç, ilgini çeken becerileri işaretle; öğrenmek mi paylaşmak mı istediğini belirt.',
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final branch in interestBranches)
            FilterChip(
              label: Text(branch.label),
              selected: selection.branches.contains(branch.id),
              selectedColor: CoetusPalette.lime,
              onSelected: enabled
                  ? (_) {
                      selection.toggleBranch(branch.id);
                      onChanged();
                    }
                  : null,
            ),
        ],
      ),
      for (final branch in interestBranches)
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.topCenter,
          child: selection.branches.contains(branch.id)
              ? Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CoetusPalette.purple,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_tree_outlined,
                            color: CoetusPalette.lime,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              branch.label,
                              style: const TextStyle(
                                color: CoetusPalette.cream,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final skill in branch.skills)
                            FilterChip(
                              label: Text(skill),
                              selected: selection.skills.containsKey(
                                skillKey(skill),
                              ),
                              selectedColor: CoetusPalette.lime,
                              onSelected: enabled
                                  ? (_) {
                                      selection.toggleSkill(
                                        skill,
                                        branch.label,
                                      );
                                      onChanged();
                                    }
                                  : null,
                            ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      if (selection.skills.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            'Seçtiğin beceriler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      for (final entry in selection.skills.entries)
        Card(
          key: ValueKey('choice-${entry.key}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Beceriyi kaldır',
                      onPressed: enabled
                          ? () {
                              selection.skills.remove(entry.key);
                              onChanged();
                            }
                          : null,
                      icon: const Icon(Icons.close, color: CoetusPalette.red),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Öğrenmek istiyorum'),
                  value: entry.value.learn,
                  onChanged: enabled
                      ? (v) {
                          entry.value.learn = v!;
                          onChanged();
                        }
                      : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bu beceriyi paylaşabilirim'),
                  value: entry.value.teach,
                  onChanged: enabled
                      ? (v) {
                          entry.value.teach = v!;
                          onChanged();
                        }
                      : null,
                ),
                if (entry.value.teach)
                  DropdownButtonFormField<int>(
                    initialValue: entry.value.level,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bu becerideki seviyen',
                    ),
                    items: [
                      for (var n = 1; n <= 7; n++)
                        DropdownMenuItem(
                          value: n,
                          child: Text(
                            'Seviye $n${n == 1
                                ? ' · Başlangıç'
                                : n == 7
                                ? ' · İleri'
                                : ''}',
                          ),
                        ),
                    ],
                    onChanged: enabled
                        ? (n) {
                            entry.value.level = n!;
                            onChanged();
                          }
                        : null,
                  ),
                if (!entry.value.learn && !entry.value.teach)
                  const Text(
                    'Kaydetmek için en az bir amaç seç veya beceriyi kaldır.',
                    style: TextStyle(color: CoetusPalette.red),
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 16),
      const Text(
        'Bu adım isteğe bağlı. Seçim yapmadan da profilini tamamlayabilir, becerilerini daha sonra ekleyebilirsin.',
      ),
    ],
  );
}
