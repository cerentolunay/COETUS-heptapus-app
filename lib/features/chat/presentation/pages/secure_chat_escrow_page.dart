import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecureChatEscrowPage extends StatelessWidget {
  const SecureChatEscrowPage({super.key});

  static const Color _bg = Color(0xFF0F172A);
  static const Color _panel = Color(0xFF111827);
  static const Color _border = Color(0xFF243044);
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _muted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              decoration: const BoxDecoration(
                color: _panel,
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/chat'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Icon(Icons.lock_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Secure Escrow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user, color: _purple, size: 38),
                      SizedBox(height: 14),
                      Text(
                        'Escrow details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Active exchange escrow records will be shown here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
