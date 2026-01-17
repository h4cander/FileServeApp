# 📋 環境設置與構建指南

## 前置要求

本項目在以下環境中已驗證可運行：

```
✅ Java: OpenJDK 25.0.1 LTS
✅ Gradle: 9.2.1
✅ Android API: 34-35
✅ Linux: Ubuntu 24.04+
```

## 第 1 步：安裝基礎工具

### 1.1 安裝 Java 17+

#### 使用 sdkman（推薦）
```bash
# 安裝 sdkman
curl -s "https://get.sdkman.io" | bash
source ~/.sdkman/bin/sdkman-init.sh

# 安裝 Java
sdk install java 17.0.9-amzn
sdk use java 17.0.9-amzn
```

#### 或使用系統包管理器
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk

# macOS
brew install openjdk@17

# 設置 JAVA_HOME
export JAVA_HOME=/path/to/java
```

驗證：
```bash
java -version  # 應顯示 Java 17 或更高版本
```

### 1.2 安裝 Gradle 8.5+

#### 使用 sdkman（推薦）
```bash
source ~/.sdkman/bin/sdkman-init.sh
sdk install gradle 8.5
sdk use gradle 8.5
```

#### 或直接下載
```bash
cd /tmp
curl -L https://services.gradle.org/distributions/gradle-8.5-bin.zip -o gradle-8.5.zip
unzip gradle-8.5.zip
sudo mv gradle-8.5 /opt/gradle

# 添加到 PATH
export PATH=$PATH:/opt/gradle/gradle-8.5/bin
```

驗證：
```bash
gradle --version  # 應顯示 Gradle 8.5+
```

### 1.3 安裝 Android SDK

#### 使用 sdkman
```bash
source ~/.sdkman/bin/sdkman-init.sh
sdk install androidcommandlinetools 11.0
```

#### 或手動下載
```bash
# 下載 Android Command Line Tools
curl -o ~/cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip

# 解壓
unzip ~/cmdline-tools.zip -d ~/android-sdk-linux/
mkdir -p ~/android-sdk-linux/cmdline-tools/latest
mv ~/android-sdk-linux/cmdline-tools/* ~/android-sdk-linux/cmdline-tools/latest/ 2>/dev/null || true

# 設置環境變量
export ANDROID_HOME=$HOME/android-sdk-linux
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
```

### 1.4 安裝 Android SDK 組件

```bash
# 創建目錄
mkdir -p $ANDROID_HOME/licenses

# 同意許可證
echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license
echo -e "\n504667f4c0de7973335447fc681d51d756287ee6" > $ANDROID_HOME/licenses/google-android-sdk-license

# 安裝 SDK 組件
sdkmanager --sdk_root=$ANDROID_HOME "build-tools;35.0.0"
sdkmanager --sdk_root=$ANDROID_HOME "platforms;android-35"
sdkmanager --sdk_root=$ANDROID_HOME "platforms;android-34"

# 驗證
ls -la $ANDROID_HOME/platforms/
```

### 1.5 配置環境變量

編輯 `~/.bashrc` 或 `~/.zshrc`：

```bash
# Java
export JAVA_HOME=/path/to/java
export PATH=$JAVA_HOME/bin:$PATH

# Gradle
export GRADLE_HOME=/path/to/gradle
export PATH=$GRADLE_HOME/bin:$PATH

# Android SDK
export ANDROID_HOME=$HOME/android-sdk-linux
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
```

應用配置：
```bash
source ~/.bashrc
```

驗證完整環境：
```bash
java -version
gradle --version
echo $ANDROID_HOME
ls $ANDROID_HOME/platforms/
```

---

## 第 2 步：準備項目

### 2.1 檢查項目結構

```bash
cd /path/to/FileServeApp
ls -la android/
# 應該看到：
# ├── app/
# ├── build.gradle
# ├── settings.gradle
# ├── gradle.properties
# └── gradlew
```

### 2.2 驗證項目完整性

```bash
bash verify.sh
```

預期輸出：
```
✅ 所有檢查通過！項目完整無誤
✅ 可以開始構建 APK 了！
```

---

## 第 3 步：構建 APK

### 選項 1：使用構建腳本（推薦）

#### 交互式菜單
```bash
bash build.sh
# 選擇選項：
# 1. 檢查環境要求
# 2. 清理舊構建
# 3. 構建調試版
# 4. 構建發佈版
# 5. 安裝 APK
# 6. 完整構建流程
```

#### 直接命令
```bash
# 只構建發佈版
bash build.sh release

# 完整流程（清理→構建→安裝）
bash build.sh full
```

### 選項 2：直接使用 Gradle

#### 構建調試版（用於開發測試）
```bash
cd android
./gradlew assembleDebug
```

輸出位置：`android/app/build/outputs/apk/debug/app-debug.apk`

#### 構建發佈版（用於上線）
```bash
cd android
./gradlew assembleRelease
```

輸出位置：`android/app/build/outputs/apk/release/app-release.apk`

### 選項 3：全局 Gradle

```bash
cd android
gradle assembleRelease
```

---

## 第 4 步：驗證構建結果

### 檢查 APK 文件

```bash
# 檢查大小
ls -lh android/app/build/outputs/apk/release/app-release.apk

# 驗證 APK 內容
unzip -l android/app/build/outputs/apk/release/app-release.apk | head -30

# 檢查簽名
jarsigner -verify -verbose -certs android/app/build/outputs/apk/release/app-release.apk
```

---

## 第 5 步：安裝到設備

### 前置條件

```bash
# 檢查 ADB
adb version

# 列出連接的設備
adb devices
```

### 安裝 APK

```bash
# 安裝發佈版
adb install -r android/app/build/outputs/apk/release/app-release.apk

# 或安裝調試版
adb install -r android/app/build/outputs/apk/debug/app-debug.apk

# 驗證安裝
adb shell pm list packages | grep fileserveapp
```

### 啟動應用

```bash
# 方式 1：使用 ADB
adb shell am start -n com.fileserveapp/.MainActivity

# 方式 2：在設備上點擊應用圖標
```

---

## 第 6 步：訪問 Web 界面

### 獲取設備 IP

```bash
# 在設備上查看
設定 → 關於手機 → IP 地址

# 或通過 ADB
adb shell ip addr show
```

### 訪問文件管理器

在電腦瀏覽器中打開：
```
http://<設備IP>:8080
```

或使用 ADB 轉發（無需知道設備 IP）：
```bash
adb forward tcp:8080 tcp:8080
# 然後訪問 http://localhost:8080
```

---

## 常見問題解決

### 問題 1：找不到 Gradle

```bash
# 檢查 GRADLE_HOME
echo $GRADLE_HOME

# 添加到 PATH
export PATH=$GRADLE_HOME/bin:$PATH

# 驗證
gradle --version
```

### 問題 2：找不到 Android SDK

```bash
# 設置 ANDROID_HOME
export ANDROID_HOME=$HOME/android-sdk-linux

# 驗證
ls $ANDROID_HOME/platforms/
```

### 問題 3：Java 版本不兼容

```bash
# 檢查當前 Java
java -version

# 切換 Java 版本（使用 sdkman）
sdk list java
sdk use java <version>

# 或設置 JAVA_HOME
export JAVA_HOME=/path/to/java17
export PATH=$JAVA_HOME/bin:$PATH
```

### 問題 4：Gradle 守護進程錯誤

```bash
# 停止所有 Gradle 守護進程
gradle --stop

# 清理 gradle cache
rm -rf ~/.gradle

# 重新構建
cd android
./gradlew assembleRelease --no-daemon
```

### 問題 5：找不到 build-tools

```bash
# 檢查已安裝的工具
ls $ANDROID_HOME/build-tools/

# 如果不存在，安裝
sdkmanager --sdk_root=$ANDROID_HOME "build-tools;35.0.0"
```

### 問題 6：Java 25 不支持 MaxPermSize

✅ **已修復**：`gradle.properties` 已移除 `MaxPermSize` 參數

如果還有問題，執行：
```bash
cd android
./gradlew assembleRelease --no-daemon -Dorg.gradle.java.home=$JAVA_HOME
```

---

## 環境檢查清單

在開始構建前，確保以下全部通過：

```bash
#!/bin/bash
echo "=== 環境檢查清單 ==="
echo ""
echo "1. Java:"
java -version && echo "✅ PASS" || echo "❌ FAIL"

echo ""
echo "2. Gradle:"
gradle --version && echo "✅ PASS" || echo "❌ FAIL"

echo ""
echo "3. ANDROID_HOME:"
[ -n "$ANDROID_HOME" ] && echo "✅ 已設置: $ANDROID_HOME" || echo "❌ 未設置"

echo ""
echo "4. Android SDK Platforms:"
ls $ANDROID_HOME/platforms/ && echo "✅ PASS" || echo "❌ FAIL"

echo ""
echo "5. Android Build Tools:"
ls $ANDROID_HOME/build-tools/ && echo "✅ PASS" || echo "❌ FAIL"

echo ""
echo "=== 結果 ==="
echo "如果全部 ✅ PASS，可以開始構建！"
```

保存為 `check-env.sh` 並執行：
```bash
bash check-env.sh
```

---

## 完整構建流程（一次完成）

```bash
#!/bin/bash
set -e

echo "=== FileServeApp 完整構建流程 ==="

# 1. 檢查環境
echo "[1/5] 檢查環境..."
java -version || exit 1
gradle --version || exit 1

# 2. 清理舊構建
echo "[2/5] 清理舊構建..."
cd android
./gradlew clean || gradle clean

# 3. 構建發佈版
echo "[3/5] 構建發佈版 APK..."
./gradlew assembleRelease || gradle assembleRelease

# 4. 驗證
echo "[4/5] 驗證 APK..."
APK_PATH="app/build/outputs/apk/release/app-release.apk"
if [ -f "$APK_PATH" ]; then
    echo "✅ APK 構建成功"
    ls -lh "$APK_PATH"
else
    echo "❌ APK 構建失敗"
    exit 1
fi

# 5. 安裝（如果連接了設備）
echo "[5/5] 安裝到設備..."
if adb devices | grep -q "device$"; then
    adb install -r "$APK_PATH"
    echo "✅ APK 安裝完成"
else
    echo "⚠️  未連接設備，跳過安裝"
fi

echo ""
echo "=== 構建完成！==="
echo "APK 位置: $(pwd)/$APK_PATH"
```

保存為 `build-complete.sh` 並執行：
```bash
bash build-complete.sh
```

---

## 技術細節

### Gradle 配置說明

主要配置文件：

1. **android/gradle.properties**
   - JVM 參數：`-Xmx2048m`
   - AndroidX 支持：`android.useAndroidX=true`
   - R 類命名空間：`android.nonTransitiveRClass=true`

2. **android/app/build.gradle**
   - 編譯 SDK：35（Android 15）
   - 最低 SDK：34（Android 14）
   - 目標 SDK：35（Android 15）
   - 自動簽名配置

3. **android/settings.gradle**
   - 項目名稱：FileServeApp
   - 模塊配置：`:app`

### 構建產物

```
android/app/build/
├── outputs/
│   ├── apk/
│   │   ├── debug/
│   │   │   └── app-debug.apk          # 調試版（帶簽名）
│   │   └── release/
│   │       └── app-release.apk        # 發佈版（簽名）
│   └── bundle/
│       └── release/
│           └── app-release.aab        # Android App Bundle
├── intermediates/                      # 中間文件
└── ...
```

---

## 參考資源

- [Android Developer 官方文檔](https://developer.android.com/)
- [Gradle 用戶指南](https://docs.gradle.org/)
- [Android Gradle Plugin 文檔](https://developer.android.com/studio/build)
- [sdkman 官方網站](https://sdkman.io/)

---

## 支持與反饋

如遇到問題：

1. 運行 `bash verify.sh` 檢查項目完整性
2. 檢查環境變量設置
3. 查看 Gradle 日誌：`gradle assembleRelease --stacktrace`
4. 檢查 Java 版本兼容性

祝構建順利！🚀
