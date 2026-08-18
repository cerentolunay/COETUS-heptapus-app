import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/coetus_tokens.dart';
import '../../data/repositories/profile_repository_factory.dart';
import '../../domain/models/profile_data.dart';
import '../../domain/repositories/profile_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileRepository _profileRepository =
      ProfileRepositoryFactory.create();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();

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
    _photoUrlController.dispose();
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
      _photoUrlController.text = profile.user.photoUrl ?? '';

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Profil yüklenemedi: $e';
      });
    }
  }

  String? _validateDisplayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Display name zorunludur';
    if (text.length < 2) return 'Display name en az 2 karakter olmalıdır';
    if (text.length > 50) return 'Display name en fazla 50 karakter olabilir';
    return null;
  }

  String? _validateBio(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 500) return 'Bio en fazla 500 karakter olabilir';
    return null;
  }

  String? _validateLocation(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 100) return 'Location en fazla 100 karakter olabilir';
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileData == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedUser = _profileData!.user.copyWith(
        name: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        photoUrl: _photoUrlController.text.trim(),
      );

      await _profileRepository.updateProfile(updatedUser);

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
        _errorMessage = 'Profil güncellenemedi: $e';
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
        body: Center(child: CircularProgressIndicator()),
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
                    Text('Edit Profile', style: t.headlineSmall),
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
                _buildFieldLabel(t, 'Display Name *'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  controller: _displayNameController,
                  validator: _validateDisplayName,
                  decoration: const InputDecoration(
                    hintText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 18),
                _buildFieldLabel(t, 'Bio'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  controller: _bioController,
                  validator: _validateBio,
                  minLines: 3,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Bio',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                _buildFieldLabel(t, 'Lokasyon'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  controller: _locationController,
                  validator: _validateLocation,
                  decoration: const InputDecoration(
                    hintText: 'Lokasyon',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                _buildFieldLabel(t, 'Profil Fotoğrafı URL'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  controller: _photoUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: CoetusSpace.xxl),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CoetusColors.oat,
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
