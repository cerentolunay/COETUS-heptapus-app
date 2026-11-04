import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/preview/preview_mode.dart';
import '../domain/profile_identity.dart';

Future<void> showProfileQr(
  BuildContext context,
  String userId,
  String username,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Profil QR kodun',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (username.isNotEmpty) Text('@$username'),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: QrImageView(
            data: profileQrData(userId),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(20),
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: CoetusPalette.purple,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: CoetusPalette.purple,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Karşındaki kişi COETUS içinden bu kodu okutarak profilini bulabilir. QR kodun kullanıcı adını değiştirsen de aynı kalır.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
      ],
    ),
  ),
);

class ScanProfileQrPage extends StatefulWidget {
  const ScanProfileQrPage({super.key});
  @override
  State<ScanProfileQrPage> createState() => _ScanProfileQrPageState();
}

class _ScanProfileQrPageState extends State<ScanProfileQrPage>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _done = false;
  String? _error;
  bool get _supported =>
      kIsWeb ||
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!PreviewMode.enabled && _supported) {
      _controller = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed && !_done) {
      unawaited(controller.start());
    } else {
      unawaited(controller.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  void _scan(String raw) {
    if (_done) return;
    try {
      final userId = parseProfileQr(raw);
      _done = true;
      Navigator.pop(context, userId);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Widget _camera() {
    if (PreviewMode.enabled) {
      return Center(
        child: FilledButton(
          onPressed: () => _scan(profileQrData('preview-partner')),
          child: const Text('Örnek QR okut'),
        ),
      );
    }
    if (!_supported) {
      return const Center(
        child: Text('Bu cihazda kullanıcı adıyla arama yapabilirsin.'),
      );
    }
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final code in capture.barcodes) {
          if (code.rawValue != null) {
            _scan(code.rawValue!);
            break;
          }
        }
      },
      errorBuilder: (_, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Kamera açılamadı. Kamera iznini kontrol et veya kullanıcı adıyla ara.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil QR kodunu okut')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Yalnızca karşındaki kişinin COETUS profil kodunu okut.'),
        ),
        Expanded(child: _camera()),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              style: const TextStyle(color: CoetusColors.danger),
            ),
          ),
      ],
    ),
  );
}
