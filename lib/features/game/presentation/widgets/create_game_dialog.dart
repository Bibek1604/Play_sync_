import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_list_provider.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';

/// Create Game Dialog
///
/// Shows a form dialog to create a new game
class CreateGameDialog extends ConsumerStatefulWidget {
  final Function(String gameId)? onGameCreated;

  const CreateGameDialog({
    super.key,
    this.onGameCreated,
  });

  @override
  ConsumerState<CreateGameDialog> createState() => _CreateGameDialogState();
}

class _CreateGameDialogState extends ConsumerState<CreateGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '10');
  
  DateTime? _selectedEndTime;
  XFile? _selectedImage;
  Uint8List? _webImageBytes; // For web preview
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _webImageBytes = bytes;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(date),
      );

      if (time != null) {
        setState(() {
          _selectedEndTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEndTime == null) {
      _showError('Please select an end time for the game');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse tags from comma-separated string
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Parse max players
      final maxPlayers = int.tryParse(_maxPlayersController.text) ?? 10;

      // Call create game API
      final gameId = await ref.read(gameListProvider.notifier).createGame(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: tags,
        maxPlayers: maxPlayers,
        endTime: _selectedEndTime!,
        imageFile: _selectedImage,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onGameCreated?.call(gameId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game "${_titleController.text}" created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.paddingMD,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                      AppSpacing.gapHorizontalSM,
                      Text(
                        'Create New Game',
                        style: AppTypography.h2,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalMD,

                  // Image Picker
                  if (_selectedImage != null && _webImageBytes != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _webImageBytes!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _webImageBytes = null;
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _isLoading ? null : _pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                            AppSpacing.gapVerticalSM,
                            Text(
                              'Add Game Image (Optional)',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  AppSpacing.gapVerticalMD,

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Game Title *',
                      hintText: 'e.g., Friday Night Soccer',
                      prefixIcon: Icon(Icons.title),
                    ),
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a game title';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapVerticalMD,

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Tell players about your game...',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    enabled: !_isLoading,
                  ),
                  AppSpacing.gapVerticalMD,

                  // Tags Field
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags',
                      hintText: 'e.g., Soccer, Casual, Beginners',
                      prefixIcon: Icon(Icons.tag),
                      suffixIcon: Tooltip(
                        message: 'Separate tags with commas',
                        child: Icon(Icons.info_outline),
                      ),
                    ),
                    enabled: !_isLoading,
                  ),
                  AppSpacing.gapVerticalMD,

                  // Max Players Field
                  TextFormField(
                    controller: _maxPlayersController,
                    decoration: const InputDecoration(
                      labelText: 'Max Players *',
                      hintText: 'e.g., 10',
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter max players';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 2) {
                        return 'Must be at least 2 players';
                      }
                      if (number > 100) {
                        return 'Cannot exceed 100 players';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapVerticalMD,

                  // End Time Picker
                  InkWell(
                    onTap: _isLoading ? null : _selectEndTime,
                    child: Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedEndTime == null
                              ? AppColors.error.withOpacity(0.5)
                              : (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: _selectedEndTime == null
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                          AppSpacing.gapHorizontalSM,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Time *',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                AppSpacing.gapVerticalXS,
                                Text(
                                  _selectedEndTime != null
                                      ? _formatDateTime(_selectedEndTime!)
                                      : 'Select when the game ends',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _selectedEndTime == null
                                        ? AppColors.error
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalLG,

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Game'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$month $day, $year at $hour:$minute';
  }
}
