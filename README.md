# FileServeApp - Mobile File Server

簡易版安卓文件服務器應用，讓區網電腦可以透過 Web 介面整理手機裡的檔案。

支持 **Android 14（API 34）及以上**。

## 功能特性

### 應用端
- ✅ 開始/停止服務按鈕
- ✅ 實時服務狀態顯示
- ✅ 日誌記錄（時間、IP、操作類型、文件路徑）
- ✅ 按日期分檔日誌（yyyyMMdd.log 格式）
- ✅ 日誌倒序顯示

### 文件服務器 API
- ✅ `GET /api/list?path=<path>` - 列出目錄文件
- ✅ `GET /api/get?path=<path>` - 下載文件
- ✅ `POST /api/upload` - 上傳文件
- ✅ `DELETE /api/delete?path=<path>` - 刪除文件/目錄
- ✅ `POST /api/rename` - 重命名文件
- ✅ `GET /api/logs?date=<date>` - 查詢日誌

### Web 前端
- ✅ 文件管理器 UI（Vue 3.js）
- ✅ 拖拉上傳功能
- ✅ Ctrl+C/Ctrl+V 複製粘貼
- ✅ 右鍵菜單（下載、重命名、刪除）
- ✅ 面包屑導航
- ✅ 文件類型圖標

## 系統要求

### 運行環境
- Android 14（API 34）及以上

### 開發環境
- Java 17+（推薦 OpenJDK）
- Gradle 8.5+
- Android SDK 34+
- Android Build Tools 35.0.0+

完整的環境設置說明見 [SETUP.md](SETUP.md)

## 快速開始

### 1. 驗證環境
```bash
bash verify.sh
```

### 2. 構建 APK
```bash
bash build.sh release
```

### 3. 安裝到設備
```bash
adb install -r android/app/build/outputs/apk/release/app-release.apk
```

### 4. 啟動應用
1. 在手機上打開 FileServeApp
2. 點擊「開始服務」按鈕
3. 訪問 `http://<手機IP>:8080`

詳見 [QUICKSTART.md](QUICKSTART.md)

## 項目結構

```
FileServeApp/
├── android/                        # Android 應用源碼
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── java/com/fileserveapp/
│   │   │   │   ├── MainActivity.java
│   │   │   │   ├── FileServerService.java
│   │   │   │   ├── FileServerThread.java
│   │   │   │   └── LogWriter.java
│   │   │   ├── assets/www/
│   │   │   │   └── index.html
│   │   │   ├── res/
│   │   │   │   └── ...
│   │   │   └── AndroidManifest.xml
│   │   └── build.gradle
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle.properties
│   ├── gradlew
│   └── gradlew.bat
├── SETUP.md                        # 環境設置完整指南
├── QUICKSTART.md                   # 快速開始指南
├── DELIVERY.md                     # 項目交付清單
├── README.md                       # 本文件
├── PROJECT_SUMMARY.txt             # 項目總結
├── verify.sh                       # 項目驗證腳本
├── build.sh                        # 構建腳本
└── .gitignore
```

## 環境設置

### 前置條件

在開始之前，確保已安裝：
- **Java 17+**（建議使用 sdkman）
- **Gradle 8.5+**
- **Android SDK** with Build Tools 35.0.0

### 快速設置

詳細的分步驟說明請參考 [SETUP.md](SETUP.md)，包括：

- Java 安裝（使用 sdkman 或系統包管理器）
- Gradle 安裝與配置
- Android SDK 安裝與配置
- 環境變量設置
- 常見問題解決

### 驗證環境

```bash
# 檢查所有必需組件
bash verify.sh

# 輸出應該顯示：
# ✅ 所有檢查通過！項目完整無誤
# ✅ 可以開始構建 APK 了！
```

## 構建 APK

### 使用構建腳本（推薦）

```bash
# 交互式菜單
bash build.sh

# 或直接構建
bash build.sh release        # 構建發佈版
bash build.sh full           # 完整流程（清理→構建→安裝）
```

### 直接使用 Gradle

```bash
cd android

# 構建調試版（開發用）
./gradlew assembleDebug

# 構建發佈版（上線用）
./gradlew assembleRelease
```

### 輸出位置

- 調試版：`android/app/build/outputs/apk/debug/app-debug.apk`
- 發佈版：`android/app/build/outputs/apk/release/app-release.apk`

## 安裝與運行

### 安裝 APK

```bash
adb install -r android/app/build/outputs/apk/release/app-release.apk
```

### 啟動應用

```bash
# 方式 1：ADB 啟動
adb shell am start -n com.fileserveapp/.MainActivity

# 方式 2：手機上點擊應用圖標
```

### 訪問 Web 界面

1. **獲取設備 IP**
   ```bash
   adb shell ip addr show
   ```

2. **使用 ADB 轉發（推薦）**
   ```bash
   adb forward tcp:8080 tcp:8080
   # 訪問 http://localhost:8080
   ```

3. **或直接訪問**
   ```
   http://<設備IP>:8080
   ```

## API 端點

| 方法 | 端點 | 說明 |
|------|------|------|
| GET | `/api/list?path=<path>` | 列出文件/目錄 |
| GET | `/api/get?path=<path>` | 下載文件 |
| POST | `/api/upload` | 上傳文件 |
| DELETE | `/api/delete?path=<path>` | 刪除文件或目錄 |
| POST | `/api/rename` | 重命名文件 |
| GET | `/api/logs?date=<yyyyMMdd>` | 查詢日誌 |

## 文件權限

應用已配置以下權限：
- `MANAGE_EXTERNAL_STORAGE` - 管理外部存儲
- `READ_EXTERNAL_STORAGE` - 讀取外部存儲
- `WRITE_EXTERNAL_STORAGE` - 寫入外部存儲
- `ACCESS_MEDIA_LOCATION` - 訪問媒體位置
- `INTERNET` - 網絡訪問

## 開發注意事項

### 日誌位置
- 應用日誌：`/data/data/com.fileserveapp/logs/file-server-yyyyMMdd.log`
- 文件存儲：`/data/data/com.fileserveapp/files/`
- Web 資源：`/data/data/com.fileserveapp/www/`

### 代碼結構

**Android 原生模塊（Java）**
- `MainActivity.java` - 主 UI 界面
- `FileServerService.java` - 後台服務
- `FileServerThread.java` - HTTP 服務器核心（基於 Java HttpServer）
- `LogWriter.java` - 日誌管理系統

**Web 前端（Vue 3.js）**
- `index.html` - 文件管理器應用

### 自定義應用

**修改應用名稱**
```bash
# 編輯 android/app/src/main/res/values/strings.xml
<string name="app_name">Your App Name</string>
```

**修改最小 SDK 版本**
```gradle
// 編輯 android/app/build.gradle
defaultConfig {
    minSdk 33  // 改為需要的版本
}
```

## 故障排除

### 找不到 Gradle
```bash
export GRADLE_HOME=/path/to/gradle
export PATH=$GRADLE_HOME/bin:$PATH
```

### 找不到 Android SDK
```bash
export ANDROID_HOME=$HOME/android-sdk-linux
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
```

### Java 版本錯誤
```bash
java -version  # 檢查版本
export JAVA_HOME=/path/to/java17
```

詳見 [SETUP.md](SETUP.md) 的問題解決部分

## 文檔

- [SETUP.md](SETUP.md) - 完整的環境設置指南
- [QUICKSTART.md](QUICKSTART.md) - 快速開始指南
- [DELIVERY.md](DELIVERY.md) - 項目交付清單

## 技術棧

- **Android**: Java 17+, Android SDK 34+
- **後端**: Java HttpServer（標準庫）
- **前端**: Vue 3.js + HTML/CSS
- **構建**: Gradle 8.5+

## 許可證

MIT License

## 貢獻

歡迎提交 Issues 和 Pull Requests！
