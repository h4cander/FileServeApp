# App Icon Setup

The app currently uses a placeholder icon. To add proper app icons:

1. Generate icons using a tool like:
   - [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)
   - [App Icon Generator](https://appicon.co/)

2. Place the generated icons in the appropriate mipmap folders:
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

3. For adaptive icons (Android 8.0+), also create:
   - `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`

## Using flutter_launcher_icons

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  image_path: "assets/icon/app_icon.png"
```

Then run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```
