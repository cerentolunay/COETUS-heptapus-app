import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/coetus_tokens.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CoetusPalette.cream,
    appBar: AppBar(
      backgroundColor: CoetusPalette.cream,
      foregroundColor: CoetusPalette.purple,
      title: const Text('Premium ve token'),
      leading: IconButton(
        tooltip: 'Geri',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/matching');
          }
        },
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: CoetusPalette.purple,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: CoetusPalette.lime,
                      size: 44,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Biraz daha merak.\nDaha çok keşif.',
                      style: TextStyle(
                        color: CoetusPalette.lime,
                        fontSize: 30,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'İster yeni insanlarla sınırsız eşleş, ister öğrenme yolculuğun için token ekle.',
                      style: TextStyle(
                        color: CoetusPalette.cream,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Sana uygun paketi keşfet',
                style: TextStyle(
                  color: CoetusPalette.purple,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paketler yakında burada. Satın alma henüz açık değil.',
                style: TextStyle(color: CoetusPalette.purple),
              ),
              const SizedBox(height: 20),
              const _PackageCard(
                title: 'Sınırsız eşleşme',
                eyebrow: 'COETUS PREMIUM',
                icon: Icons.all_inclusive_rounded,
                description:
                    'Merakına sınır koyma. Yeni öğrenme arkadaşlarını keşfet.',
                benefits: [
                  'Eşleşme sınırını kaldır',
                  'Yeni yetenekler ve insanlarla tanış',
                ],
                footnote: 'Üyelik paketi · Token içermez.',
              ),
              const SizedBox(height: 16),
              const _PackageCard(
                title: '250 token',
                eyebrow: 'TOKEN PAKETİ',
                icon: Icons.toll_rounded,
                description: 'Bir sonraki öğrenme deneyimine yer aç.',
                benefits: [
                  'Bakiyene eklenecek 250 token',
                  'Öğrenme oturumlarında kullan',
                ],
                footnote: 'Tek seferlik paket · Premium üyelik içermez.',
              ),
              const SizedBox(height: 20),
              const Text(
                'Fiyatlar ve paket koşulları satışa açılmadan önce burada paylaşılacak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CoetusPalette.purple,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    required this.eyebrow,
    required this.icon,
    required this.description,
    required this.benefits,
    required this.footnote,
  });
  final String title, eyebrow, description, footnote;
  final IconData icon;
  final List<String> benefits;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: CoetusPalette.purple.withValues(alpha: .15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: CoetusPalette.purple, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                eyebrow,
                style: const TextStyle(
                  color: CoetusPalette.purple,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: CoetusPalette.purple,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: CoetusPalette.purple, height: 1.5),
        ),
        const SizedBox(height: 18),
        for (final benefit in benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: CoetusPalette.purple,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(color: CoetusPalette.purple),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Text(
          footnote,
          style: const TextStyle(color: CoetusPalette.purple, fontSize: 12),
        ),
        const SizedBox(height: 18),
        const FilledButton(onPressed: null, child: Text('Yakında')),
      ],
    ),
  );
}
