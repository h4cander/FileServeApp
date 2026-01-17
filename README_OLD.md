
# FileServeApp

一個功能完整的Android檔案伺服器應用，讓您可以透過區域網路的網頁瀏覽器輕鬆管理手機中的檔案。

## 🎯 專案簡介

這是一個基於React Native開發的Android應用程式，內建HTTP伺服器，提供網頁式檔案管理介面。您可以在電腦瀏覽器中透過簡單的操作介面來瀏覽、上傳、下載、刪除和重新命名手機中的檔案。

## ✨ 主要功能

### App端功能
- 🚀 一鍵啟動/停止檔案伺服器
- 📊 即時顯示伺服器狀態和連線資訊
- 📝 完整的操作日誌記錄
- 📅 按日期查看歷史日誌
- 🔄 自動記錄所有CRUD操作

### Web端功能
- 📁 檔案總管風格的介面設計
- ⬆️ 支援拖拉上傳檔案
- 📤 批次檔案上傳
- 📥 直接下載檔案
- 🗑️ 刪除檔案和資料夾
- ✏️ 重新命名檔案/資料夾
- ➕ 建立新資料夾
- 🔙 快速導航到上層目錄

## 🛠️ 技術棧

- **框架**: React Native 0.83
- **語言**: TypeScript, Kotlin
- **HTTP伺服器**: NanoHTTPD 2.3.1
- **原生整合**: Native Modules
- **前端**: HTML5, CSS3, JavaScript

## 📦 快速開始

### 前置需求
- Node.js >= 20
- Android Studio
- React Native開發環境
- JDK

### 開發環境設置（使用Docker）

```bash
docker run --name my-abb --rm -it -v /"$PWD:/app" -w //app beevelop/android:v2025.08.1 bash
```

在Docker容器中設置環境：

```bash
apt-get update
apt-get install -y curl ca-certificates

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

node -v
npm -v

yes | /opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android --licenses
/opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android "ndk;27.1.12297006"
```

### 編譯應用




```bash
npx @react-native-community/cli init MyApp --version 0.83.0
cd MyApp/android
./gradlew assembleRelease

```





