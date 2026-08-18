import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/coetus_tokens.dart';

/// Paylaşılan alt navigasyon çubuğu. Uygulamadaki 4 üst düzey hedefi
/// tutarlı şekilde temsil eder: Keşfet / Sohbet / Takas / Profil.
///
/// `currentIndex` aktif sekmeyi işaretler; hiçbir sekmenin aktif olmadığı
/// ekranlarda (örn. Bildirimler) `-1` geçilebilir.
class CoetusBottomNav extends StatelessWidget {
  const CoetusBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = <_NavDestination>[
    _NavDestination(
      label: 'Keşfet',
      route: '/matching',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
    _NavDestination(
      label: 'Sohbet',
      route: '/chat',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
    ),
    _NavDestination(
      label: 'Takas',
      route: '/exchange',
      icon: Icons.swap_horiz_outlined,
      activeIcon: Icons.swap_horiz,
    ),
    _NavDestination(
      label: 'Profil',
      route: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: CoetusColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _items.length; i++)
            _NavButton(
              destination: _items[i],
              active: i == currentIndex,
              onTap: () {
                if (i == currentIndex) return;
                context.go(_items[i].route);
              },
            ),
        ],
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.route,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? CoetusColors.oat
        : CoetusColors.oat.withValues(alpha: .6);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? destination.activeIcon : destination.icon,
              size: 21, color: color),
          const SizedBox(height: 4),
          Text(
            destination.label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
