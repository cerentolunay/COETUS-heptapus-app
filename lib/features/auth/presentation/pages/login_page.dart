import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository_factory.dart';
import '../../domain/repositories/auth_repository.dart';

import 'package:coetus/app/theme/coetus_tokens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepositoryFactory.create();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email zorunludur';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir email adresi gir';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'Şifre zorunludur';
    }

    if (password.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır';
    }

    return null;
  }

  Future<void> _handleLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giriş başarılı')));

      context.go('/home');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapEmailAuthError(error.code))));
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapFirestoreError(error.code))));
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İstek zaman aşımına uğradı. İnternet bağlantını kontrol et.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giriş yapılamadı')));
    }
  }

  String _mapEmailAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi gir.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'E-posta veya şifre hatalı.';
      case 'user-disabled':
        return 'Bu kullanıcı devre dışı bırakılmış.';
      case 'network-request-failed':
        return 'Ağ hatası oluştu. İnternet bağlantını kontrol et.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Bir süre sonra tekrar dene.';
      default:
        return 'Giriş yapılamadı. ($code)';
    }
  }

  String _mapFirestoreError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Profil bilgisi okunamadı. Firestore kurallarını kontrol et.';
      case 'unavailable':
        return 'Firestore şu an kullanılamıyor. Lütfen tekrar dene.';
      default:
        return 'Profil bilgisi alınamadı. ($code)';
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.signInWithGoogle();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google ile giriş başarılı')),
      );

      context.go('/home');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapAuthError(error.code))));
    } on TimeoutException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google oturumu zaman aşımına uğradı.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google ile giriş yapılamadı.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Bu hesap farklı bir yöntemle kayıtlı.';
      case 'invalid-credential':
        return 'Google kimlik bilgisi geçersiz.';
      case 'network-request-failed':
        return 'Ağ hatası oluştu. İnternet bağlantını kontrol et.';
      case 'user-disabled':
        return 'Bu kullanıcı devre dışı bırakılmış.';
      default:
        return 'Google ile giriş yapılamadı. ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AuthHeaderSection(
                      headline: 'Tekrar hoş geldin',
                      subtitle: 'Kredi bakiyen ve oturumların seni bekliyor.',
                    ),
                    const SizedBox(height: 24),
                    _AuthModeTabs(
                      loginActive: true,
                      onTapRegister: _isLoading
                          ? null
                          : () => context.go('/register'),
                    ),
                    const SizedBox(height: 24),
                    _LabeledField(
                      label: 'E-posta',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        decoration: const InputDecoration(
                          hintText: 'ornek@eposta.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Şifre',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        validator: _validatePassword,
                        decoration: InputDecoration(
                          hintText: 'Şifreni gir',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                context.go('/forgot-password');
                              },
                        child: const Text('Şifremi unuttum'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: CoetusColors.oat,
                              ),
                            )
                          : const Text('Giriş yap'),
                    ),
                    const SizedBox(height: 24),
                    const _OrDivider(),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleIcon(),
                          SizedBox(width: 10),
                          Text('Google ile devam et'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 52x52 lacivert kare logo rozeti + başlık + alt metin.
class _AuthHeaderSection extends StatelessWidget {
  const _AuthHeaderSection({required this.headline, required this.subtitle});

  final String headline;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: CoetusColors.navy,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'C',
              style: TextStyle(
                color: CoetusColors.oat,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            color: CoetusColors.navyInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: CoetusColors.muted),
        ),
      ],
    );
  }
}

/// Giriş / Kayıt pill sekme geçişi.
class _AuthModeTabs extends StatelessWidget {
  const _AuthModeTabs({
    required this.loginActive,
    this.onTapRegister,
  });

  final bool loginActive;
  final VoidCallback? onTapRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CoetusColors.navy.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthModeTab(
              label: 'Giriş',
              active: loginActive,
              onTap: null,
            ),
          ),
          Expanded(
            child: _AuthModeTab(
              label: 'Kayıt',
              active: !loginActive,
              onTap: onTapRegister,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeTab extends StatelessWidget {
  const _AuthModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: active ? null : onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? CoetusColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? CoetusColors.navy : CoetusColors.muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: CoetusColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: TextStyle(color: CoetusColors.hint, fontSize: 12),
          ),
        ),
        Expanded(child: Container(height: 1, color: CoetusColors.border)),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: CoetusColors.navy,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
