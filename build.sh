#!/bin/bash
# 構建腳本 - 用於本地開發和測試

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FileServeApp 構建腳本 ===${NC}\n"

# 檢查環境
check_requirements() {
    echo -e "${YELLOW}檢查系統要求...${NC}"
    
    if ! command -v java &> /dev/null; then
        echo -e "${RED}❌ Java 未安裝${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Java: $(java -version 2>&1 | head -1)${NC}"
    
    if ! command -v gradle &> /dev/null; then
        echo -e "${RED}❌ Gradle 未安裝${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Gradle: $(gradle -v | grep "^Gradle")${NC}\n"
}

# 清理舊構建
clean_build() {
    echo -e "${YELLOW}清理舊構建...${NC}"
    cd android
    ./gradlew clean
    cd ..
    echo -e "${GREEN}✅ 清理完成\n${NC}"
}

# 構建調試版
build_debug() {
    echo -e "${YELLOW}構建調試版 APK...${NC}"
    cd android
    ./gradlew assembleDebug
    cd ..
    echo -e "${GREEN}✅ 調試版構建完成${NC}"
    echo -e "輸出文件: android/app/build/outputs/apk/debug/app-debug.apk\n"
}

# 構建發佈版
build_release() {
    echo -e "${YELLOW}構建發佈版 APK...${NC}"
    cd android
    ./gradlew assembleRelease
    cd ..
    echo -e "${GREEN}✅ 發佈版構建完成${NC}"
    echo -e "輸出文件: android/app/build/outputs/apk/release/app-release.apk\n"
}

# 安裝 APK
install_apk() {
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}❌ adb 未安裝或不在 PATH 中${NC}"
        return
    fi
    
    echo -e "${YELLOW}安裝 APK 到設備...${NC}"
    APK_PATH="android/app/build/outputs/apk/release/app-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        adb install -r "$APK_PATH"
        echo -e "${GREEN}✅ APK 安裝完成${NC}\n"
    else
        echo -e "${RED}❌ APK 文件不存在: $APK_PATH${NC}\n"
    fi
}

# 主菜單
show_menu() {
    echo -e "${YELLOW}請選擇操作:${NC}"
    echo "1. 檢查環境要求"
    echo "2. 清理舊構建"
    echo "3. 構建調試版"
    echo "4. 構建發佈版"
    echo "5. 安裝 APK"
    echo "6. 完整構建流程（清理 → 發佈版）"
    echo "0. 退出"
    echo ""
}

# 主程序
if [ $# -eq 0 ]; then
    # 交互模式
    while true; do
        show_menu
        read -p "選擇 [0-6]: " choice
        
        case $choice in
            1) check_requirements ;;
            2) clean_build ;;
            3) build_debug ;;
            4) build_release ;;
            5) install_apk ;;
            6) check_requirements && clean_build && build_release && install_apk ;;
            0) echo -e "${GREEN}退出${NC}"; exit 0 ;;
            *) echo -e "${RED}無效的選擇${NC}\n" ;;
        esac
    done
else
    # 命令行模式
    case "$1" in
        check) check_requirements ;;
        clean) clean_build ;;
        debug) build_debug ;;
        release) build_release ;;
        install) install_apk ;;
        full) check_requirements && clean_build && build_release && install_apk ;;
        *)
            echo "使用方法: $0 [check|clean|debug|release|install|full]"
            echo ""
            echo "命令:"
            echo "  check   - 檢查系統要求"
            echo "  clean   - 清理舊構建"
            echo "  debug   - 構建調試版 APK"
            echo "  release - 構建發佈版 APK"
            echo "  install - 安裝 APK 到設備"
            echo "  full    - 完整構建流程"
            exit 1
            ;;
    esac
fi
