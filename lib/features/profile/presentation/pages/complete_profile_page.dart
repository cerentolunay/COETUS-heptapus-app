import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/services/profile_completion_service.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileCompletionService _profileService = ProfileCompletionService();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  static const Color _bgStart = Color(0xFF0B1120);
  static const Color _bgMiddle = Color(0xFF0F172A);
  static const Color _bgEnd = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  String? _validateDisplayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Display name zorunludur';
    if (name.length < 2) return 'Display name en az 2 karakter olmalıdır';
    if (name.length > 50) return 'Display name en fazla 50 karakter olabilir';
    return null;
  }

  String? _validateBio(String? value) {
    final bio = value?.trim() ?? '';
    if (bio.length > 500) return 'Bio en fazla 500 karakter olabilir';
    return null;
  }

  String? _validateLocation(String? value) {
    final location = value?.trim() ?? '';
    if (location.length > 100) return 'Location en fazla 100 karakter olabilir';
    return null;
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _profileService.completeProfile(
        displayName: _displayNameController.text,
        bio: _bioController.text,
        location: _locationController.text,
        photoUrl: _photoUrlController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil tamamlandı!')));

      // GoRouter redirect'i otomatik yapacak, ama emin olmak için açıkça gidelim
      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Profil kaydedilirken hata oluştu: $e';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Header
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_purple, _cyan],
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Profilini Tamamla',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Diğer kullanıcılar seni tanısın',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.30),
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
                  // Display Name
                  _buildFieldLabel('Display Name *'),
                  const SizedBox(height: 8),
                  _buildTextInput(
                    controller: _displayNameController,
                    hintText: 'örn: Alex Chen',
                    prefixIcon: Icons.person_outline,
                    validator: _validateDisplayName,
                  ),
                  const SizedBox(height: 18),
                  // Bio
                  _buildFieldLabel('Bio'),
                  const SizedBox(height: 8),
                  _buildTextInput(
                    controller: _bioController,
                    hintText: 'Kendini tanıt...',
                    prefixIcon: Icons.description_outlined,
                    minLines: 3,
                    maxLines: 3,
                    validator: _validateBio,
                  ),
                  const SizedBox(height: 18),
                  // Location
                  _buildFieldLabel('Lokasyon'),
                  const SizedBox(height: 8),
                  _buildTextInput(
                    controller: _locationController,
                    hintText: 'örn: İstanbul, Türkiye',
                    prefixIcon: Icons.location_on_outlined,
                    validator: _validateLocation,
                  ),
                  const SizedBox(height: 18),
                  // Photo URL
                  _buildFieldLabel('Profil Fotoğrafı URL (isteğe bağlı)'),
                  const SizedBox(height: 8),
                  _buildTextInput(
                    controller: _photoUrlController,
                    hintText: 'https://example.com/photo.jpg',
                    prefixIcon: Icons.image_outlined,
                  ),
                  const SizedBox(height: 28),
                  // Submit Button
                  _buildGradientButton(
                    text: _isLoading ? 'Kaydediliyor...' : 'Profili Tamamla',
                    onTap: _isLoading ? null : _handleSaveProfile,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  // Skip button (optional)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            // Daha sonra atla - fakat guard onu /complete-profile'a geri gönderecek
                            // Bu yüzden bu buton görünür fakat işlevli değil
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profili tamamlaman gerekiyor devam etmek için',
                                ),
                              ),
                            );
                          },
                    child: Text(
                      'Daha sonra atla',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 14,
                      ),
                    ),
                  ),
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
        color: Colors.white.withOpacity(0.50),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 14,
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 12),
        prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.50)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x8006B6D4)),
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

  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_purple, _cyan]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(124, 58, 237, 0.30),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            if (isLoading) const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
