import 'skill_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'interest_catalog_panel.dart';
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
  Future<void> _configureSharing(BuildContext context, String key) async {
    final choice = selection.skills[key];
    if (choice == null) return;
    final result = await showDialog<SkillEditorResult>(
      context: context,
      builder: (_) => SkillEditorDialog(
        initialName: choice.name,
        initialLevel: choice.level,
        editableName: false,
        title: 'Becerini paylaş',
      ),
    );
    if (!context.mounted || result == null || selection.skills[key] != choice) {
      return;
    }
    choice.teach = true;
    choice.level = result.level;
    onChanged();
  }

  @override
  Widget build(BuildContext context) => InterestCatalogPanel(
    enabled: enabled,
    builder: (branches) => Column(
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
        for (var row = 0; row < branches.length; row += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < 2; column++) ...[
                if (column > 0) const SizedBox(width: 14),
                Expanded(
                  child: row + column < branches.length
                      ? _InterestBranchCard(
                          branch: branches[row + column],
                          selected: selection.branches.contains(
                            branches[row + column].id,
                          ),
                          onTap: enabled
                              ? () {
                                  selection.toggleBranch(
                                    branches[row + column].id,
                                  );
                                  onChanged();
                                }
                              : null,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
          for (final branch in branches.skip(row).take(2))
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
                                            branchId: branch.id,
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
          const SizedBox(height: 14),
        ],
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
                            if (v == true) {
                              _configureSharing(context, entry.key);
                            } else {
                              entry.value.teach = false;
                              onChanged();
                            }
                          }
                        : null,
                  ),
                  if (entry.value.teach)
                    OutlinedButton.icon(
                      onPressed: enabled
                          ? () => _configureSharing(context, entry.key)
                          : null,
                      icon: const Icon(Icons.tune_rounded),
                      label: Text('Seviye ${entry.value.level}/7 · Düzenle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CoetusPalette.purple,
                      ),
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
    ),
  );
}

class _InterestBranchCard extends StatelessWidget {
  const _InterestBranchCard({
    required this.branch,
    required this.selected,
    required this.onTap,
  });
  final InterestBranch branch;
  final bool selected;
  final VoidCallback? onTap;

  IconData get icon => switch (branch.id) {
    'music' => Icons.music_note_outlined,
    'software' => Icons.code,
    'anime' => Icons.auto_awesome,
    'books' => Icons.menu_book_outlined,
    'film' => Icons.movie_outlined,
    'psychology' => Icons.psychology_outlined,
    'design' => Icons.brush_outlined,
    'languages' => Icons.public,
    'movement' => Icons.sports_gymnastics,
    'kitchen' => Icons.restaurant_outlined,
    'animal_care' => Icons.pets,
    'history' => Icons.account_balance_outlined,
    'strategy_games' || 'video_games' => Icons.sports_esports_outlined,
    'travel' => Icons.flight_outlined,
    'nature' => Icons.forest_outlined,
    'camping' => Icons.terrain_outlined,
    'gardening' => Icons.local_florist_outlined,
    'diy' || 'crafts' => Icons.handyman_outlined,
    'content_creation' => Icons.video_camera_front_outlined,
    'photography' => Icons.photo_camera_outlined,
    'finance' => Icons.savings_outlined,
    _ => Icons.interests_outlined,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      key: ValueKey('interest-branch-${branch.id}'),
      color: selected ? CoetusPalette.purple : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 152),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? CoetusPalette.lime : CoetusPalette.purple,
                    size: 28,
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: selected
                        ? CoetusPalette.cream
                        : CoetusPalette.purple,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                branch.label,
                style: TextStyle(
                  color: selected ? CoetusPalette.cream : CoetusPalette.purple,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
