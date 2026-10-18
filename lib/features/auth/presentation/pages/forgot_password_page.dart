import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../preview/preview_mode.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:coetus/app/theme/coetus_tokens.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.sendResetEmail});
  final Future<void> Function(String email)? sendResetEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false, _sending = false;
  String? _error;
  final _form = GlobalKey<FormState>();

  Future<void> _handleSubmit() async {
    if (_sending || !_form.currentState!.validate()) return;
    if (PreviewMode.enabled && widget.sendResetEmail == null) {
      setState(
        () => _error =
            'Önizlemede gerçek e-posta gönderilmez. Normal uygulama sürümünden dene.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      if (widget.sendResetEmail != null) {
        await widget.sendResetEmail!(email);
      } else {
        if (Firebase.apps.isEmpty) {
          throw StateError(
            'Firebase bağlantısı hazır değil. Normal uygulama sürümünden dene.',
          );
        }
        await FirebaseAuth.instance.setLanguageCode('tr');
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      }
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'user-not-found') {
        // Same response as success: do not expose whether an account exists.
        setState(() => _sent = true);
      } else {
        setState(
          () => _error = switch (error.code) {
            'invalid-email' => 'Geçerli bir e-posta adresi gir.',
            'too-many-requests' =>
              'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.',
            'network-request-failed' =>
              'Bağlantı kurulamadı. İnternet bağlantını kontrol et.',
            'operation-not-allowed' =>
              'E-posta/şifre girişi Firebase ayarlarında etkinleştirilmeli.',
            _ => 'Bağlantı gönderilemedi. Lütfen yeniden dene.',
          },
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Bağlantı gönderilemedi. Lütfen yeniden dene.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
        icon: const Icon(Icons.arrow_back, color: CoetusColors.muted, size: 20),
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
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('E-posta', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            enabled: !_sending,
            autofillHints: const [AutofillHints.email],
            validator: (value) =>
                value != null &&
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
                ? null
                : 'Geçerli bir e-posta adresi gir.',
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'ornek@eposta.com',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: CoetusPalette.onRed),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _handleSubmit,
              child: Text(
                _sending ? 'Gönderiliyor…' : 'Sıfırlama bağlantısı gönder',
              ),
            ),
          ),
        ],
      ),
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
              const TextSpan(
                text:
                    'Bu e-posta ile kayıtlı bir şifreli hesap varsa sıfırlama bağlantısı ',
              ),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: CoetusColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' adresine gönderilecek.'),
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
                'Google ile kayıt olduysan Google ile giriş yap. E-postayı görmüyorsan spam klasörünü kontrol et veya ',
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
