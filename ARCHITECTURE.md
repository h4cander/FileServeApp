# 技術架構文件

## 系統架構圖

```
┌─────────────────────────────────────────────────────────┐
│                      Android App                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │          React Native Layer (App.tsx)             │  │
│  │  - UI Components                                  │  │
│  │  - State Management                               │  │
│  │  - Event Handling                                 │  │
│  └────────────────┬──────────────────────────────────┘  │
│                   │                                      │
│                   │ NativeModules Bridge                 │
│                   │                                      │
│  ┌────────────────▼──────────────────────────────────┐  │
│  │    Native Module (FileServerModule.kt)           │  │
│  │  - Server Control                                │  │
│  │  - Log Management                                │  │
│  │  - Permission Handling                           │  │
│  └────────────────┬──────────────────────────────────┘  │
│                   │                                      │
│  ┌────────────────▼──────────────────────────────────┐  │
│  │      HTTP Server (NanoHTTPD)                     │  │
│  │  - Request Routing                               │  │
│  │  - File Operations                               │  │
│  │  - Static HTML Serving                           │  │
│  └───────────────────────────────────────────────────┘  │
│                   │                                      │
└───────────────────┼──────────────────────────────────────┘
                    │
                    │ HTTP Protocol (Port 8080)
                    │ Local Network (Wi-Fi)
                    │
┌───────────────────▼──────────────────────────────────────┐
│              Web Browser (Client)                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │          HTML/CSS/JavaScript                      │  │
│  │  - File Manager UI                                │  │
│  │  - File Operations                                │  │
│  │  - Drag & Drop                                    │  │
│  │  - Keyboard Shortcuts                             │  │
│  └───────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

## 技術棧詳細說明

### 前端層（React Native）

**框架**: React Native 0.83
**語言**: TypeScript
**主要依賴**:
- `react`: 19.2.0
- `react-native`: 0.83.0
- `react-native-safe-area-context`: 5.5.2

**功能模塊**:
```typescript
// App.tsx 主要組件
├── SafeAreaProvider          // 安全區域包裝
├── AppContent                 // 主要內容組件
│   ├── Control Panel         // 控制面板（啟動/停止）
│   ├── Status Display        // 狀態顯示
│   ├── Date Selector         // 日期選擇器
│   └── Log Display           // 日誌顯示區
└── Event Handlers            // 事件處理
    ├── startServer()
    ├── stopServer()
    ├── loadLogs()
    └── checkPermissions()
```

### 原生層（Kotlin）

**主要類**:

1. **FileServerModule.kt**
   - 提供與React Native的橋接
   - 管理伺服器生命週期
   - 處理日誌讀寫
   - 獲取網路資訊

2. **FileServerPackage.kt**
   - 註冊Native Module到React Native

**核心功能**:
```kotlin
class FileServerModule : ReactContextBaseJavaModule {
    // 導出給JS的方法
    @ReactMethod fun startServer(port: Int, promise: Promise)
    @ReactMethod fun stopServer(promise: Promise)
    @ReactMethod fun isServerRunning(promise: Promise)
    @ReactMethod fun getLogs(date: String, promise: Promise)
    @ReactMethod fun getLogDates(promise: Promise)
    
    // 內部功能
    private fun getIPAddress(): String
    private fun logOperation(clientIp: String, operation: String, path: String)
}
```

### HTTP伺服器層（NanoHTTPD）

**框架**: NanoHTTPD 2.3.1
**功能**: 輕量級HTTP伺服器

**API路由設計**:
```kotlin
inner class FileServer : NanoHTTPD {
    override fun serve(session: IHTTPSession): Response {
        when (uri) {
            "/"                    -> serveIndexHtml()
            "/api/list"           -> handleList()
            "/api/get"            -> handleGet()
            "/api/upload"         -> handleUpload()
            "/api/delete"         -> handleDelete()
            "/api/rename"         -> handleRename()
            "/api/mkdir"          -> handleMkdir()
        }
    }
}
```

**請求處理流程**:
```
1. 接收HTTP請求
2. 解析URI和參數
3. 驗證檔案路徑
4. 執行檔案操作
5. 記錄日誌
6. 返回JSON/檔案響應
```

### Web前端層（Vanilla JS）

**技術**: 純HTML5 + CSS3 + JavaScript（無框架）

**組件結構**:
```javascript
// 全域變數
let currentPath = '/'
let selectedItems = new Set()
let clipboard = null

// 主要功能函數
async function loadFiles(path)      // 載入檔案列表
async function uploadFiles(files)   // 上傳檔案
async function deleteFile(path)     // 刪除檔案
async function confirmRename()      // 重新命名
async function confirmNewFolder()   // 建立資料夾

// 事件處理
document.addEventListener('keydown', handleKeyboard)
dropZone.addEventListener('drop', handleDrop)
```

**UI設計原則**:
- 響應式設計
- 直覺式操作
- 視覺回饋
- 錯誤提示

## 資料流

### 啟動伺服器流程
```
1. 使用者點擊「開始服務」
   ↓
2. App.tsx 調用 FileServer.startServer(8080)
   ↓
3. Native Module 創建 FileServer 實例
   ↓
4. NanoHTTPD.start() 啟動HTTP服務
   ↓
5. 獲取IP地址
   ↓
6. Promise 返回 {ip, port, url}
   ↓
7. 更新UI狀態和顯示URL
```

### 檔案上傳流程
```
1. 使用者在瀏覽器選擇/拖曳檔案
   ↓
2. JavaScript FormData 構建請求
   ↓
3. POST /api/upload (multipart/form-data)
   ↓
4. NanoHTTPD 接收請求
   ↓
5. parseBody() 解析檔案
   ↓
6. 儲存到目標路徑
   ↓
7. logOperation() 記錄日誌
   ↓
8. 觸發 'newLogEntry' 事件
   ↓
9. App.tsx 接收事件更新日誌UI
   ↓
10. 返回 JSON {success: true}
   ↓
11. 瀏覽器重新載入檔案列表
```

### 日誌記錄流程
```
1. 檔案操作發生
   ↓
2. logOperation(ip, operation, path)
   ↓
3. 格式化時間戳和日誌內容
   ↓
4. 寫入檔案: /sdcard/Android/data/com.myapp/files/{date}.log
   ↓
5. 發送事件到React Native
   ↓
6. App.tsx 更新日誌列表
```

## 檔案系統架構

### Android檔案結構
```
/sdcard/
├── Android/
│   └── data/
│       └── com.myapp/
│           └── files/
│               ├── 20260117.log      # 日誌檔案
│               ├── 20260118.log
│               └── ...
├── Download/                          # 可存取
├── Documents/                         # 可存取
├── Pictures/                          # 可存取
├── DCIM/                             # 可存取
└── ...                               # 根據權限
```

### 日誌格式
```
時間戳 | 客戶端IP | 操作類型 | 檔案路徑
yyyy-MM-dd HH:mm:ss | xxx.xxx.xxx.xxx | OPERATION | /path/to/file

範例:
2026-01-17 14:30:25 | 192.168.1.10 | UPLOAD | /Download/photo.jpg
```

## API規格詳細說明

### 1. 列出檔案
```
GET /api/list?path={path}

Request:
  Query Params:
    - path: 目標路徑 (預設: /)

Response: 200 OK
{
  "path": "/Download",
  "files": [
    {
      "name": "document.pdf",
      "path": "/Download/document.pdf",
      "isDirectory": false,
      "size": 1024000,
      "modified": 1705483200000
    },
    ...
  ]
}

Error: 404 Not Found
{
  "error": "Directory not found"
}
```

### 2. 下載檔案
```
GET /api/get?path={path}

Request:
  Query Params:
    - path: 檔案路徑

Response: 200 OK
  Content-Type: {detected mime type}
  Body: {file stream}

Error: 404 Not Found
  "File not found"
```

### 3. 上傳檔案
```
POST /api/upload

Request:
  Content-Type: multipart/form-data
  Body:
    - file: {file data}
    - path: {target directory}

Response: 200 OK
{
  "success": true
}

Error: 404 Not Found
{
  "error": "Directory not found"
}
```

### 4. 刪除檔案/資料夾
```
DELETE /api/delete?path={path}

Request:
  Query Params:
    - path: 要刪除的路徑

Response: 200 OK
{
  "success": true
}

Error: 404 Not Found
{
  "error": "File not found"
}
```

### 5. 重新命名
```
POST /api/rename

Request:
  Content-Type: application/json
  Body:
  {
    "oldPath": "/Download/old.txt",
    "newName": "new.txt"
  }

Response: 200 OK
{
  "success": true
}

Error: 404 Not Found
{
  "error": "File not found"
}
```

### 6. 建立資料夾
```
POST /api/mkdir

Request:
  Content-Type: application/json
  Body:
  {
    "path": "/Download",
    "name": "NewFolder"
  }

Response: 200 OK
{
  "success": true
}

Error: 404 Not Found
{
  "error": "Parent directory not found"
}
```

## 安全性考量

### 當前安全措施
1. **僅限區域網路**: 伺服器只監聽本地網路介面
2. **權限隔離**: 僅存取授予權限的儲存區域
3. **路徑驗證**: 防止路徑遍歷攻擊（基本）
4. **日誌記錄**: 記錄所有操作用於審計

### 已知安全限制
1. **無身份驗證**: 同網路任何人都可存取
2. **無加密傳輸**: HTTP明文傳輸
3. **無存取控制**: 所有檔案權限相同
4. **無速率限制**: 可能被濫用

### 未來安全增強
- [ ] 實作Basic Authentication
- [ ] 支援HTTPS/TLS
- [ ] Token-based認證
- [ ] IP白名單
- [ ] 操作權限分級
- [ ] 速率限制
- [ ] 防暴力破解

## 性能優化

### 已實作優化
1. **檔案串流**: 使用串流方式傳輸大檔案
2. **非阻塞IO**: NanoHTTPD的異步處理
3. **日誌批次寫入**: 使用appendText減少IO
4. **路徑緩存**: 減少重複的檔案系統查詢

### 建議優化
1. **壓縮傳輸**: Gzip壓縮HTTP響應
2. **檔案緩存**: 添加ETag和Cache-Control
3. **分頁載入**: 大資料夾分頁顯示
4. **連接池**: 限制並發連接數
5. **記憶體管理**: 優化大檔案處理

## 錯誤處理

### 錯誤類型
1. **網路錯誤**: 連接失敗、超時
2. **權限錯誤**: 無讀寫權限
3. **檔案錯誤**: 檔案不存在、空間不足
4. **解析錯誤**: JSON解析失敗、參數缺失

### 處理機制
```kotlin
try {
    // 操作
} catch (e: Exception) {
    Log.e("FileServer", "Error", e)
    return errorResponse(e.message)
}
```

### 前端錯誤處理
```javascript
try {
    const response = await fetch(url);
    const data = await response.json();
    if (data.error) {
        alert('錯誤: ' + data.error);
    }
} catch (error) {
    alert('操作失敗: ' + error.message);
}
```

## 測試策略

### 單元測試
- Native Module方法測試
- 檔案操作邏輯測試
- 日誌格式化測試

### 整合測試
- API端點測試
- 檔案上傳下載測試
- 權限檢查測試

### E2E測試
- 完整使用流程測試
- 多設備並發測試
- 長時間穩定性測試

## 部署考量

### 建構設定
- Release模式開啟ProGuard混淆
- 移除除錯符號減小APK大小
- 設定最小和目標SDK版本

### 發布檢查清單
- [ ] 簽名APK
- [ ] 測試多個Android版本
- [ ] 檢查權限聲明
- [ ] 驗證網路功能
- [ ] 性能測試
- [ ] 安全掃描

## 維護與監控

### 日誌監控
- 定期檢查日誌檔案大小
- 分析常見錯誤
- 監控異常流量

### 更新策略
- 定期更新依賴套件
- 修復已知安全漏洞
- 收集使用者反饋
- 迭代改進功能

## 參考資源

- [React Native官方文檔](https://reactnative.dev/)
- [NanoHTTPD GitHub](https://github.com/NanoHttpd/nanohttpd)
- [Android開發者指南](https://developer.android.com/)
- [Kotlin官方文檔](https://kotlinlang.org/)
