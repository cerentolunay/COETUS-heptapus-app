import 'package:coetus/widgets/coetus_mascot.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository_factory.dart';
import '../../domain/repositories/auth_repository.dart';

import 'package:coetus/app/theme/coetus_tokens.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepositoryFactory.create();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final fullName = value?.trim() ?? '';

    if (fullName.isEmpty) {
      return 'Ad soyad zorunludur';
    }

    if (fullName.length < 3) {
      return 'Ad soyad en az 3 karakter olmalıdır';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'E-posta zorunludur';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi gir';
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

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value?.trim() ?? '';
    final password = _passwordController.text.trim();

    if (confirmPassword.isEmpty) {
      return 'Şifre tekrarı zorunludur';
    }

    if (confirmPassword != password) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  Future<void> _handleRegister() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.signUp(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kayıt başarılı')));

      context.go('/discovery');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapAuthError(error.code))));
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapFirestoreError(error))));
    } on TimeoutException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İstek zaman aşımına uğradı. İnternet bağlantını kontrol et.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt oluşturulamadı. Lütfen tekrar dene.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        const SnackBar(content: Text('Google ile kayıt başarılı')),
      );

      context.go('/discovery');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapGoogleAuthError(error.code))));
    } on TimeoutException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google oturumu zaman aşımına uğradı.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google ile kayıt oluşturulamadı.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapGoogleAuthError(String code) {
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
        return 'Google ile kayıt oluşturulamadı. ($code)';
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanımda.';
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi gir.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 8 karakter kullan.';
      case 'network-request-failed':
        return 'Ağ hatası oluştu. İnternet bağlantını kontrol et.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Bir süre sonra tekrar dene.';
      default:
        return 'Kayıt oluşturulamadı. ($code)';
    }
  }

  String _mapFirestoreError(FirebaseException error) {
    final details = error.message;

    switch (error.code) {
      case 'permission-denied':
        return 'Veri yazma izni yok. Firestore kurallarını kontrol et.';
      case 'unavailable':
        if (details == null || details.isEmpty) {
          return 'Firestore şu an kullanılamıyor. Lütfen tekrar dene.';
        }
        return 'Firestore kullanılamıyor: $details';
      default:
        return 'Profil kaydedilemedi. (${error.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AuthHeaderSection(
                      headline: "Coetus'a katıl",
                      subtitle: 'Yeteneklerini paylaşmaya başla.',
                    ),
                    const SizedBox(height: 24),
                    _AuthModeTabs(
                      loginActive: false,
                      onTapLogin: _isLoading
                          ? null
                          : () => context.go('/login'),
                    ),
                    const SizedBox(height: 24),
                    _LabeledField(
                      label: 'Ad soyad',
                      child: TextFormField(
                        controller: _fullNameController,
                        validator: _validateFullName,
                        decoration: const InputDecoration(
                          hintText: 'Adın ve soyadın',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          hintText: 'En az 8 karakter',
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
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Şifre tekrarı',
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        validator: _validateConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Şifreni tekrar gir',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: CoetusPalette.purple,
                              ),
                            )
                          : const Text('Kayıt ol'),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Kayıt olarak Kullanım Şartları ve Gizlilik '
                        "Politikası'nı kabul ediyorsun.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CoetusColors.hint,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
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
                          Flexible(
                            child: Text(
                              'Google ile devam et',
                              textAlign: TextAlign.center,
                            ),
                          ),
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
        const CoetusMascot(size: 100, animate: false, interactive: false),
        const SizedBox(height: 16),
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
  const _AuthModeTabs({required this.loginActive, this.onTapLogin});

  final bool loginActive;
  final VoidCallback? onTapLogin;

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
              onTap: onTapLogin,
            ),
          ),
          Expanded(
            child: _AuthModeTab(
              label: 'Kayıt',
              active: !loginActive,
              onTap: null,
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
          color: active ? CoetusPalette.lime : Colors.transparent,
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
