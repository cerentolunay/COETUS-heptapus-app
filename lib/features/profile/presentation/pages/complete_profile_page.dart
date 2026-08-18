import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/coetus_tokens.dart';
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
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: CoetusSpace.xl,
            vertical: CoetusSpace.xl,
          ),
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
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CoetusColors.navy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: CoetusColors.oat,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Profilini Tamamla',
                      textAlign: TextAlign.center,
                      style: t.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Diğer kullanıcılar seni tanısın',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(color: CoetusColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: CoetusSpace.xxl + CoetusSpace.sm),
                // Error message
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
                // Display Name
                _buildFieldLabel(t, 'Display Name *'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  controller: _displayNameController,
                  validator: _validateDisplayName,
                  decoration: const InputDecoration(
                    hintText: 'örn: Alex Chen',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 18),
                // Bio
                _buildFieldLabel(t, 'Bio'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  controller: _bioController,
                  validator: _validateBio,
                  minLines: 3,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Kendini tanıt...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                // Location
                _buildFieldLabel(t, 'Lokasyon'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  controller: _locationController,
                  validator: _validateLocation,
                  decoration: const InputDecoration(
                    hintText: 'örn: İstanbul, Türkiye',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                // Photo URL
                _buildFieldLabel(t, 'Profil Fotoğrafı URL (isteğe bağlı)'),
                const SizedBox(height: CoetusSpace.sm),
                TextFormField(
                  controller: _photoUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/photo.jpg',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: CoetusSpace.xxl),
                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveProfile,
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CoetusColors.oat,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Kaydediliyor...'),
                          ],
                        )
                      : const Text('Profili Tamamla'),
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
                  child: const Text('Daha sonra atla'),
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
