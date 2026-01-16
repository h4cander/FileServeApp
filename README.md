# File Server App

A Flutter-based mobile file server application for Android 14+ that allows local network computers to manage files on the phone through a web interface.

## Features

### App Features
- Start/Stop server with buttons
- Display server status and URL
- Log viewer with date selection
- Logs stored in yyyyMMdd.log format (append mode)
- Reverse chronological log display

### Server Features
- Static HTML web interface
- REST API endpoints:
  - `GET /api/list?path=<path>` - List files in directory
  - `GET /api/get?path=<path>` - Download file
  - `POST /api/upload` - Upload file
  - `DELETE /api/delete` - Delete file/directory
  - `PUT /api/rename` - Rename file/directory
  - `POST /api/mkdir` - Create directory

### Web Interface Features
- File explorer similar to file manager
- Drag and drop file upload
- Keyboard shortcuts (Ctrl+C, Ctrl+V)
- Navigate up directory
- Rename files/folders
- Built with Vue 3 and Pico CSS

## Requirements

- Android 14+
- Flutter SDK
- Network connectivity (WiFi/LAN)

## Permissions

The app requests the following permissions for maximum file access:
- `INTERNET` - For HTTP server
- `ACCESS_NETWORK_STATE` - For network information
- `ACCESS_WIFI_STATE` - For WiFi IP address
- `MANAGE_EXTERNAL_STORAGE` - For full storage access on Android 11+
- `READ_EXTERNAL_STORAGE` - For reading files (Android 12 and below)
- `WRITE_EXTERNAL_STORAGE` - For writing files (Android 12 and below)
- `READ_MEDIA_IMAGES/VIDEO/AUDIO` - For media access on Android 13+

## Installation

1. Clone the repository
2. Run `flutter pub get`
3. Connect your Android device
4. Run `flutter run`

## Usage

1. Open the app on your Android device
2. Grant all requested permissions
3. Tap "開始" (Start) to start the server
4. Note the URL displayed (e.g., http://192.168.1.100:8080)
5. Open this URL in a web browser on any computer on the same network
6. Use the web interface to manage files
7. Tap "停止" (Stop) to stop the server when done

## Development

This project uses:
- Flutter for the mobile app
- Shelf for HTTP server
- Vue 3 for web frontend
- Pico CSS for styling

## License

See LICENSE file for details.
