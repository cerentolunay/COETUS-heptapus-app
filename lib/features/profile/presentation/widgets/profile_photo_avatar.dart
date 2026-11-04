import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../app/theme/coetus_tokens.dart';

class ProfilePhotoAvatar extends StatelessWidget {
  const ProfilePhotoAvatar({
    super.key,
    this.photoUrl,
    this.bytes,
    this.size = 88,
    this.initials = '',
  });
  final String? photoUrl;
  final Uint8List? bytes;
  final double size;
  final String initials;
  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: initials.isEmpty
          ? const Icon(Icons.add_a_photo_outlined, color: CoetusPalette.purple)
          : Text(
              initials,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: CoetusPalette.purple),
            ),
    );
    Widget child = fallback;
    if (bytes != null) {
      child = Image.memory(
        bytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (photoUrl?.isNotEmpty == true) {
      final uri = Uri.tryParse(photoUrl!);
      if (uri?.scheme == 'data') {
        try {
          child = Image.memory(
            uri!.data!.contentAsBytes(),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );
        } catch (_) {
          child = fallback;
        }
      } else if (uri?.scheme == 'https' || uri?.scheme == 'http') {
        child = Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      }
    }
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(color: CoetusPalette.lime, child: child),
      ),
    );
  }
}
