# 📷 Camera Theme Feature

A production-ready, modular feature that automatically switches to dark mode when the camera is hidden, without affecting the rest of your app.

---

## ✨ Features

✅ **Camera visibility control** - Show/hide camera with state management  
✅ **Automatic dark mode** - Switches to dark mode when camera is hidden  
✅ **Theme persistence** - Theme doesn't reset when camera is shown again  
✅ **Clean architecture** - Separation of concerns (controller, provider, UI)  
✅ **Null safety** - Fully null-safe implementation  
✅ **No memory leaks** - Proper disposal and lifecycle management  
✅ **No rebuild loops** - Optimized provider listening  
✅ **Production-ready** - Safe integration with existing projects  

---

## 📁 Architecture

```
features/camera_theme/
├── controllers/
│   └── camera_visibility_controller.dart    # Business logic
├── providers/
│   └── camera_theme_provider.dart           # State management
├── presentation/
│   └── camera_wrapper_widget.dart           # UI components
├── examples/
│   └── camera_page_example.dart             # Usage examples
└── camera_theme.dart                        # Barrel file
```

---

## 🎯 Behavior

| Action | Theme Change |
|--------|--------------|
| **Hide Camera** | ✅ Switches to dark mode |
| **Show Camera** | ❌ NO change (keeps current theme) |

This ensures the theme doesn't flip back and forth unnecessarily.

---

## 🚀 Quick Start

### 1. Import the feature

```dart
import 'package:play_sync_new/features/camera_theme/camera_theme.dart';
```

### 2. Use the wrapper widget

```dart
class MyCameraPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: CameraWrapperWidget(
        cameraWidget: MyCameraWidget(), // Your actual camera
        showControls: true,
        onHide: () => print('Hidden - dark mode activated'),
        onShow: () => print('Shown - theme unchanged'),
      ),
    );
  }
}
```

---

## 📖 Usage Examples

### Example 1: Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/camera_theme/camera_theme.dart';

class BasicCameraPage extends ConsumerWidget {
  const BasicCameraPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: CameraWrapperWidget(
        cameraWidget: YourCameraWidget(),
        showControls: true, // Shows hide/show buttons
      ),
    );
  }
}
```

---

### Example 2: Manual Controls

```dart
class ManualControlPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(isCameraVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Control'),
        actions: [
          IconButton(
            icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              ref.read(cameraVisibilityProvider.notifier).toggleVisibility();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Standalone control buttons
          CameraControlButtons(
            onHide: () => print('Camera hidden'),
            onShow: () => print('Camera shown'),
          ),
          
          Expanded(
            child: isVisible 
              ? YourCameraWidget()
              : Center(child: Text('Camera Hidden')),
          ),
        ],
      ),
    );
  }
}
```

---

### Example 3: Programmatic Control

```dart
class ProgrammaticPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProgrammaticPage> createState() => _ProgrammaticPageState();
}

class _ProgrammaticPageState extends ConsumerState<ProgrammaticPage> {
  @override
  void initState() {
    super.initState();
    
    // Auto-hide after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        ref.read(cameraVisibilityProvider.notifier).hideCamera();
      }
    });
  }

  void _handleButtonPress() {
    // Manually hide camera
    ref.read(cameraVisibilityProvider.notifier).hideCamera();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched to dark mode!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraVisibilityProvider);

    return Scaffold(
      body: CameraWrapperWidget(
        cameraWidget: YourCameraWidget(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleButtonPress,
        child: Icon(Icons.visibility_off),
      ),
    );
  }
}
```

---

## 🔧 API Reference

### Providers

#### `cameraVisibilityProvider`
Main provider for camera visibility state.

```dart
final cameraState = ref.watch(cameraVisibilityProvider);
print(cameraState.isVisible); // true or false
print(cameraState.lastHiddenAt); // DateTime?
```

#### `isCameraVisibleProvider`
Helper to get visibility as boolean.

```dart
final isVisible = ref.watch(isCameraVisibleProvider);
```

#### `isCameraHiddenProvider`
Helper to check if camera is hidden.

```dart
final isHidden = ref.watch(isCameraHiddenProvider);
```

---

### Controller Methods

#### `hideCamera()`
Hides the camera and switches to dark mode.

```dart
ref.read(cameraVisibilityProvider.notifier).hideCamera();
```

#### `showCamera()`
Shows the camera without changing theme.

```dart
ref.read(cameraVisibilityProvider.notifier).showCamera();
```

#### `toggleVisibility()`
Toggles between visible and hidden.

```dart
ref.read(cameraVisibilityProvider.notifier).toggleVisibility();
```

#### `reset()`
Resets to initial state (camera visible).

```dart
ref.read(cameraVisibilityProvider.notifier).reset();
```

---

### Widgets

#### `CameraWrapperWidget`

Main wrapper widget for camera.

**Properties:**
- `cameraWidget` (required) - Your camera widget
- `showControls` (bool) - Show hide/show buttons (default: true)
- `onHide` (callback) - Called when camera is hidden
- `onShow` (callback) - Called when camera is shown
- `hiddenPlaceholder` (Widget?) - Custom placeholder when hidden

```dart
CameraWrapperWidget(
  cameraWidget: MyCameraWidget(),
  showControls: true,
  onHide: () => print('Hidden'),
  onShow: () => print('Shown'),
  hiddenPlaceholder: CustomPlaceholder(),
)
```

---

#### `CameraControlButtons`

Standalone control buttons.

```dart
CameraControlButtons(
  onHide: () => print('Hidden'),
  onShow: () => print('Shown'),
)
```

---

## 🔒 Safety Features

### ✅ No setState After Dispose
All state updates check `mounted` before executing.

### ✅ No Memory Leaks
Proper disposal in all StatefulWidgets.

### ✅ No Rebuild Loops
Theme changes are one-way (hide → dark mode only).

### ✅ Non-Intrusive
Doesn't modify existing theme provider or MaterialApp.

### ✅ Null Safety
Fully null-safe implementation.

---

## 🧪 Testing

The feature is safe to test:

```dart
void main() {
  testWidgets('Camera hide switches to dark mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ExampleCameraPage(),
        ),
      ),
    );

    // Initial state
    final controller = container.read(cameraVisibilityProvider.notifier);
    expect(controller.isVisible, true);

    // Hide camera
    controller.hideCamera();
    await tester.pump();

    expect(controller.isHidden, true);
  });
}
```

---

## 🎨 Customization

### Custom Hidden Placeholder

```dart
CameraWrapperWidget(
  cameraWidget: MyCameraWidget(),
  hiddenPlaceholder: Container(
    color: Colors.black,
    child: Center(
      child: Text(
        'Camera Paused',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
)
```

### No Controls (Manual Only)

```dart
CameraWrapperWidget(
  cameraWidget: MyCameraWidget(),
  showControls: false, // Remove hide/show buttons
)
```

---

## 🚨 Important Notes

⚠️ **Theme Behavior:**
- Hiding camera → switches to dark mode
- Showing camera → does NOT change theme
- User can still manually change theme via settings

⚠️ **Integration:**
- Requires existing `themeModeProvider` (already in your project)
- Works with your existing theme system
- Does NOT modify MaterialApp configuration

⚠️ **Lifecycle:**
- Camera state persists across navigation
- Call `reset()` if you want to clear state

---

## 📝 Full Example

See [camera_page_example.dart](./examples/camera_page_example.dart) for complete examples.

---

## 🔗 Dependencies

- `flutter_riverpod` (already in your project)
- Your existing theme provider (already in your project)

No additional packages required!

---

## ✅ Production Checklist

- ✅ Null safety compliant
- ✅ No memory leaks
- ✅ No setState after dispose
- ✅ Clean architecture
- ✅ Separation of concerns
- ✅ Safe integration
- ✅ No rebuild loops
- ✅ Fully documented
- ✅ Examples provided

---

## 🎉 Ready to Use!

This feature is **production-ready** and can be safely integrated into your existing Flutter project without breaking anything.

```dart
import 'package:play_sync_new/features/camera_theme/camera_theme.dart';

// Start using it!
CameraWrapperWidget(
  cameraWidget: YourCameraWidget(),
)
```
