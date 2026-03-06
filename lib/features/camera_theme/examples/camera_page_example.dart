import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../camera_theme.dart';

/// Example Camera Page
/// 
/// Demonstrates how to use the CameraWrapperWidget safely.
/// This is a complete, production-ready example.
class ExampleCameraPage extends ConsumerWidget {
  const ExampleCameraPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera with Theme Control'),
        centerTitle: true,
      ),
      body: CameraWrapperWidget(
        // Your actual camera widget goes here
        cameraWidget: const _DemoCameraWidget(),

        // Optional callbacks
        onHide: () {
          debugPrint('Camera hidden - app switched to dark mode');
        },
        onShow: () {
          debugPrint('Camera shown - theme unchanged');
        },

        // Show control buttons
        showControls: true,
      ),
    );
  }
}

/// Demo Camera Widget (Replace with your actual camera)
class _DemoCameraWidget extends StatelessWidget {
  const _DemoCameraWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('camera_visible'),
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Text(
                'Replace this with your actual camera widget\n(camera_plugin, camera package, etc.)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 2: Manual Control
/// 
/// Shows how to use camera controls without the wrapper.
class ExampleManualControlPage extends ConsumerWidget {
  const ExampleManualControlPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(isCameraVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Camera Control'),
      ),
      body: Column(
        children: [
          // Manual control buttons
          CameraControlButtons(
            onHide: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Switched to dark mode!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onShow: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Camera shown - theme unchanged'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          // Your camera widget
          Expanded(
            child: isVisible
                ? const _DemoCameraWidget()
                : const Center(
                    child: Text('Camera is hidden'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Example 3: Programmatic Control
/// 
/// Shows how to control camera visibility from code.
class ExampleProgrammaticPage extends ConsumerStatefulWidget {
  const ExampleProgrammaticPage({super.key});

  @override
  ConsumerState<ExampleProgrammaticPage> createState() =>
      _ExampleProgrammaticPageState();
}

class _ExampleProgrammaticPageState
    extends ConsumerState<ExampleProgrammaticPage> {
  @override
  void initState() {
    super.initState();

    // Example: Auto-hide camera after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        ref.read(cameraVisibilityProvider.notifier).hideCamera();
        _showMessage('Camera auto-hidden after 5 seconds');
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleCamera() {
    ref.read(cameraVisibilityProvider.notifier).toggleVisibility();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraVisibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programmatic Control'),
        actions: [
          IconButton(
            icon: Icon(
              cameraState.isVisible ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _toggleCamera,
            tooltip: cameraState.isVisible ? 'Hide Camera' : 'Show Camera',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Camera Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Visible: ${cameraState.isVisible}'),
                  if (cameraState.lastHiddenAt != null)
                    Text('Last Hidden: ${cameraState.lastHiddenAt}'),
                  if (cameraState.lastShownAt != null)
                    Text('Last Shown: ${cameraState.lastShownAt}'),
                ],
              ),
            ),
          ),

          // Camera widget
          Expanded(
            child: CameraWrapperWidget(
              cameraWidget: const _DemoCameraWidget(),
              showControls: true,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCamera,
        child: Icon(
          cameraState.isVisible ? Icons.visibility_off : Icons.visibility,
        ),
      ),
    );
  }
}
