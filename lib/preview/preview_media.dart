import 'package:flutter/material.dart';
import '../app/theme/coetus_tokens.dart';
import '../widgets/coetus_mascot.dart';

/// A local illustration, explicitly not a downloaded photo or playable video.
class PreviewMedia extends StatelessWidget {
  const PreviewMedia({super.key, this.video = false});
  final bool video;
  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    width: double.infinity,
    decoration: BoxDecoration(
      color: CoetusPalette.purple,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CoetusMascot(size: 120),
        const SizedBox(height: 12),
        Text(
          video
              ? 'Örnek video alanı · Çevrimdışı'
              : 'Örnek görsel alanı · Çevrimdışı',
          style: const TextStyle(color: CoetusPalette.lime),
        ),
        if (video)
          const Icon(Icons.play_circle_outline, color: CoetusPalette.cream),
      ],
    ),
  );
}
