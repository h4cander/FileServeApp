# File Server App

一個簡易的Android檔案伺服器應用，可讓區域網路中的電腦透過網頁瀏覽器管理手機中的檔案。

## 功能特色

### 📱 App端
- **啟動/停止服務**：一鍵啟動或停止檔案伺服器
- **即時狀態顯示**：清楚顯示伺服器運行狀態和網址
- **操作日誌**：記錄所有檔案操作（增刪改查）
- **日誌管理**：
  - 按日期自動分檔（yyyyMMdd.log）
  - 日誌倒序顯示（最新在上）
  - 可選擇不同日期查看歷史日誌

### 🌐 Web端（瀏覽器界面）
- **檔案總管風格**：類似Windows檔案總管的操作體驗
- **完整檔案操作**：
  - 瀏覽資料夾和檔案
  - 上傳檔案（支援拖拉上傳）
  - 下載檔案
  - 刪除檔案/資料夾
  - 重新命名
  - 建立新資料夾
- **便捷操作**：
  - 拖拉上傳
  - 雙擊開啟資料夾
  - 雙擊下載檔案
  - 上一層導航

### 🔐 權限設定
- 要求最大檔案存取權限
- 支援Android 11+的MANAGE_EXTERNAL_STORAGE權限

## 技術架構

- **前端框架**：React Native 0.83
- **HTTP伺服器**：NanoHTTPD
- **原生模組**：Kotlin
- **Web界面**：純HTML/CSS/JavaScript（內嵌於伺服器）

## 安裝與執行

### 環境需求
- Node.js >= 20
- React Native開發環境
- Android Studio
- JDK

### 安裝步驟

1. **安裝依賴**
```bash
cd MyApp
npm install
```

2. **Android設定**
確保已安裝Android SDK和模擬器或連接實體設備。

3. **執行應用**
```bash
npm run android
```

### 首次使用

1. 開啟App後，點擊「▶️ 開始服務」
2. 授予檔案存取權限（包括「所有檔案存取權限」）
3. 記下顯示的伺服器地址（如：`http://192.168.1.100:8080`）
4. 在同一區域網路的電腦瀏覽器中開啟該地址
5. 開始管理手機檔案！

## API端點

伺服器提供以下API：

- `GET /` - 主頁面（檔案管理界面）
- `GET /api/list?path=<path>` - 列出指定路徑的檔案
- `GET /api/get?path=<path>` - 下載檔案
- `POST /api/upload` - 上傳檔案
- `DELETE /api/delete?path=<path>` - 刪除檔案/資料夾
- `POST /api/rename` - 重新命名檔案/資料夾
- `POST /api/mkdir` - 建立新資料夾

## 日誌格式

日誌檔案格式：`yyyyMMdd.log`

日誌內容格式：
```
2026-01-17 14:30:25 | 192.168.1.10 | LIST | /Download
2026-01-17 14:30:28 | 192.168.1.10 | GET | /Download/example.pdf
2026-01-17 14:30:45 | 192.168.1.10 | UPLOAD | /Download/newfile.jpg
2026-01-17 14:31:02 | 192.168.1.10 | DELETE | /Download/oldfile.txt
2026-01-17 14:31:15 | 192.168.1.10 | RENAME | /Download/old.doc -> /Download/new.doc
```

## 安全提示

⚠️ **重要安全提醒**：
- 此應用僅供區域網路使用
- 不建議在公共網路環境下使用
- 伺服器沒有身份驗證機制
- 任何連接到同一網路的設備都可以存取您的檔案
- 使用完畢後請記得停止服務

## 疑難排解

### 無法連接伺服器
1. 確認手機和電腦在同一Wi-Fi網路
2. 檢查防火牆設定
3. 確認App顯示的IP位址正確
4. 嘗試關閉並重新啟動服務

### 無法存取某些資料夾
1. 確認已授予所有檔案存取權限
2. Android 11+需手動在設定中開啟「所有檔案存取權限」
3. 某些系統資料夾可能受保護無法存取

### 上傳失敗
1. 檢查手機儲存空間
2. 確認目標資料夾有寫入權限
3. 檔案名稱不可包含特殊字元

## 開發者資訊

### 專案結構
```
MyApp/
├── App.tsx                 # React Native主程式
├── android/
│   └── app/src/main/java/com/myapp/
│       ├── FileServerModule.kt    # 檔案伺服器原生模組
│       └── FileServerPackage.kt   # React Native套件註冊
└── package.json
```

### 自訂修改

**修改伺服器端口**：
在 `App.tsx` 中修改：
```typescript
const result = await FileServer.startServer(8080); // 改為其他端口
```

**修改存取根目錄**：
在 `FileServerModule.kt` 中修改：
```kotlin
private val baseDir: File = Environment.getExternalStorageDirectory()
```

## 授權

MIT License

## 聯絡資訊

如有問題或建議，請開啟Issue。
