#!/bin/bash

# FileServeApp - 自動編譯腳本
# 使用方法: ./build.sh [debug|release]

set -e  # 遇到錯誤立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函數：打印彩色消息
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# 檢查參數
BUILD_TYPE="${1:-release}"

if [ "$BUILD_TYPE" != "debug" ] && [ "$BUILD_TYPE" != "release" ]; then
    print_error "無效的編譯類型: $BUILD_TYPE"
    echo "使用方法: ./build.sh [debug|release]"
    exit 1
fi

print_info "開始編譯 FileServeApp ($BUILD_TYPE 模式)..."

# 步驟1：檢查環境
print_info "檢查環境..."

if ! command -v node &> /dev/null; then
    print_error "未找到 Node.js，請先安裝 Node.js >= 20"
    exit 1
fi
print_success "Node.js 已安裝: $(node -v)"

if ! command -v npm &> /dev/null; then
    print_error "未找到 npm"
    exit 1
fi
print_success "npm 已安裝: $(npm -v)"

if ! command -v java &> /dev/null; then
    print_error "未找到 Java，請先安裝 JDK"
    exit 1
fi
print_success "Java 已安裝: $(java -version 2>&1 | head -n 1)"

# 步驟2：進入專案目錄
cd MyApp

# 步驟3：安裝依賴
print_info "安裝 npm 依賴..."
if npm install; then
    print_success "npm 依賴安裝完成"
else
    print_error "npm 依賴安裝失敗"
    exit 1
fi

# 步驟4：清理舊的建構
print_info "清理舊的建構..."
cd android
if ./gradlew clean; then
    print_success "清理完成"
else
    print_error "清理失敗"
    exit 1
fi

# 步驟5：編譯APK
print_info "開始編譯 $BUILD_TYPE APK..."
if [ "$BUILD_TYPE" = "release" ]; then
    if ./gradlew assembleRelease; then
        print_success "Release APK 編譯完成"
        APK_PATH="app/build/outputs/apk/release/app-release.apk"
    else
        print_error "Release APK 編譯失敗"
        exit 1
    fi
else
    if ./gradlew assembleDebug; then
        print_success "Debug APK 編譯完成"
        APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    else
        print_error "Debug APK 編譯失敗"
        exit 1
    fi
fi

# 步驟6：顯示結果
cd ../..
FULL_PATH="MyApp/android/$APK_PATH"

if [ -f "$FULL_PATH" ]; then
    FILE_SIZE=$(du -h "$FULL_PATH" | cut -f1)
    print_success "編譯成功！"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 APK 資訊"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "位置: $FULL_PATH"
    echo "大小: $FILE_SIZE"
    echo "類型: $BUILD_TYPE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_info "下一步："
    echo "  1. 將APK傳輸到Android設備"
    echo "  2. 在設備上安裝APK"
    echo "  3. 授予必要的權限"
    echo "  4. 開啟應用並點擊「開始服務」"
    echo "  5. 在電腦瀏覽器開啟顯示的URL"
    echo ""
    
    # 如果有 adb，嘗試安裝
    if command -v adb &> /dev/null; then
        print_info "偵測到 adb 工具"
        read -p "是否要立即安裝到連接的設備？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "開始安裝..."
            if adb install -r "$FULL_PATH"; then
                print_success "安裝成功！"
                echo ""
                print_info "您可以執行以下命令啟動應用："
                echo "  adb shell am start -n com.myapp/.MainActivity"
            else
                print_error "安裝失敗"
            fi
        fi
    fi
else
    print_error "找不到編譯的APK檔案"
    exit 1
fi
