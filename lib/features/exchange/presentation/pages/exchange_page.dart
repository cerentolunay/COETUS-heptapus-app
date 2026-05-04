import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExchangePage extends StatelessWidget {
  const ExchangePage({super.key});

  static const Color _bg = Color(0xFF0A0F1C);
  static const Color _bg2 = Color(0xFF0F172A);
  static const Color _bg3 = Color(0xFF1E1B4B);

  static const Color _card = Color(0x14FFFFFF);
  static const Color _border = Color(0x1AFFFFFF);

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _violetSoft = Color(0xFFA78BFA);
  static const Color _green = Color(0xFF4ADE80);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFF87171);

  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _textSoft = Color(0xFFCBD5E1);

  static const List<_ExchangeItem> _activeExchanges = [
    _ExchangeItem(
      id: '1',
      partnerName: 'Sarah Martinez',
      title: 'Guitar & Spanish Exchange',
      date: 'Tomorrow • 4:00 PM',
      credits: 50,
      status: ExchangeStatus.locked,
      teachesYou: 'Spanish',
      youTeach: 'Guitar',
    ),
    _ExchangeItem(
      id: '2',
      partnerName: 'David Kim',
      title: 'Coding & English Session',
      date: 'Fri • 6:30 PM',
      credits: 40,
      status: ExchangeStatus.scheduled,
      teachesYou: 'Coding',
      youTeach: 'English',
    ),
    _ExchangeItem(
      id: '3',
      partnerName: 'Emily Chen',
      title: 'Design Feedback Swap',
      date: 'Completed • Yesterday',
      credits: 30,
      status: ExchangeStatus.completed,
      teachesYou: 'Design',
      youTeach: 'Spanish',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, _bg2, _bg3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 18),
                      _buildCreditSummary(),
                      const SizedBox(height: 18),
                      _buildSectionHeader(),
                      const SizedBox(height: 14),
                      ..._activeExchanges.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ExchangeCard(item: item),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomNavigation(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exchange Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your sessions, credits, and swap history',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => context.go('/exchange-history'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, color: _cyan, size: 18),
                SizedBox(width: 8),
                Text(
                  'History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_violet, _cyan]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Credits',
                      style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '450 HC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Top Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withOpacity(0.20)),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: 'Locked', value: '50 HC'),
              _MiniStat(label: 'Completed', value: '18'),
              _MiniStat(label: 'Success', value: '98%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Row(
      children: [
        Icon(Icons.swap_horiz, color: _cyan, size: 20),
        SizedBox(width: 8),
        Text(
          'Active Exchanges',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg2.withOpacity(0.86),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => context.go('/profile'),
          ),
          _BottomNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chats',
            onTap: () => context.go('/chat'),
          ),
          _BottomNavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Exchange',
            isActive: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  final _ExchangeItem item;

  const _ExchangeCard({required this.item});

  static const Color _card = Color(0x14FFFFFF);
  static const Color _border = Color(0x1AFFFFFF);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _textSoft = Color(0xFFCBD5E1);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _green = Color(0xFF4ADE80);
  static const Color _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final visual = _ExchangeStatusVisual.fromStatus(item.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: visual.color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      visual.color.withOpacity(0.90),
                      visual.secondaryColor.withOpacity(0.90),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(visual.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.partnerName,
                      style: const TextStyle(color: _textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _StatusChip(visual: visual),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Date',
                  value: item.date,
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'You teach',
                  value: item.youTeach,
                  icon: Icons.arrow_upward,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'You learn',
                  value: item.teachesYou,
                  icon: Icons.arrow_downward,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Credits',
                  value: '${item.credits} HC',
                  icon: Icons.monetization_on_outlined,
                  valueColor: _cyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/exchange-detail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                    backgroundColor: Colors.white.withOpacity(0.04),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [visual.color, visual.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.go('/chat-escrow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      item.status == ExchangeStatus.completed
                          ? 'Review'
                          : 'Open Chat',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _ExchangeStatusVisual visual;

  const _StatusChip({required this.visual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: visual.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: visual.color.withOpacity(0.22)),
      ),
      child: Text(
        visual.label,
        style: TextStyle(
          color: visual.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  static const Color _active = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _active : Colors.white.withOpacity(0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ExchangeStatus { locked, scheduled, completed }

class _ExchangeItem {
  final String id;
  final String partnerName;
  final String title;
  final String date;
  final int credits;
  final ExchangeStatus status;
  final String teachesYou;
  final String youTeach;

  const _ExchangeItem({
    required this.id,
    required this.partnerName,
    required this.title,
    required this.date,
    required this.credits,
    required this.status,
    required this.teachesYou,
    required this.youTeach,
  });
}

class _ExchangeStatusVisual {
  final IconData icon;
  final Color color;
  final Color secondaryColor;
  final String label;

  const _ExchangeStatusVisual({
    required this.icon,
    required this.color,
    required this.secondaryColor,
    required this.label,
  });

  factory _ExchangeStatusVisual.fromStatus(ExchangeStatus status) {
    switch (status) {
      case ExchangeStatus.locked:
        return const _ExchangeStatusVisual(
          icon: Icons.lock_outline,
          color: Color(0xFFF59E0B),
          secondaryColor: Color(0xFF7C3AED),
          label: 'Locked',
        );
      case ExchangeStatus.scheduled:
        return const _ExchangeStatusVisual(
          icon: Icons.event_available_outlined,
          color: Color(0xFF06B6D4),
          secondaryColor: Color(0xFF7C3AED),
          label: 'Scheduled',
        );
      case ExchangeStatus.completed:
        return const _ExchangeStatusVisual(
          icon: Icons.check_circle_outline,
          color: Color(0xFF4ADE80),
          secondaryColor: Color(0xFF06B6D4),
          label: 'Completed',
        );
    }
  }
}
