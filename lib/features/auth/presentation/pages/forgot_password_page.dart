import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:coetus/app/theme/coetus_tokens.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false;

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
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildIntro(context),
                    const SizedBox(height: 28),
                    _sent ? _buildSuccessState(context) : _buildForm(context),
                  ],
                ),
              ),
            ),
          ],
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
        icon: const Icon(
          Icons.arrow_back,
          color: CoetusColors.muted,
          size: 20,
        ),
        label: const Text(
          'Girişe dön',
          style: TextStyle(color: CoetusColors.muted, fontSize: 14),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: CoetusColors.navy,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.mail_outline,
            color: CoetusColors.oat,
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Şifreni mi unuttun?',
          style: textTheme.headlineMedium?.copyWith(
            color: CoetusColors.navyInk,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'E-posta adresini gir, sana şifreni sıfırlamak için bir bağlantı '
          'gönderelim.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: CoetusColors.muted),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('E-posta', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'ornek@eposta.com',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSubmit,
            child: const Text('Sıfırlama bağlantısı gönder'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final email = _emailController.text.trim();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: CoetusColors.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.check, color: CoetusColors.oat, size: 42),
        ),
        const SizedBox(height: 22),
        Text(
          'E-postanı kontrol et',
          style: textTheme.headlineMedium?.copyWith(
            color: CoetusColors.navyInk,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: textTheme.bodyMedium?.copyWith(color: CoetusColors.muted),
            children: [
              const TextSpan(text: 'Şifre sıfırlama bağlantısını '),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: CoetusColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' adresine gönderdik.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CoetusColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CoetusColors.border),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                'E-postayı görmüyorsan spam klasörünü kontrol et veya ',
                textAlign: TextAlign.center,
                style: TextStyle(color: CoetusColors.muted, fontSize: 13),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _sent = false;
                  });
                },
                child: const Text(
                  'tekrar dene',
                  style: TextStyle(
                    color: CoetusColors.navy,
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
            child: const Text('Girişe dön'),
          ),
        ),
      ],
    );
  }
}
