import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository_factory.dart';
import '../../domain/repositories/auth_repository.dart';

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

  static const Color _bgStart = Color(0xFF0B1120);
  static const Color _bgMiddle = Color(0xFF0F172A);
  static const Color _bgEnd = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgStart, _bgMiddle, _bgEnd],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const _HeaderSection(),
                      const SizedBox(height: 28),
                      _InputSection(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        showPassword: _showPassword,
                        onTogglePassword: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                        emailValidator: _validateEmail,
                        passwordValidator: _validatePassword,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  context.go('/forgot-password');
                                },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: _cyan,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _GradientButton(
                        text: _isLoading ? 'Logging in...' : 'Login',
                        icon: _isLoading ? null : Icons.arrow_forward,
                        isLoading: _isLoading,
                        onTap: _isLoading ? null : _handleLogin,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SecondaryButton(
                        text: 'Continue with Google',
                        leading: const _GoogleIcon(),
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      context.go('/register');
                                    },
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: _cyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_purple, _cyan],
            ),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to continue your skill-swapping journey',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 14),
        ),
      ],
    );
  }
}

class _InputSection extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final String? Function(String?) emailValidator;
  final String? Function(String?) passwordValidator;

  const _InputSection({
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.onTogglePassword,
    required this.emailValidator,
    required this.passwordValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: 'Email Address'),
        const SizedBox(height: 8),
        _GlassInput(
          controller: emailController,
          hintText: 'your.email@example.com',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          validator: emailValidator,
        ),
        const SizedBox(height: 18),
        _FieldLabel(text: 'Password'),
        const SizedBox(height: 8),
        _GlassInput(
          controller: passwordController,
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          obscureText: !showPassword,
          validator: passwordValidator,
          suffix: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.50),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlassInput({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 14,
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 12),
        prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.50)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x8006B6D4)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.2),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_purple, _cyan]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(124, 58, 237, 0.30),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            if (isLoading) const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isLoading && icon != null) const SizedBox(width: 8),
            if (!isLoading && icon != null)
              Icon(icon, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String text;
  final Widget leading;
  final VoidCallback? onTap;

  const _SecondaryButton({
    required this.text,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.05),
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        side: BorderSide(color: Colors.white.withOpacity(0.10)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
