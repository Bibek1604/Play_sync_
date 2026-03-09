import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_theme_provider.dart';

/// Camera Wrapper Widget
/// A reusable widget that wraps camera UI and manages visibility.
/// This follows clean architecture - UI layer only.
/// Usage:
/// ```dart
/// CameraWrapperWidget(
///   cameraWidget: MyCameraScreen(),
///   onHide: () => print('Camera hidden'),
///   onShow: () => print('Camera shown'),
/// )
/// ```
class CameraWrapperWidget extends ConsumerStatefulWidget {
  /// The actual camera widget to display when visible
  final Widget cameraWidget;

  /// Optional callback when camera is hidden
  final VoidCallback? onHide;

  /// Optional callback when camera is shown
  final VoidCallback? onShow;

  /// Widget to show when camera is hidden (optional)
  final Widget? hiddenPlaceholder;

  /// Whether to show control buttons
  final bool showControls;

  const CameraWrapperWidget({
    super.key,
    required this.cameraWidget,
    this.onHide,
    this.onShow,
    this.hiddenPlaceholder,
    this.showControls = true,
  });

  @override
  ConsumerState<CameraWrapperWidget> createState() =>
      _CameraWrapperWidgetState();
}

class _CameraWrapperWidgetState extends ConsumerState<CameraWrapperWidget> {
  @override
  void initState() {
    super.initState();
    // Initialize camera theme manager to start listening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(cameraThemeManagerProvider);
      }
    });
  }

  void _hideCamera() {
    if (!mounted) return;

    ref.read(cameraVisibilityProvider.notifier).hideCamera();
    widget.onHide?.call();
  }

  void _showCamera() {
    if (!mounted) return;

    ref.read(cameraVisibilityProvider.notifier).showCamera();
    widget.onShow?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(isCameraVisibleProvider);

    return Column(
      children: [
        // Control buttons (optional)
        if (widget.showControls) _buildControlButtons(isVisible),

        // Camera or placeholder
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isVisible
                ? widget.cameraWidget
                : _buildHiddenState(context),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(bool isVisible) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isVisible)
            ElevatedButton.icon(
              onPressed: _hideCamera,
              icon: const Icon(Icons.visibility_off),
              label: const Text('Hide Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _showCamera,
              icon: const Icon(Icons.visibility),
              label: const Text('Show Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHiddenState(BuildContext context) {
    if (widget.hiddenPlaceholder != null) {
      return widget.hiddenPlaceholder!;
    }

    return Container(
      key: const ValueKey('camera_hidden'),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 80,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Hidden',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'App switched to dark mode',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean dispose - no setState after dispose issues
    super.dispose();
  }
}

/// Simple Camera Control Buttons
/// Standalone control buttons that can be placed anywhere.
/// Useful when you don't want the full wrapper.
class CameraControlButtons extends ConsumerWidget {
  final VoidCallback? onHide;
  final VoidCallback? onShow;

  const CameraControlButtons({
    super.key,
    this.onHide,
    this.onShow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(isCameraVisibleProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isVisible)
            ElevatedButton.icon(
              onPressed: () {
                ref.read(cameraVisibilityProvider.notifier).hideCamera();
                onHide?.call();
              },
              icon: const Icon(Icons.visibility_off),
              label: const Text('Hide Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                ref.read(cameraVisibilityProvider.notifier).showCamera();
                onShow?.call();
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Show Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
