#!/bin/bash
# CI/CD 構建腳本 - 本地環境

set -e

echo "================================"
echo "  FileServeApp APK 構建開始"
echo "================================"

# 檢查環境
echo "[1/4] 檢查環境..."
java -version
gradle --version
echo "✅ 環境就緒\n"

# 安裝 npm 依賴
echo "[2/4] 安裝 npm 依賴..."
npm install --silent
echo "✅ npm 依賴安裝完成\n"

# 進入 Android 目錄並構建
echo "[3/4] 構建 APK..."
cd android
chmod +x gradlew
./gradlew assembleRelease -x lint --stacktrace
cd ..
echo "✅ APK 構建完成\n"

# 列出輸出文件
echo "[4/4] 構建結果..."
APK_FILE="android/app/build/outputs/apk/release/app-release.apk"

if [ -f "$APK_FILE" ]; then
    SIZE=$(du -h "$APK_FILE" | cut -f1)
    echo "================================"
    echo "✅ 構建成功！"
    echo "================================"
    echo "APK 文件: $APK_FILE"
    echo "文件大小: $SIZE"
    echo ""
    echo "完整路徑: $(pwd)/$APK_FILE"
    echo "================================\n"
    
    # 驗證 APK 簽名
    echo "驗證 APK 簽名..."
    jarsigner -verify -verbose -certs "$APK_FILE" || echo "⚠️  簽名驗證提示（開發簽名可能無效）"
else
    echo "❌ 構建失敗：未找到 APK 文件"
    exit 1
fi

echo "構建完成！"
