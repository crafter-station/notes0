# Voice Notes - Ultra-Fast Voice Recording App

A professional Flutter Android application that enables ultra-fast voice note capture using physical volume buttons, even with the screen locked.

## Features

- **Physical Button Recording**: Double-press volume up button to start/stop recording
- **Background Recording**: Works even when screen is locked
- **Haptic Feedback**: Vibration patterns to confirm recording start/stop
- **Automatic Wi-Fi Upload**: Recordings automatically upload to your API when connected to Wi-Fi
- **Foreground Service**: Persistent service ensures reliability
- **Clean UI**: Modern Material Design 3 interface
- **Permission Management**: Streamlined permission handling

## Architecture

```
Flutter UI
    ↓
Platform Channel
    ↓
Android Foreground Service
    ↓
MediaSession (volume button detection)
    ↓
MediaRecorder (recording)
    ↓
Local Storage
    ↓
WorkManager (Wi-Fi upload)
```

## Technical Stack

### Flutter Side
- **Provider**: State management
- **Platform Channels**: Native communication
- **Material Design 3**: Modern UI

### Android Side (Kotlin)
- **Foreground Service**: Background operation
- **MediaSession**: Volume button detection
- **MediaRecorder**: Audio recording
- **WorkManager**: Background Wi-Fi uploads
- **OkHttp**: HTTP uploads

## Setup & Installation

### 1. Prerequisites
- Flutter SDK (3.11.0 or higher)
- Android SDK (minimum API 26)
- Android Studio or VS Code

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Build & Run
```bash
flutter run
```

## Usage

### First Time Setup
1. Launch the app
2. Grant required permissions:
   - Microphone (for recording)
   - Notifications (for foreground service)
3. Configure API endpoint in Settings
4. Start the service from home screen

### Recording Voice Notes
1. **Wake Device**: Press Power button
2. **Start Recording**: Double-press Volume ↑ button
3. **Confirmation**: Phone vibrates once (short)
4. **Speak**: Record your voice note
5. **Stop Recording**: Double-press Volume ↑ button again
6. **Confirmation**: Phone vibrates twice (double)
7. **Auto-Upload**: Recording uploads automatically when on Wi-Fi

### Managing Recordings
- **View All**: Home screen shows all pending recordings
- **Delete**: Swipe left on any recording
- **Manual Upload**: Tap "Upload Now" button
- **Refresh**: Pull down to refresh list

## File Structure

```
lib/
├── main.dart                       # App entry point
├── models/
│   ├── recording.dart             # Recording data model
│   └── upload_status.dart         # Upload status model
├── providers/
│   └── recording_provider.dart    # State management
├── screens/
│   ├── home_screen.dart          # Main UI
│   └── settings_screen.dart      # Settings & configuration
└── services/
    └── recording_service.dart    # Platform channel service

android/app/src/main/kotlin/com/example/notes_0/
├── MainActivity.kt                # Platform channel handler
├── VolumeButtonRecordingService.kt # Foreground service
├── RecordingManager.kt           # Audio recording logic
└── AudioUploadWorker.kt          # Wi-Fi upload worker
```

## API Integration

### Endpoint Configuration
Configure your API endpoint in the Settings screen. The endpoint should accept multipart form data.

### Upload Format
```
POST /your-endpoint
Content-Type: multipart/form-data

Fields:
- audio: File (audio/mp4, .m4a format)
- timestamp: Long (file creation timestamp)
```

### Expected Response
- **Success**: HTTP 200-299
- **Failure**: Any other status code triggers retry

## Audio Specifications

- **Format**: M4A (MPEG-4 Audio)
- **Encoder**: AAC
- **Bitrate**: 128 kbps
- **Sample Rate**: 44.1 kHz
- **Channels**: Mono

## Permissions

Required permissions (auto-configured):
- `RECORD_AUDIO` - For recording audio
- `FOREGROUND_SERVICE` - For background service
- `FOREGROUND_SERVICE_MICROPHONE` - For microphone access in foreground
- `WAKE_LOCK` - For keeping service alive
- `VIBRATE` - For haptic feedback
- `ACCESS_NETWORK_STATE` - For network detection
- `INTERNET` - For API uploads
- `POST_NOTIFICATIONS` - For foreground service notification (Android 13+)

## Device Compatibility

- **Minimum SDK**: Android 8.0 (API 26)
- **Target SDK**: Latest
- **Architecture**: ARM64, ARMv7, x86_64

## Known Limitations

### Volume Button Detection
- Uses MediaSession API (Google Play compliant)
- Cannot intercept Power button (requires root/system permissions)
- Volume button intercept may not work on some heavily customized ROMs
- Some manufacturers disable volume button intercept in accessibility settings

### Background Restrictions
- Service may be killed on some devices with aggressive battery optimization
- Users should exclude app from battery optimization
- Doze mode may affect service reliability
- Different behavior across manufacturers (Samsung, Xiaomi, Huawei, etc.)

### Upload Behavior
- Only uploads on Wi-Fi (not mobile data)
- WorkManager handles retries automatically
- Failed uploads remain in local storage
- Large recordings may take time to upload

## Battery Optimization

To ensure the app works reliably:

1. **Disable Battery Optimization**:
   - Settings → Apps → Voice Notes → Battery → Unrestricted

2. **Manufacturer-Specific**:
   - **Samsung**: Settings → Device care → Battery → App power management → Add to "Never sleeping apps"
   - **Xiaomi**: Settings → Battery & performance → Manage apps' battery usage → Choose apps → Voice Notes → No restrictions
   - **Huawei**: Settings → Battery → App launch → Voice Notes → Manage manually → Enable all

## Troubleshooting

### Volume Buttons Not Working
1. Check if service is running (green indicator on home screen)
2. Grant all required permissions
3. Disable battery optimization
4. Try restarting the service
5. Check manufacturer-specific volume button settings

### Recordings Not Uploading
1. Verify Wi-Fi connection
2. Check API endpoint configuration
3. Ensure API is accessible
4. Check app logs for errors
5. Try manual upload from home screen

### Service Stops Unexpectedly
1. Exclude from battery optimization
2. Lock app in recent apps (manufacturer-specific)
3. Check notification is visible
4. Verify all permissions granted

## Development

### Platform Channel Methods

**Flutter → Native**:
- `startService()` - Start foreground service
- `stopService()` - Stop foreground service
- `checkPermissions()` - Check permission status
- `requestPermissions()` - Request required permissions
- `getAllRecordings()` - Get list of recordings
- `deleteRecording(filePath)` - Delete a recording
- `saveApiEndpoint(endpoint)` - Save API URL
- `getApiEndpoint()` - Get saved API URL
- `triggerUpload()` - Manually trigger upload

**Native → Flutter**:
- `onRecordingStarted()` - Recording started event
- `onRecordingStopped(filePath)` - Recording stopped event
- `onUploadCompleted(successCount, failedCount)` - Upload completed
- `onPermissionsResult(granted)` - Permission result

### Testing

```bash
# Run in debug mode
flutter run

# Build release APK
flutter build apk --release

# Build release App Bundle (for Play Store)
flutter build appbundle --release
```

### Debugging Tips

1. **Check Android Logs**:
```bash
adb logcat | grep -i "notes_0"
```

2. **View Service Status**:
```bash
adb shell dumpsys activity services | grep -i "VolumeButtonRecordingService"
```

3. **Check WorkManager Jobs**:
```bash
adb shell dumpsys jobscheduler
```

## Google Play Compliance

This app complies with Google Play policies:
- Uses approved MediaSession API for volume button detection
- Foreground service with persistent notification
- Clearly states microphone usage
- Requests permissions with clear explanations
- No root or system-level modifications required

## Future Enhancements

Potential improvements:
- [ ] Audio playback in-app
- [ ] Speech-to-text transcription
- [ ] Cloud sync with multiple services
- [ ] Recording tags/categories
- [ ] Export to various formats
- [ ] Audio compression options
- [ ] Dark mode support
- [ ] Multiple language support
- [ ] Wear OS companion app

## License

This project is provided as-is for educational and personal use.

## Support

For issues or questions:
1. Check troubleshooting section
2. Review Android logs
3. Verify permissions and settings
4. Test on different devices

## Credits

Built with:
- Flutter
- Kotlin
- AndroidX WorkManager
- OkHttp
- MediaSession API

---

**Note**: This app is designed for personal voice note capture and requires user configuration of their own API endpoint for uploads.
