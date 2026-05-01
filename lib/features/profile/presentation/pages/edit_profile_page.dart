import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  static const Color _bgStart = Color(0xFF0B1120);
  static const Color _bgMiddle = Color(0xFF0F172A);
  static const Color _bgEnd = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

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
        _errorMessage = 'Failed to load profile: $e';
      });
    }
  }

  String? _validateDisplayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Display name is required';
    if (text.length < 2) return 'Display name must be at least 2 characters';
    if (text.length > 50) return 'Display name must be at most 50 characters';
    return null;
  }

  String? _validateBio(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 500) return 'Bio must be at most 500 characters';
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
      return Scaffold(
        backgroundColor: _bgMiddle,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgStart, _bgMiddle, _bgEnd],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null && _profileData == null) {
      return Scaffold(
        backgroundColor: _bgMiddle,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgStart, _bgMiddle, _bgEnd],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
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
        ),
      );
    }

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isSaving ? null : () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            0xFFFF6B6B,
                          ).withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildFieldLabel('Display Name *'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _displayNameController,
                    hintText: 'Display name',
                    icon: Icons.person_outline,
                    validator: _validateDisplayName,
                  ),
                  const SizedBox(height: 18),
                  _buildFieldLabel('Bio'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _bioController,
                    hintText: 'Bio',
                    icon: Icons.description_outlined,
                    minLines: 3,
                    maxLines: 3,
                    validator: _validateBio,
                  ),
                  const SizedBox(height: 18),
                  _buildFieldLabel('Lokasyon'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _locationController,
                    hintText: 'Lokasyon',
                    icon: Icons.location_on_outlined,
                    validator: _validateLocation,
                  ),
                  const SizedBox(height: 18),
                  _buildFieldLabel('Profil Fotoğrafı URL'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _photoUrlController,
                    hintText: 'https://...',
                    icon: Icons.image_outlined,
                  ),
                  const SizedBox(height: 28),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.60),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.50)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _cyan),
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

  Widget _buildSaveButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_purple, _cyan]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Profili Güncelle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
