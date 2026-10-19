import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:flutter/services.dart';
import '../../data/services/profile_photo_service.dart';
import '../widgets/profile_photo_avatar.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/coetus_tokens.dart';
import '../../data/repositories/profile_repository_factory.dart';
import '../../domain/models/profile_data.dart';
import '../../domain/repositories/profile_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    this.repository,
    this.pickPhoto,
    this.uploadPhoto,
  });
  final ProfileRepository? repository;
  final Future<XFile?> Function(ImageSource source)? pickPhoto;
  final Future<String> Function(ProfilePhoto photo)? uploadPhoto;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final ProfileRepository _profileRepository =
      widget.repository ?? ProfileRepositoryFactory.create();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  ProfilePhoto? _selectedPhoto;
  String? _existingPhotoUrl, _uploadedPhotoUrl;
  bool _isPickingPhoto = false;

  ProfileData? _profileData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.loadProfile();

      if (!mounted) return;

      _profileData = profile;
      _displayNameController.text = profile.user.name;
      _bioController.text = profile.user.bio;
      _locationController.text = profile.user.location ?? '';
      _existingPhotoUrl = profile.user.photoUrl;

      String? photoError;
      if (widget.pickPhoto == null &&
          !PreviewMode.enabled &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        try {
          final lost = await ImagePicker().retrieveLostData();
          final file = lost.files?.firstOrNull;
          if (file != null) _selectedPhoto = await ProfilePhoto.read(file);
          if (lost.exception != null) {
            photoError =
                'Önceki fotoğraf seçimi kurtarılamadı. Yeniden seçebilirsin.';
          }
        } catch (_) {
          photoError =
              'Önceki fotoğraf seçimi kurtarılamadı. Yeniden seçebilirsin.';
        }
      }
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = photoError;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Profil yüklenemedi: $e';
      });
    }
  }

  Future<void> _pickProfilePhoto() async {
    if (_isPickingPhoto || _isSaving) return;
    setState(() => _isPickingPhoto = true);
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden fotoğraf seç'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Fotoğraf çek'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      if (source == null || !mounted) return;
      final file =
          await (widget.pickPhoto?.call(source) ??
              ImagePicker().pickImage(
                source: source,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 80,
              ));
      if (file == null) return;
      final photo = await ProfilePhoto.read(file);
      if (!mounted) return;
      setState(() {
        _selectedPhoto = photo;
        _uploadedPhotoUrl = null;
        _errorMessage = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error is FormatException
              ? error.message
              : error is PlatformException
              ? 'Fotoğraf seçilemedi. Kamera veya galeri iznini kontrol edip yeniden dene.'
              : 'Fotoğraf açılamadı. Yeniden dene.';
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  String? _validateDisplayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Görünen ad zorunludur';
    if (text.length < 2) return 'Görünen ad en az 2 karakter olmalıdır';
    if (text.length > 50) return 'Görünen ad en fazla 50 karakter olabilir';
    return null;
  }

  String? _validateBio(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 500) {
      return 'Hakkında alanı en fazla 500 karakter olabilir';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 100) return 'Konum en fazla 100 karakter olabilir';
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileData == null || _isSaving || _isPickingPhoto) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_selectedPhoto != null && _uploadedPhotoUrl == null) {
        _uploadedPhotoUrl =
            await (widget.uploadPhoto ?? ProfilePhotoService().upload)(
              _selectedPhoto!,
            );
      }
      if (!mounted) return;
      final updatedUser = _profileData!.user.copyWith(
        name: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        photoUrl: _uploadedPhotoUrl ?? _existingPhotoUrl,
      );

      await _profileRepository.updateProfile(updatedUser);
      if (_uploadedPhotoUrl != null && widget.uploadPhoto == null) {
        unawaited(
          ProfilePhotoService().removePrevious(
            _existingPhotoUrl,
            _uploadedPhotoUrl!,
          ),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil güncellendi')));

      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/profile');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e is StateError
            ? e.message
            : e is FormatException
            ? e.message
            : 'Profil güncellenemedi. Bağlantını kontrol edip yeniden dene.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: CoetusColors.oat,
        body: CoetusLoadingState(),
      );
    }

    if (_errorMessage != null && _profileData == null) {
      return Scaffold(
        backgroundColor: CoetusColors.oat,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CoetusSpace.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _isSaving ? null : () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: CoetusColors.navyInk,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Profili düzenle', style: t.headlineSmall),
                    ),
                  ],
                ),
                const SizedBox(height: CoetusSpace.xxl),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(CoetusSpace.md),
                    decoration: BoxDecoration(
                      color: CoetusColors.danger.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CoetusColors.danger.withValues(alpha: .30),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: t.bodySmall?.copyWith(color: CoetusColors.danger),
                    ),
                  ),
                  const SizedBox(height: CoetusSpace.xl),
                ],
                _buildFieldLabel(t, 'Görünen ad *'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  enabled: !_isSaving,
                  controller: _displayNameController,
                  validator: _validateDisplayName,
                  decoration: const InputDecoration(
                    hintText: 'Görünen ad',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 18),
                _buildFieldLabel(t, 'Hakkında'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  enabled: !_isSaving,
                  controller: _bioController,
                  validator: _validateBio,
                  minLines: 3,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Hakkında',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                _buildFieldLabel(t, 'Konum'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  enabled: !_isSaving,
                  controller: _locationController,
                  validator: _validateLocation,
                  decoration: const InputDecoration(
                    hintText: 'Konum',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                _buildFieldLabel(t, 'Profil fotoğrafı ekle'),
                const SizedBox(height: CoetusSpace.sm),
                Center(
                  child: ProfilePhotoAvatar(
                    photoUrl: _existingPhotoUrl,
                    bytes: _selectedPhoto?.bytes,
                    size: 104,
                  ),
                ),
                const SizedBox(height: CoetusSpace.sm),
                OutlinedButton.icon(
                  onPressed: _isSaving || _isPickingPhoto
                      ? null
                      : _pickProfilePhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    _isPickingPhoto
                        ? 'Fotoğraf seçiliyor…'
                        : 'Galeriden seç veya fotoğraf çek',
                  ),
                ),
                if (_selectedPhoto != null)
                  const Text(
                    'Yeni fotoğraf seçildi. Kaydetmek için Profili Güncelle düğmesine dokun.',
                    textAlign: TextAlign.center,
                  ),
                if (_selectedPhoto != null)
                  TextButton(
                    onPressed: _isSaving || _isPickingPhoto
                        ? null
                        : () => setState(() {
                            _selectedPhoto = null;
                            _uploadedPhotoUrl = null;
                            _errorMessage = null;
                          }),
                    child: const Text('Seçimi iptal et'),
                  ),
                const SizedBox(height: CoetusSpace.xxl),
                ElevatedButton(
                  onPressed: _isSaving || _isPickingPhoto ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CoetusPalette.purple,
                          ),
                        )
                      : const Text('Profili Güncelle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(TextTheme t, String text) {
    return Text(text, style: t.labelMedium);
  }
}
