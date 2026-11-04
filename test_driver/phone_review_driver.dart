import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory('build/phone-review')..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return bytes.isNotEmpty;
    },
    responseDataCallback: (data) async {
      final result = Map<String, dynamic>.from(data ?? {})
        ..remove('screenshots');
      await File(
        '${output.path}/result.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(result));
    },
    writeResponseOnFailure: true,
  );
}
