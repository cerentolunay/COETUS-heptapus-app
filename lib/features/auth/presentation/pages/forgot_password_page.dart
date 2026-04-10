import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false;

  static const Color _bgTop = Color(0xFF0B1120);
  static const Color _bgMid = Color(0xFF0F172A);
  static const Color _bgBottom = Color(0xFF1E1B4B);

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _blue = Color(0xFF0EA5E9);
  static const Color _purple = Color(0xFF7C3AED);

  static const Color _surface = Color(0x14FFFFFF);
  static const Color _surfaceBorder = Color(0x1AFFFFFF);
  static const Color _textMuted = Color(0xFF94A3B8);

  void _handleSubmit() {
    if (_emailController.text.trim().isEmpty) return;

    setState(() {
      _sent = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgMid, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 12),
                      _buildIntro(),
                      const SizedBox(height: 28),
                      _sent ? _buildSuccessState(context) : _buildForm(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          context.go('/login');
        },
        icon: const Icon(Icons.arrow_back, color: _textMuted, size: 20),
        label: const Text(
          'Back to Login',
          style: TextStyle(
            color: _textMuted,
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_purple, _cyan]),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: const Icon(
            Icons.mail_outline,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Forgot Password?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          "Enter your email address and we'll send you a link to reset your password",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            color: _textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _surfaceBorder),
          ),
          child: TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail_outline, color: _textMuted),
              hintText: 'your.email@example.com',
              hintStyle: TextStyle(
                color: _textMuted,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_purple, _cyan]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _purple.withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _handleSubmit,
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'Send Reset Link',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final email = _emailController.text.trim();

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_cyan, _blue]),
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 42,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Check Your Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: _textMuted,
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "We've sent a password reset link to "),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: _cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              const Text(
                "Didn't receive the email? Check your spam folder or ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _sent = false;
                  });
                },
                child: const Text(
                  'try again',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.go('/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _surfaceBorder),
              backgroundColor: _surface,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}