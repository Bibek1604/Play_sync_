import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/app/theme/app_colors.dart';
import 'package:play_sync_new/features/profile/presentation/state/profile_state.dart';
import 'package:play_sync_new/features/profile/presentation/viewmodel/profile_notifier.dart';

/// Edit Profile Page
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _favoriteGameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing profile data
    Future.microtask(() {
      final profile = ref.read(profileNotifierProvider).profile;
      if (profile != null) {
        _fullNameController.text = profile.fullName ?? '';
        _phoneController.text = profile.phoneNumber ?? '';
        _locationController.text = profile.location ?? '';
        
        if (profile.favouriteGame != null && profile.favouriteGame!.isNotEmpty) {
          _favoriteGameController.text = profile.favouriteGame!;
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _favoriteGameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        // Upload image immediately
        await ref.read(profileNotifierProvider.notifier).uploadProfilePicture(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        // Upload image immediately
        await ref.read(profileNotifierProvider.notifier).uploadProfilePicture(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = ref.read(profileNotifierProvider).profile;
      await ref.read(profileNotifierProvider.notifier).updateProfile(
            name: _fullNameController.text.trim(),
            number: _phoneController.text.trim(),
            favouriteGame: _favoriteGameController.text.trim(),
            place: _locationController.text.trim(),
            currentPassword: _oldPasswordController.text.isNotEmpty ? _oldPasswordController.text : null,
            changePassword: _newPasswordController.text.isNotEmpty ? _newPasswordController.text : null,
            avatar: profile?.profilePicture,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen to state changes
    ref.listen<ProfileState>(profileNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(profileNotifierProvider.notifier).clearError();
      }

      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(profileNotifierProvider.notifier).clearSuccess();
        
        // Navigate back after successful update
        if (!next.isUpdating && !next.isUploadingPicture) {
          Navigator.pop(context);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (profileState.isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDark
                                ? [AppColors.primaryDark, AppColors.primary]
                                : [AppColors.primary, AppColors.primaryLight],
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: kIsWeb
                                    ? Image.network(
                                        _selectedImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : profileState.profile?.profilePicture != null
                                ? ClipOval(
                                    child: Image.network(
                                      profileState.profile!.profilePicture!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.person, size: 60, color: Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: profileState.isUploadingPicture ? null : _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: profileState.isUploadingPicture
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Personal Info Section
                Text(
                  'Profile Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? AppColors.secondary : AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _favoriteGameController,
                  label: 'Favorite Game',
                  icon: Icons.videogame_asset,
                  isDark: isDark,
                  hint: 'e.g., God of War',
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on,
                  isDark: isDark,
                  hint: 'e.g., New York, USA',
                ),

                const SizedBox(height: 30),

                // Password Section
                Text(
                  'Security',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? AppColors.secondary : AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _oldPasswordController,
                  label: 'Current Password',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  obscureText: true,
                  hint: 'Enter current password to update',
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  icon: Icons.lock_reset,
                  isDark: isDark,
                  obscureText: true,
                  hint: 'Enter new password',
                ),

                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: profileState.isUpdating ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: profileState.isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
