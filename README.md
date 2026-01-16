# File Server App

A Flutter-based mobile file server application for Android 14+ that allows local network computers to manage files on the phone through a web interface.

## 📖 Documentation

- **[Setup Guide](SETUP.md)** - Installation and configuration instructions
- **[API Documentation](API.md)** - Complete API reference for developers
- **[Testing Guide](TESTING.md)** - Comprehensive testing checklist
- **[Icon Setup](ICON_SETUP.md)** - How to add custom app icons

## ✨ Features

### App Features
- 🚀 Start/Stop server with buttons
- 📊 Display server status and URL
- 📝 Log viewer with date selection
- 💾 Logs stored in yyyyMMdd.log format (append mode)
- ⏮️ Reverse chronological log display

### Server Features
- 🌐 Static HTML web interface
- 🔌 REST API endpoints:
  - `GET /api/list?path=<path>` - List files in directory
  - `GET /api/get?path=<path>` - Download file
  - `POST /api/upload` - Upload file
  - `DELETE /api/delete` - Delete file/directory
  - `PUT /api/rename` - Rename file/directory
  - `POST /api/mkdir` - Create directory

### Web Interface Features
- 📁 File explorer similar to file manager
- 🖱️ Drag and drop file upload
- ⌨️ Keyboard shortcuts (Ctrl+C, Ctrl+V)
- ⬆️ Navigate up directory
- ✏️ Rename files/folders
- 🎨 Built with Vue 3 and Pico CSS

## 📋 Requirements

- Android 14+
- Flutter SDK
- Network connectivity (WiFi/LAN)

## 🔐 Permissions

The app requests the following permissions for maximum file access:
- `INTERNET` - For HTTP server
- `ACCESS_NETWORK_STATE` - For network information
- `ACCESS_WIFI_STATE` - For WiFi IP address
- `MANAGE_EXTERNAL_STORAGE` - For full storage access on Android 11+
- `READ_EXTERNAL_STORAGE` - For reading files (Android 12 and below)
- `WRITE_EXTERNAL_STORAGE` - For writing files (Android 12 and below)
- `READ_MEDIA_IMAGES/VIDEO/AUDIO` - For media access on Android 13+

## 🚀 Quick Start

1. Clone the repository
   ```bash
   git clone https://github.com/h4cander/FileServeApp.git
   cd FileServeApp
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Connect your Android device and run
   ```bash
   flutter run
   ```

4. Grant all permissions when prompted

5. Tap "開始" (Start) to start the server

6. Open the displayed URL in a web browser on any device on the same network

For detailed setup instructions, see [SETUP.md](SETUP.md)

## 💡 Usage

1. Open the app on your Android device
2. Grant all requested permissions (especially "All files access" for Android 14+)
3. Tap "開始" (Start) to start the server
4. Note the URL displayed (e.g., http://192.168.1.100:8080)
5. Open this URL in a web browser on any computer on the same network
6. Use the web interface to manage files:
   - Browse folders by clicking on them
   - Upload files by drag-and-drop or clicking "上傳檔案"
   - Download files by clicking "下載" or double-clicking
   - Delete files by selecting them and clicking "刪除"
   - Rename files by selecting one and clicking "重新命名"
   - Create folders by clicking "新增資料夾"
7. Tap "停止" (Stop) to stop the server when done

## 🛠️ Development

This project uses:
- **Flutter** for the mobile app
- **Shelf** for HTTP server
- **Vue 3** for web frontend
- **Pico CSS** for styling

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   └── home_screen.dart      # Main app screen with controls
└── services/
    ├── file_server.dart      # HTTP server and API endpoints
    └── logger_service.dart   # Logging functionality

android/
└── app/
    └── src/main/
        ├── AndroidManifest.xml           # Permissions configuration
        └── kotlin/.../MainActivity.kt    # Android main activity
```

### Building

```bash
# Debug build
flutter run

# Release APK
flutter build apk --release

# The APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🔒 Security Considerations

⚠️ **Warning**: This app is designed for use on trusted local networks only.

- No authentication is implemented
- All files on the device are accessible to anyone on the network
- Do not expose this server to the internet
- Only use on networks you trust
- Consider adding authentication if needed

## 🐛 Known Issues

- File upload size is limited by available device memory
- Large files may take time to upload/download depending on network speed
- Some Android devices may have stricter permission requirements

## 📝 License

See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Uses [Shelf](https://pub.dev/packages/shelf) for HTTP server
- UI powered by [Vue 3](https://vuejs.org/)
- Styled with [Pico CSS](https://picocss.com/)

## 📧 Contact

For issues and feature requests, please use the [GitHub Issues](https://github.com/h4cander/FileServeApp/issues) page.
