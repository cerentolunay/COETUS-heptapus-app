import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/widgets/coetus_mascot.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _celebration = ValueNotifier<int>(0);
  bool _starting = false;

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    _celebration.value++;
    if (!MediaQuery.disableAnimationsOf(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 18,
                    runSpacing: 10,
                    children: [
                      Text('coetus', style: text.headlineMedium),
                      const _Pill(
                        label: 'Birlikte geliş.',
                        color: CoetusPalette.lime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
                    decoration: BoxDecoration(
                      color: CoetusPalette.purple,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Pill(
                          label: 'MERAK ET. PAYLAŞ. GELİŞ.',
                          color: CoetusPalette.lavender,
                        ),
                        Center(
                          child: CoetusMascot(
                            size: 166,
                            celebration: _celebration,
                          ),
                        ),
                        Text(
                          'Sen öğret.\nSen de öğren.',
                          style: text.displaySmall?.copyWith(
                            color: CoetusPalette.cream,
                            fontSize: 40,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Bildiğini paylaş, kredi kazan. Merak ettiğin yeteneği topluluktan öğren.',
                          style: text.bodyLarge?.copyWith(
                            color: CoetusPalette.cream,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(label: 'Tasarım', color: CoetusPalette.lime),
                            _Pill(
                              label: 'Yazılım',
                              color: CoetusPalette.lavender,
                            ),
                            _Pill(
                              label: 'Müzik',
                              color: CoetusPalette.softLavender,
                            ),
                            _Pill(
                              label: 'Yabancı dil',
                              color: CoetusPalette.softLavender,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '01  Öğret    ·    02  Kredi kazan    ·    03  Öğren',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CoetusPalette.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _starting ? null : _start,
                    child: const Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        Text('Ücretsiz hesap aç'),
                        Icon(Icons.arrow_outward_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _starting ? null : () => context.go('/login'),
                    child: const Text(
                      'Zaten hesabım var · Giriş yap',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Para yerine yeteneğinle başla.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: CoetusPalette.purple,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: .15,
      ),
    ),
  );
}
