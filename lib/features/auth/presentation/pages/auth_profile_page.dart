import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository_factory.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProfilePage extends StatefulWidget {
  const AuthProfilePage({super.key});

  @override
  State<AuthProfilePage> createState() => _AuthProfilePageState();
}

class _AuthProfilePageState extends State<AuthProfilePage> {
  final AuthRepository _authRepository = AuthRepositoryFactory.create();

  AppUser? _user;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();
      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _error = 'Kullanici bilgisi alinirken zaman asimi olustu.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Kullanici bilgisi alinamadi. Lutfen tekrar dene.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
      _error = null;
    });

    try {
      await _authRepository.signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cikis basarili.')));
      context.go('/login');
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
        _error = 'Cikis islemi zaman asimina ugradi.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
        _error = 'Cikis yapilamadi. Lutfen tekrar dene.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgStart = Color(0xFF0B1120);
    const bgMiddle = Color(0xFF0F172A);
    const bgEnd = Color(0xFF1E1B4B);
    const cyan = Color(0xFF06B6D4);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgMiddle, bgEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: _buildContent(cyan),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color cyan) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _loadCurrentUser,
            child: const Text('Tekrar dene'),
          ),
        ],
      );
    }

    if (_user == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Aktif oturum bulunamadi.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Login sayfasina git'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _UserRow(label: 'Ad Soyad', value: _user!.name),
        const SizedBox(height: 8),
        _UserRow(label: 'Email', value: _user!.email),
        const SizedBox(height: 8),
        _UserRow(label: 'Kredi', value: '${_user!.credits} HC'),
        const SizedBox(height: 8),
        _UserRow(
          label: 'Dogrulama',
          value: _user!.verified ? 'Dogrulandi' : 'Dogrulanmadi',
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFFB4B4)),
            ),
          ),
        ElevatedButton(
          onPressed: _isLoggingOut ? null : _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: cyan,
            foregroundColor: const Color(0xFF07111F),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoggingOut
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
