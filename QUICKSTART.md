# 快速入門指南

## 環境檢查

在開始之前，請確認以下環境：

```bash
# 檢查Node.js版本
node -v
# 應該 >= 20

# 檢查npm
npm -v

# 檢查Java
java -version

# 進入專案目錄
cd MyApp
```

## 安裝依賴

```bash
npm install
```

## 編譯Release版本

```bash
cd android
./gradlew assembleRelease
```

APK輸出位置：`android/app/build/outputs/apk/release/app-release.apk`

## 編譯Debug版本（用於測試）

```bash
cd android
./gradlew assembleDebug
```

## 在設備上運行（開發模式）

1. 連接Android設備或啟動模擬器
2. 啟用USB調試
3. 執行：

```bash
npm run android
```

## 檢查錯誤

如果遇到問題：

```bash
# 清理建構快取
cd android
./gradlew clean

# 重新安裝依賴
cd ..
rm -rf node_modules
npm install

# 重新建構
cd android
./gradlew assembleRelease
```

## 權限設置

Android 11+設備需要手動授予「所有檔案存取權限」：

1. 設定 → 應用程式 → MyApp
2. 權限 → 檔案和媒體
3. 選擇「允許管理所有檔案」

## 測試步驟

1. 安裝APK到手機
2. 開啟App並點擊「開始服務」
3. 授予所有權限
4. 在電腦瀏覽器輸入顯示的URL
5. 測試各項功能：
   - 瀏覽資料夾
   - 上傳檔案
   - 下載檔案
   - 重新命名
   - 刪除檔案
   - 建立資料夾

## 常見問題排除

### Gradle錯誤
```bash
# 使用特定版本的Gradle
cd android
./gradlew wrapper --gradle-version 8.3

# 重新同步
./gradlew --refresh-dependencies
```

### NDK錯誤
確保已安裝NDK：
```bash
/opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android "ndk;27.1.12297006"
```

### 網路連接問題
- 確認手機和電腦在同一Wi-Fi網路
- 關閉VPN或代理
- 檢查防火牆設定

## 部署到生產環境

1. 生成簽名金鑰（首次）：
```bash
keytool -genkeypair -v -storetype PKCS12 -keystore my-release-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
```

2. 配置gradle：
編輯 `android/app/build.gradle` 添加簽名配置

3. 建構簽名版本：
```bash
./gradlew assembleRelease
```

4. 對齊APK：
```bash
zipalign -v -p 4 app-release-unsigned.apk app-release-aligned.apk
```

5. 簽名APK：
```bash
apksigner sign --ks my-release-key.keystore --out app-release.apk app-release-aligned.apk
```
