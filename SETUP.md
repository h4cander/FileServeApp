# Setup Guide

## Prerequisites

1. **Flutter SDK**: Install Flutter from https://flutter.dev/docs/get-started/install
2. **Android Studio** or **VS Code** with Flutter extensions
3. **Android Device** running Android 14 or higher (or emulator)
4. **USB Debugging** enabled on your Android device

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/h4cander/FileServeApp.git
cd FileServeApp
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Flutter

If this is your first Flutter project, run:

```bash
flutter doctor
```

Fix any issues reported by Flutter Doctor.

### 4. Connect Your Device

Connect your Android device via USB or start an Android emulator:

```bash
flutter devices
```

### 5. Run the App

```bash
flutter run
```

Or for release build:

```bash
flutter build apk --release
flutter install
```

## First Run Setup

1. When you first launch the app, it will request storage permissions
2. **IMPORTANT**: For Android 14+, you must grant "All files access" permission:
   - Go to Settings → Apps → File Server → Permissions
   - Enable "Files and media" or "All files access"
   - This is required for the app to access and serve files from your device

## Configuration

### Port Configuration

The server runs on port 8080 by default. To change this:

1. Edit `lib/services/file_server.dart`
2. Change the `_port` constant:

```dart
static const int _port = 8080; // Change to your desired port
```

### Storage Location

By default, the app serves files from the external storage root. To change the storage location:

1. Edit `lib/services/file_server.dart`
2. Modify the `_getStorageDirectory()` method

## Network Configuration

### Using on Local Network

1. Ensure your Android device and computer are on the same WiFi network
2. The app will display the server URL (e.g., http://192.168.1.100:8080)
3. Open this URL in a web browser on any device on the same network

### Firewall Considerations

If you can't connect from other devices:

1. Check if your WiFi network allows device-to-device communication
2. Some public WiFi networks block device-to-device connections
3. Try using a personal hotspot or home network

## Troubleshooting

### "Permission Denied" Errors

**Solution**: 
- Ensure "All files access" permission is granted
- On Android 14+, go to Settings → Apps → File Server → Permissions → Files and media → Allow all files access

### "Cannot Connect to Server" from Browser

**Solutions**:
1. Verify both devices are on the same network
2. Check the IP address displayed in the app matches what you're typing in the browser
3. Try disabling any VPN or firewall on the computer
4. Make sure the server is running (green "運行中" status in the app)

### Files Not Appearing

**Solutions**:
1. Check storage permissions are granted
2. Navigate to the correct directory using the web interface
3. Refresh the file list using the refresh button

### App Crashes on Startup

**Solutions**:
1. Clear app data: Settings → Apps → File Server → Storage → Clear data
2. Uninstall and reinstall the app
3. Check `flutter doctor` for any SDK issues

## Development

### Running in Debug Mode

```bash
flutter run
```

### Viewing Logs

```bash
flutter logs
```

### Hot Reload

While the app is running in debug mode, press `r` in the terminal to hot reload changes.

### Building for Release

```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Updating

To update to the latest version:

```bash
git pull origin main
flutter pub get
flutter run
```

## Uninstalling

To remove the app:

1. Via command line:
   ```bash
   flutter uninstall
   ```

2. Or manually:
   - Go to Settings → Apps → File Server → Uninstall
