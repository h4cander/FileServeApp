# FileServeApp 開發與構建指南

本文件旨在幫助開發者快速設置環境並從源碼構建 APK。

## 1. 環境需求

本項目已在以下環境驗證通過：
- **作業系統**: Ubuntu 24.04+ / Debian (Linux)
- **Java**: OpenJDK 17 (強烈建議，避免相容性問題)
- **Android SDK**: API Level 34 (Android 14)
- **Gradle**: 8.5 (項目自帶 Wrapper)

## 2. 環境設置步驟 (Linux/Codespace)

### 2.1 安裝 Java 17
可以使用 `sdkman` 快速安裝：
```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 17.0.12-ms
sdk use java 17.0.12-ms
```

### 2.2 設置 Android SDK
如果您在 GitHub Codespaces 或乾淨的 Linux 環境，請確保已列出 SDK 路徑。
編輯 `android/local.properties`:
```properties
sdk.dir=/path/to/your/android-sdk
```

### 2.3 下載 Android 編譯工具
使用 `sdkmanager` 安裝必要組件：
```bash
sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"
```

## 3. 構建 APK

進入 `android` 目錄並執行 Gradle 指令：

### 構建發佈版 (Release)
```bash
cd android
./gradlew assembleRelease
```
輸出路徑：`android/app/build/outputs/apk/release/app-release.apk`

### 構建調試版 (Debug)
```bash
cd android
./gradlew assembleDebug
```
輸出路徑：`android/app/build/outputs/apk/debug/app-debug.apk`

## 4. 技術架構說明
- **HTTP Server**: 採用 [NanoHTTPD](https://github.com/NanoHttpd/nanohttpd)，因其在 Android 環境下的穩定性優於標準 JDK HttpServer。
- **權限**: 項目針對 Android 14+ 進行了優化。
- **Web 端**: 前端資源位於 `app/src/main/assets/www`。

## 5. 常見問題
- **編譯報錯 JdkImageTransform**: 請確保使用 Java 17 而非 Java 21+。
- **NanoHTTPD 缺失**: 執行編譯時 Gradle 會自動從 Maven Central 下載。
