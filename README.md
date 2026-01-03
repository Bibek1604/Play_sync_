# play_sync_new

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
"# playsync-_______" 

## Run on Mobile & Tablet (Windows)

### Prerequisites
- Install Flutter (stable) and Android Studio.
- Accept Android licenses: `flutter doctor --android-licenses`.
- Ensure an AVD (Android Virtual Device) is created (e.g., Pixel 7 or Pixel Tablet).

### Emulator
1. List emulators: `flutter emulators`
2. Launch an emulator: `flutter emulators --launch Pixel_7`
3. Run the app on the emulator: `flutter run -d Pixel_7`

If launch fails:
- Open Android Studio > Device Manager, ensure the AVD exists and is started.
- Verify the exact AVD id from `flutter emulators` and use that id.
- Update emulator & platform tools via Android Studio.
- Try: `emulator -list-avds` and start via Device Manager.

### Physical Android Device
1. Enable Developer Options and USB debugging.
2. Install OEM USB driver (Windows) if required.
3. Connect the device; verify: `flutter devices`
4. Run: `flutter run -d <device_id>`

### Tablet Responsiveness
This app uses simple breakpoints to adapt layouts for tablets. See `lib/core/ui/responsive.dart`.

## Sprint Workflow & Commits
- We target 10 commits per sprint (minimum), across Sprint 1–3.
- Commits are scoped and meaningful: responsiveness, docs, small improvements, and fixes.
- Recommended: work on `sprint-1`, `sprint-2`, `sprint-3` branches and merge to `main` after review.

