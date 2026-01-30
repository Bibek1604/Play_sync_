import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/profile/presentation/viewmodel/profile_notifier.dart';

/// Example: How to use the Profile Update feature
/// 
/// This file demonstrates various ways to update user profile
/// in the Play Sync application.

class ProfileUpdateExamples {
  
  /// Example 1: Update only text fields (no image)
  /// 
  /// This sends a JSON request to the backend
  static Future<void> updateTextFieldsOnly(WidgetRef ref) async {
    await ref.read(profileNotifierProvider.notifier).updateProfile(
      fullName: 'Bibek Pandey',
      phone: '9823482382',
      favouriteGame: 'Clash of Clans',
      place: 'Kathmandu',
    );
  }

  /// Example 2: Update profile picture only
  /// 
  /// This sends a multipart/form-data request with just the image
  static Future<void> updateProfilePictureOnly(
    WidgetRef ref,
    XFile selectedImage,
  ) async {
    await ref.read(profileNotifierProvider.notifier).updateProfile(
      profilePicture: selectedImage,
    );
  }

  /// Example 3: Update all fields including profile picture
  /// 
  /// This sends a multipart/form-data request with all data
  static Future<void> updateAllFields(
    WidgetRef ref,
    XFile selectedImage,
  ) async {
    await ref.read(profileNotifierProvider.notifier).updateProfile(
      fullName: 'Bibek Pandey',
      phone: '9823482382',
      favouriteGame: 'Clash of Clans',
      place: 'Kathmandu',
      profilePicture: selectedImage,
    );
  }

  /// Example 4: Change password
  /// 
  /// This requires current password for security
  static Future<void> changePassword(WidgetRef ref) async {
    await ref.read(profileNotifierProvider.notifier).updateProfile(
      currentPassword: 'oldPassword123',
      changePassword: 'newPassword456',
    );
  }

  /// Example 5: Update profile with password change
  /// 
  /// You can update profile data and change password in one request
  static Future<void> updateProfileAndChangePassword(
    WidgetRef ref,
    XFile? selectedImage,
  ) async {
    await ref.read(profileNotifierProvider.notifier).updateProfile(
      fullName: 'Bibek Pandey',
      phone: '9823482382',
      favouriteGame: 'Clash of Clans',
      place: 'Kathmandu',
      currentPassword: 'oldPassword123',
      changePassword: 'newPassword456',
      profilePicture: selectedImage,
    );
  }

  /// Example 6: Pick image and update profile
  /// 
  /// Complete flow: pick image, then update profile
  static Future<void> pickImageAndUpdateProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ImagePicker imagePicker = ImagePicker();
    
    // Pick image from gallery
    final XFile? image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      // Update profile with selected image
      await ref.read(profileNotifierProvider.notifier).updateProfile(
        profilePicture: image,
      );
    }
  }

  /// Example 7: Listen to profile state changes
  /// 
  /// This shows how to react to success/error states
  static Widget buildProfileUpdateListener(
    BuildContext context,
    WidgetRef ref,
    Widget child,
  ) {
    ref.listen(profileNotifierProvider, (previous, next) {
      // Handle errors
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(profileNotifierProvider.notifier).clearError();
      }

      // Handle success
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(profileNotifierProvider.notifier).clearSuccess();
      }
    });

    return child;
  }

  /// Example 8: Show loading state during update
  /// 
  /// This shows how to display loading indicator
  static Widget buildUpdateButton(WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);

    return ElevatedButton(
      onPressed: profileState.isUpdating
          ? null
          : () async {
              await ref.read(profileNotifierProvider.notifier).updateProfile(
                    fullName: 'Bibek Pandey',
                    phone: '9823482382',
                  );
            },
      child: profileState.isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Update Profile'),
    );
  }

  /// Example 9: Validate before updating
  /// 
  /// This shows how to validate form data before sending
  static Future<void> updateWithValidation(
    GlobalKey<FormState> formKey,
    WidgetRef ref,
    TextEditingController nameController,
    TextEditingController phoneController,
  ) async {
    if (formKey.currentState!.validate()) {
      await ref.read(profileNotifierProvider.notifier).updateProfile(
            fullName: nameController.text.trim(),
            phone: phoneController.text.trim(),
          );
    }
  }

  /// Example 10: Get current profile data
  /// 
  /// This shows how to access current profile
  static void getCurrentProfile(WidgetRef ref) {
    final profileState = ref.read(profileNotifierProvider);
    final profile = profileState.profile;

    if (profile != null) {
      debugPrint('User ID: ${profile.userId}');
      debugPrint('Full Name: ${profile.fullName}');
      debugPrint('Email: ${profile.email}');
      debugPrint('Phone: ${profile.phoneNumber}');
      debugPrint('Favorite Game: ${profile.favouriteGame}');
      debugPrint('Location: ${profile.location}');
      debugPrint('Profile Picture: ${profile.profilePicture}');
    }
  }
}

/// Example Widget: Complete Profile Update Form
class ExampleProfileUpdateForm extends ConsumerStatefulWidget {
  const ExampleProfileUpdateForm({super.key});

  @override
  ConsumerState<ExampleProfileUpdateForm> createState() =>
      _ExampleProfileUpdateFormState();
}

class _ExampleProfileUpdateFormState
    extends ConsumerState<ExampleProfileUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gameController = TextEditingController();
  final _locationController = TextEditingController();
  XFile? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(profileNotifierProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            favouriteGame: _gameController.text.trim(),
            place: _locationController.text.trim(),
            profilePicture: _selectedImage,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);

    // Listen to state changes
    ref.listen(profileNotifierProvider, (previous, next) {
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
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile Example')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImage != null
                      ? NetworkImage(_selectedImage!.path)
                      : null,
                  child: _selectedImage == null
                      ? const Icon(Icons.add_a_photo, size: 30)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Full Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Favorite Game
            TextFormField(
              controller: _gameController,
              decoration: const InputDecoration(
                labelText: 'Favorite Game',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Update Button
            ElevatedButton(
              onPressed: profileState.isUpdating ? null : _updateProfile,
              child: profileState.isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
