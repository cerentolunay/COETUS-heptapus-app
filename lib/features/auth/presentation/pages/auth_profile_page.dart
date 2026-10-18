import '../widgets/delete_account_button.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
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
        _error = 'Kullanıcı bilgisi alınırken zaman aşımı oluştu.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Kullanıcı bilgisi alınamadı. Lütfen tekrar dene.';
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
      ).showSnackBar(const SnackBar(content: Text('çıkış başarılı.')));
      context.go('/login');
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
        _error = 'çıkış işlemi zaman asimina ugradi.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
        _error = 'Çıkış yapilamadi. Lütfen tekrar dene.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgStart = CoetusPalette.purpleInk;
    const bgMiddle = CoetusPalette.purple;
    const bgEnd = CoetusPalette.purple;
    const cyan = CoetusPalette.lime;

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
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
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
      return const SizedBox(height: 120, child: CoetusLoadingState());
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
            'Aktif oturum bulunamadı.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Giriş sayfasına git'),
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
        _UserRow(label: 'Ad soyad', value: _user!.name),
        const SizedBox(height: 8),
        _UserRow(label: 'E-posta', value: _user!.email),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => context.push('/premium'),
          child: _UserRow(label: 'Token', value: '${_user!.credits} token'),
        ),
        const SizedBox(height: 8),
        _UserRow(
          label: 'Doğrulama',
          value: _user!.verified ? 'Doğrulandı' : 'Doğrulanmadı',
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
            foregroundColor: CoetusPalette.purpleInk,
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
                  'Çıkış yap',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
        const SizedBox(height: 8),
        DeleteAccountButton(enabled: !_isLoggingOut),
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
