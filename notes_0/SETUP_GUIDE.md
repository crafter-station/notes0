# 📱 Voice Notes - Setup Guide

Complete setup guide for ultra-fast voice recording with volume buttons.

## 🚀 Quick Start

### 1. Build & Install

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build debug APK
flutter build apk --debug

# Install on device
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**Location:** `build/app/outputs/flutter-apk/app-debug.apk`

---

## 🔧 Critical Setup Steps

### ⚠️ Step 1: Allow Restricted Settings (REQUIRED for sideloaded APKs)

**This is the #1 reason the app doesn't work!**

If you installed the APK manually (not from Google Play), Android blocks Accessibility Services by default.

**How to fix:**

1. Open **Settings**
2. Go to **Apps** → **Voice Notes**
3. Tap the **⋮** (three dots) in the top-right corner
4. Select **"Allow restricted settings"**
5. Confirm

**Without this step, the accessibility service will appear enabled but won't actually work!**

---

### ✅ Step 2: Enable Accessibility Service

1. Open **Settings**
2. Go to **Accessibility**
3. Scroll to **Downloaded apps** or **Installed services**
4. Find and tap **Voice Notes**
5. Toggle the switch to **ON**
6. Read the security warning (it's normal for accessibility services)
7. Tap **Allow** or **OK**

**You should see:**
```
Voice Notes
ON
Allows you to start/stop voice recording by holding the Volume Up button...
```

---

### 📱 Step 3: Grant App Permissions

Open the app and grant these permissions when prompted:

- ✅ **Microphone** - For recording audio
- ✅ **Notifications** - For foreground service (optional but recommended)

---

## 🎯 How to Use

### Daily Usage (After Setup)

1. **Wake your phone** - Press Power button (screen can stay locked)
2. **Start recording** - Hold **Volume ↑** for **1 second**
   - Phone vibrates once (short) → Recording started ✅
3. **Speak** your voice note
4. **Stop recording** - Hold **Volume ↑** for **1 second** again
   - Phone vibrates twice → Recording saved ✅

**That's it!** No need to unlock, no need to open the app.

---

## 🔍 Troubleshooting

### ❌ Volume button does nothing

**Most common cause:** You didn't enable "Allow restricted settings"

1. Check: Settings → Apps → Voice Notes → ⋮ → Allow restricted settings
2. If that option doesn't exist, you installed from Play Store (good!)
3. Make sure Accessibility Service is ON
4. Restart the accessibility service:
   - Turn it OFF in Settings → Accessibility
   - Wait 3 seconds
   - Turn it back ON

### ❌ "Allow restricted settings" option doesn't exist

This means you installed from Google Play (or using `adb install` with special flags). This is actually good! You can skip Step 1.

### ❌ Volume still changes instead of recording

1. Check that accessibility service is truly enabled
2. Go to Settings → Accessibility → Voice Notes
3. You should see it's ON with a green indicator
4. Try holding the button for the full second (don't release early)

### ❌ Works but stops recording immediately

The long-press threshold is 1000ms (1 second). Make sure you're holding it long enough.

**To adjust the threshold:**
Edit `VolumeButtonAccessibilityService.kt`:
```kotlin
private val longPressThreshold = 1000L // Change to 500L for 0.5s, 1500L for 1.5s
```

### ❌ Permission denied errors

1. Open the app
2. Go to Settings tab
3. Grant all permissions shown
4. If permissions don't appear, go to Android Settings → Apps → Voice Notes → Permissions

---

## 🔒 Manufacturer-Specific Issues

Some manufacturers add extra restrictions:

### Samsung (One UI)

1. **Battery optimization:**
   - Settings → Apps → Voice Notes → Battery
   - Select **Unrestricted**

2. **Auto-start:**
   - Settings → Apps → Voice Notes → ⋮
   - Select **Allow background activity**

### Xiaomi (MIUI)

1. **Autostart:**
   - Settings → Apps → Manage apps → Voice Notes
   - Enable **Autostart**

2. **Battery saver:**
   - Settings → Battery → ⋮ → Battery saver
   - Add Voice Notes to whitelist

### Huawei (EMUI)

1. **Protected apps:**
   - Settings → Battery → Protected apps
   - Enable Voice Notes

2. **Accessibility:**
   - Sometimes requires enabling in Developer Options first

---

## 🧪 Testing the Setup

### Test 1: Accessibility Service

1. Lock your phone completely
2. Press Power to wake (don't unlock)
3. Hold Volume ↑ for 1 full second
4. **Expected:** Phone vibrates once
5. **If nothing happens:** Accessibility service not working (see troubleshooting)

### Test 2: Recording

1. Hold Volume ↑ for 1 second → Vibrate
2. Say "Testing one two three"
3. Hold Volume ↑ for 1 second again → Double vibrate
4. Unlock phone and open app
5. You should see the recording in the list

### Test 3: Upload

1. Configure API endpoint in Settings
2. Make a test recording
3. Tap "Upload Now" from home screen
4. Check your server logs

---

## 📋 System Requirements

- **Android:** 8.0 (API 26) or higher
- **Recommended:** Android 12+ for best compatibility
- **Storage:** ~50MB for app + recordings

---

## 🔐 Privacy & Security

### What the Accessibility Service does:

- ✅ Listens only to Volume Up button presses
- ✅ Only checks if button is held for 1 second
- ❌ Does NOT read screen content
- ❌ Does NOT access other apps
- ❌ Does NOT send any data

### Why Android shows a security warning:

Accessibility Services CAN access screen content (for apps helping blind users, etc.), so Android warns you. Our service doesn't use those features, but Android shows the warning anyway.

**You can verify:** Check the source code in `VolumeButtonAccessibilityService.kt` - it only implements `onKeyEvent()`.

---

## 🎨 Customization

### Change vibration pattern

Edit `VolumeButtonAccessibilityService.kt`:

```kotlin
// Start recording vibration
vibratePattern(longArrayOf(0, 100)) // Current: one short buzz

// Stop recording vibration
vibratePattern(longArrayOf(0, 100, 100, 100)) // Current: two short buzzes

// Examples:
// Long buzz: longArrayOf(0, 500)
// Triple buzz: longArrayOf(0, 100, 100, 100, 100, 100)
// Pattern: longArrayOf(0, 100, 50, 200, 50, 100)
```

### Change long-press duration

Edit `VolumeButtonAccessibilityService.kt`:

```kotlin
private val longPressThreshold = 1000L // milliseconds

// Examples:
// 0.5 seconds: 500L
// 0.8 seconds: 800L
// 1.5 seconds: 1500L
// 2 seconds: 2000L
```

---

## 📞 Support

### App not working?

1. Check this guide's troubleshooting section
2. Verify all setup steps completed
3. Test on a different Android device if possible
4. Check Android version (must be 8.0+)

### Found a bug?

Check the source code - it's well commented and structured.

---

## 🏗️ Architecture

```
User presses Volume ↑
        ↓
VolumeButtonAccessibilityService (Android)
        ↓
Detects 1-second hold
        ↓
RecordingManager.startRecording()
        ↓
MediaRecorder starts
        ↓
Vibration feedback
        ↓
Save to local storage
        ↓
WorkManager schedules upload (on Wi-Fi)
        ↓
Flutter UploadService uploads via HTTP
```

---

## ✨ Tips

1. **Practice the gesture** - Hold for full 1 second, don't release early
2. **One-handed operation** - Use thumb to press Volume ↑
3. **In meetings** - Quick way to capture ideas without being obvious
4. **While driving** - Safer than typing (still focus on road!)
5. **Set up API** - Auto-upload makes recordings accessible everywhere

---

**🎉 Enjoy ultra-fast voice notes!**
