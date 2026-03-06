# eSewa Mobile SDK Setup Guide for PlaySync

This guide explains how to set up the eSewa Mobile SDK (native payment solution) for the PlaySync tournament payment system.

## ⚠️ Current Status

**The eSewa SDK is NOT YET INSTALLED** - The app will build and run, but payments will show an error message until you complete the setup below.

The code is ready for eSewa integration - you just need to download the SDK and uncomment a few lines.

## ✅ Changes Made

1. ✅ Added `esewa_flutter_sdk` dependency slot in `pubspec.yaml` (commented out)
2. ✅ Created `EsewaService` with fallback mode (works without SDK)
3. ✅ Created Riverpod provider for eSewa service
4. ✅ Updated tournament payment flow to use SDK when available
5. ✅ App builds and runs without SDK (shows error on payment)

## 🚀 Quick Start (When Ready to Enable Payments)

### Option 1: Run Without eSewa (Current Setup ✅)

The app runs perfectly but payments will show:
> "eSewa SDK not installed. Please download and configure the SDK to enable payments."

This is fine for testing other features!

### Option 2: Enable eSewa Payments (Follow steps below)

When you're ready to enable tournament payments, follow the complete setup below.

---

## 📥 Complete eSewa Setup (5 Steps)

### Step 1: Download the eSewa SDK

1. Download the SDK from the official eSewa drive link (contact eSewa for access)
2. Extract the zip file
3. Copy the **entire** `esewa_flutter_sdk` folder to your **project root**:

```
play_sync_new/
├── android/
├── ios/
├── lib/
├── esewa_flutter_sdk/     ← Copy here (should contain ios/, android/, lib/ folders)
├── pubspec.yaml
└── ...
```

### Step 2: Uncomment SDK in pubspec.yaml

Open `pubspec.yaml` and find these lines (around line 109):

```yaml
# eSewa Native Mobile SDK for payment
# TODO: Download SDK from eSewa and extract to project root, then uncomment
# esewa_flutter_sdk:
#   path: ./esewa_flutter_sdk
```

**Uncomment the last two lines:**

```yaml
# eSewa Native Mobile SDK for payment
esewa_flutter_sdk:
  path: ./esewa_flutter_sdk
```

Then run:
```bash
flutter pub get
```

### Step 3: Uncomment SDK Imports in EsewaService

Open `lib/core/services/esewa_service.dart` and uncomment lines 2-5:

**Before:**
```dart
// TODO: Uncomment when eSewa SDK is downloaded and added to project
// import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
// import 'package:esewa_flutter_sdk/models/esewa_config.dart';
// import 'package:esewa_flutter_sdk/models/esewa_payment.dart';
// import 'package:esewa_flutter_sdk/models/esewa_payment_success_result.dart';
```

**After:**
```dart
// eSewa SDK imports
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/models/esewa_config.dart';
import 'package:esewa_flutter_sdk/models/esewa_payment.dart';
import 'package:esewa_flutter_sdk/models/esewa_payment_success_result.dart';
```

### Step 4: Replace Fallback Implementation

In the same file (`esewa_service.dart`), find the `initiatePayment` method around line 36.

**Replace the fallback implementation** with the commented native SDK code:

1. **Delete** the fallback error message (lines ~47-56)
2. **Uncomment** the native SDK implementation (around lines 60-95)
3. Update the return type from `Function(dynamic)` to `Function(EsewaPaymentSuccessResult)`
4. Update `_onPaymentSuccess` type from `Function(dynamic)?` to `Function(EsewaPaymentSuccessResult)?`
5. Uncomment the actual implementation in `_handlePaymentSuccess` method

**Or simply download the full implementation from the eSewa documentation.**

### Step 5: Configure Android/iOS (If Needed)

#### Android Configuration ✅
Already done! Your AndroidManifest.xml has:
- ✅ Internet permission
- ✅ AppCompat theme support

#### iOS Configuration (If building for iOS)

**For Simulator/Testing:**
```bash
# Copy ios folder from SDK's IOS_SIMULATOR directory
cp -r /path/to/sdk/IOS_SIMULATOR/ios esewa_flutter_sdk/ios
cd ios
pod install
cd ..
```

**For Release/App Store:**
```bash
# Copy ios folder from SDK's IOS_RELEASE directory
cp -r /path/to/sdk/IOS_RELEASE/ios esewa_flutter_sdk/ios
cd ios
pod install
cd ..
```

⚠️ **Don't mix simulator and release frameworks!**

---

## 🎯 Verify Setup

After completing all steps, run:

```bash
flutter clean
flutter pub get
flutter run -d 4363ed64
```

### Test Payment Flow:
1. Navigate to Tournaments
2. Click "Pay" on a tournament
3. **Native eSewa payment sheet should appear** (not an error)
4. Complete test payment with test credentials
5. Should auto-redirect to chat

---

## 📱 Tournament Payment Flow (Native SDK)

### Before (Browser-based):
1. User clicks "Pay" button
2. Opens eSewa payment in external browser
3. User completes payment in browser
4. Returns to app manually
5. App verifies payment

### After (Native SDK):
1. User clicks "Pay" button → **Native eSewa Payment Sheet appears**
2. User enters payment details in native UI
3. **Automatic callback on success/failure**
4. **Auto-redirects to chat after verification**
5. No browser involvement

## 🔑 Test Credentials (Already in EsewaService)

```
CLIENT_ID: JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R
SECRET_KEY: BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==
Environment: Environment.test
```

**To use LIVE credentials:**
- Update `EsewaService` with your live credentials from eSewa
- Change `Environment.test` to `Environment.live` in `initiatePayment()` method

## 💳 Payment Flow Implementation

The payment flow is implemented in:

- **File:** `lib/features/tournament/presentation/pages/tournament_detail_page.dart`
- **Method:** `_initiatePayment()`

### Key Callbacks:

1. **onSuccess** - Payment successful
   - Verifies transaction with backend
   - Refreshes tournament data
   - Auto-navigates to chat

2. **onFailure** - Payment failed
   - Shows error message
   - User can retry

3. **onCancellation** - User cancelled payment
   - Shows cancellation message
   - Allows retry

## 🔍 Transaction Verification

After successful payment, the app:

1. Calls `verifyPayment()` from tournament payment provider
2. Backend verifies using eSewa's verification API
3. Checks transaction status = 'COMPLETE'
4. Grants chat access

### eSewa Verification API (Server-side):

```
GET https://rc.esewa.com.np/mobile/transaction?txnRefId={refId}
```

(Remove 'rc' for live environment)

## ⚙️ Configuration Files Modified

### 1. `pubspec.yaml`
- ✅ Added eSewa Flutter SDK dependency

### 2. `android/app/src/main/AndroidManifest.xml`
- ✅ Already has Internet permission

### 3. `android/app/build.gradle.kts`
- ✅ Already uses AGP 7+ and Kotlin 1.5+

## 🐛 Troubleshooting

### "esewa_flutter_sdk not found"
- Ensure the folder is in your project root
- Run `flutter pub get`
- Run `flutter clean && flutter pub get`

### iOS build fails with "import esewa_flutter_sdk"
- Ensure you copied the correct `ios` folder for your build type
- Run `pod install` in the ios directory
- Restart Xcode

### Payment callbacks not triggering
- Check that INTERNET permission is granted
- Ensure you're using the correct test credentials
- Check debug logs: `flutter run | grep eSewa`

### Transaction verification fails
- Backend needs to call eSewa verification API with proper credentials
- Check that `refId` from SDK matches backend verification

## 📝 Environment Variables

To use live credentials safely:

Create a `.env` file (not in git):

```
ESEWA_CLIENT_ID_LIVE=your_live_client_id
ESEWA_SECRET_KEY_LIVE=your_live_secret_key
```

Then update `EsewaService` to read from environment.

## ✨ Features

- ✅ Native payment UI (no browser redirect)
- ✅ Native success/failure/cancellation callbacks
- ✅ Automatic transaction verification
- ✅ Auto-navigation to chat after payment
- ✅ Test environment pre-configured
- ✅ Supports both TEST and LIVE environments
- ✅ Graceful error handling with user feedback

## 🔒 Security Notes

1. **Never hardcode live credentials** - Use environment variables or secure backend
2. **Always verify on backend** - Don't trust only client-side verification
3. **Use HTTPS** - All API calls should be over HTTPS
4. **Transaction Reference** - Store `refId` for audit trail

## 📞 Support

For eSewa SDK issues, refer to their official documentation or contact eSewa support.

For PlaySync integration issues, check the implementation in `tournament_detail_page.dart`.
