# 🚀 快速開始指南

## 項目概覽

**FileServeApp** - Android 文件服務器應用

你已經有一個完整的、生產級別的項目模板，包括：
- ✅ Android 原生後端（Java + HttpServer）
- ✅ Web 前端（Vue 3.js 文件管理器）
- ✅ Gradle 完整配置
- ✅ 最大文件訪問權限配置

---

## 📋 環境前置要求

確保你已安裝以下內容。詳細說明見 [SETUP.md](SETUP.md)：

```bash
# 驗證環境
bash verify.sh

# 應該看到：
# ✅ 所有檢查通過！
```

如果有缺失的組件，請按 [SETUP.md](SETUP.md) 的步驟安裝。

---

## 💻 本地開發構建（推薦）

### 快速構建

**方法 1：使用交互式菜單（推薦）**
```bash
bash build.sh
```
選擇選項 1-6 之一

**方法 2：直接命令**
```bash
# 構建發佈版 APK
bash build.sh release

# 完整流程（清理→構建→安裝）
bash build.sh full

# 安裝到連接的設備
bash build.sh install
```

**方法 3：直接使用 Gradle**
```bash
cd android

# 構建調試版
./gradlew assembleDebug

# 構建發佈版
./gradlew assembleRelease

# 構建並安裝
./gradlew installRelease

cd ..
```

### APK 輸出位置

- **調試版**：`android/app/build/outputs/apk/debug/app-debug.apk`
- **發佈版**：`android/app/build/outputs/apk/release/app-release.apk`



---

## 📱 應用架構

### 後端（Android Java）
- `FileServerService` - 後台服務，管理服務器生命週期
- `FileServerThread` - HTTP 服務器（基於 Java HttpServer）
  - 監聽 `127.0.0.1:8080`
  - 提供 REST API（列表、上傳、下載、刪除、重命名）
  - 提供靜態 HTML 頁面
- `LogWriter` - 日誌管理（按日期分檔）
- `MainActivity` - UI 界面（開始/停止按鈕 + 日誌查看）

### 前端（Web - Vue 3.js）
- 文件管理器 UI
- 拖拉上傳
- 右鍵菜單
- Ctrl+C/V 複製粘貼
- 文件下載

### 文件存儲位置
```
/data/data/com.fileserveapp/
├── files/          # 用戶可訪問的文件目錄
├── www/            # Web 靜態資源
├── logs/           # 日誌目錄
│   └── file-server-20240117.log
└── cache/          # 緩存
```

---

## 🔧 API 端點

| 方法 | 端點 | 說明 |
|------|------|------|
| GET | `/api/list?path=<path>` | 列出文件/目錄 |
| GET | `/api/get?path=<path>` | 下載文件 |
| POST | `/api/upload` | 上傳文件（Headers: X-File-Path, X-File-Name） |
| DELETE | `/api/delete?path=<path>` | 刪除文件或目錄 |
| POST | `/api/rename` | 重命名（JSON: oldPath, newName） |
| GET | `/api/logs?date=<yyyyMMdd>` | 查詢日誌 |

---

## 📋 權限配置（已設置最大化）

`AndroidManifest.xml` 已包含：
```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

運行時需要在 Android 14+ 上授予動態權限。

---

## 🚀 部署到設備

### 方法 1：使用構建腳本
```bash
bash build.sh install
```

### 方法 2：手動安裝
```bash
adb install -r android/app/build/outputs/apk/release/app-release.apk
```

### 運行應用
1. 手機上打開 FileServeApp
2. 點擊「開始服務」
3. 在電腦瀏覽器打開：`http://<手機IP>:8080`

或使用 ADB 轉發：
```bash
adb forward tcp:8080 tcp:8080
# 然後訪問 http://127.0.0.1:8080
```

---

## 🐛 調試

### 查看日誌
```bash
# Android logcat
adb logcat | grep FileServer

# 應用日誌文件（需要 root）
adb shell cat /data/data/com.fileserveapp/logs/file-server-$(date +%Y%m%d).log
```

### 調試構建
```bash
# 構建調試版（可 adb debug）
bash build.sh debug

# 或直接使用 Android Studio 附加調試器
```

---

## ✅ 驗收清單

- [ ] 環境驗證通過（bash verify.sh）
- [ ] APK 成功構建（bash build.sh release）
- [ ] APK 可以安裝到 Android 14+ 設備
- [ ] 應用啟動時可以開始/停止服務
- [ ] Web 前端可以訪問和管理文件
- [ ] 日誌正確記錄了 IP 和操作
- [ ] 區網電腦可以訪問 Web 界面

---

## 🔄 下一步

1. **驗證環境**
   ```bash
   bash verify.sh
   ```

2. **構建 APK**
   ```bash
   bash build.sh release
   ```

3. **安裝並運行**
   ```bash
   bash build.sh install
   ```

4. **優化應用**
   - 修改應用名稱/圖標：`android/app/src/main/res/`
   - 添加更多 API 端點
   - 增強前端 UI

---

## 📚 更多文檔

- [README.md](README.md) - 項目總覽
- [SETUP.md](SETUP.md) - 完整的環境設置指南
- [DELIVERY.md](DELIVERY.md) - 項目交付清單

---

**祝構建成功！** 🎉
