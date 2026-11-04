import 'package:flutter/material.dart';
import '../app/theme/coetus_tokens.dart';
import '../widgets/coetus_mascot.dart';

/// A local illustration for offline previews.
class PreviewMedia extends StatelessWidget {
  const PreviewMedia({super.key});
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
          'Örnek görsel alanı · Çevrimdışı',
          style: const TextStyle(color: CoetusPalette.lime),
        ),
      ],
    ),
  );
}
