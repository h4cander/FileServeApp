#!/bin/bash
# 項目驗證腳本 - 檢查項目完整性和構建環境

set -e

# 顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   FileServeApp 項目驗證                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

ERRORS=0
WARNINGS=0

# 檢查文件
echo -e "${YELLOW}📋 檢查項目文件...${NC}"
files=(
    "README.md"
    "QUICKSTART.md"
    "SETUP.md"
    "DELIVERY.md"
    "build.sh"
    "android/build.gradle"
    "android/settings.gradle"
    "android/app/build.gradle"
    "android/app/src/main/AndroidManifest.xml"
    "android/app/src/main/java/com/fileserveapp/MainActivity.java"
    "android/app/src/main/java/com/fileserveapp/FileServerService.java"
    "android/app/src/main/java/com/fileserveapp/FileServerThread.java"
    "android/app/src/main/java/com/fileserveapp/LogWriter.java"
    "android/app/src/main/assets/www/index.html"
    "android/app/src/main/res/layout/activity_main.xml"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $file"
    else
        echo -e "${RED}❌${NC} 缺失: $file"
        ((ERRORS++))
    fi
done

echo ""

# 檢查環境
echo -e "${YELLOW}🔧 檢查系統環境...${NC}"

if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | grep "version" | head -1)
    echo -e "${GREEN}✅${NC} Java: $JAVA_VERSION"
else
    echo -e "${YELLOW}⚠️${NC}  Java 未安裝（本地構建需要）"
    ((WARNINGS++))
fi

if command -v gradle &> /dev/null; then
    echo -e "${GREEN}✅${NC} Gradle: $(gradle -v | head -1)"
else
    echo -e "${YELLOW}⚠️${NC}  Gradle 未安裝（本地構建需要）"
    ((WARNINGS++))
fi

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✅${NC} Docker: $DOCKER_VERSION（可選）"
else
    echo -e "${YELLOW}ℹ️${NC}  Docker 未安裝（可選，本地構建不需要）"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅${NC} npm: v$NPM_VERSION"
else
    echo -e "${YELLOW}⚠️${NC}  npm 未安裝"
    ((WARNINGS++))
fi

echo ""

# 檢查目錄結構
echo -e "${YELLOW}📁 檢查目錄結構...${NC}"

dirs=(
    "android"
    "android/app/src/main"
    "android/app/src/main/java/com/fileserveapp"
    "android/app/src/main/res"
    "android/app/src/main/assets/www"
    "scripts"
)

for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅${NC} $dir"
    else
        echo -e "${RED}❌${NC} 缺失目錄: $dir"
        ((ERRORS++))
    fi
done

echo ""

# 檢查 Gradle 配置
echo -e "${YELLOW}⚙️  檢查 Gradle 配置...${NC}"

if grep -q "compileSdk 35" android/app/build.gradle; then
    echo -e "${GREEN}✅${NC} Gradle SDK 版本正確 (compileSdk 35)"
else
    echo -e "${YELLOW}⚠️${NC}  Gradle SDK 版本可能不匹配"
    ((WARNINGS++))
fi

if grep -q "minSdk 34" android/app/build.gradle; then
    echo -e "${GREEN}✅${NC} 最低 SDK 版本正確 (minSdk 34, Android 14)"
else
    echo -e "${YELLOW}⚠️${NC}  最低 SDK 版本可能不匹配"
    ((WARNINGS++))
fi

echo ""

# 檢查權限
echo -e "${YELLOW}🔐 檢查 Android 權限...${NC}"

permissions=(
    "MANAGE_EXTERNAL_STORAGE"
    "READ_EXTERNAL_STORAGE"
    "WRITE_EXTERNAL_STORAGE"
    "INTERNET"
    "FOREGROUND_SERVICE"
)

for perm in "${permissions[@]}"; do
    if grep -q "android.permission.$perm" android/app/src/main/AndroidManifest.xml; then
        echo -e "${GREEN}✅${NC} $perm"
    else
        echo -e "${YELLOW}⚠️${NC}  缺失權限: $perm"
        ((WARNINGS++))
    fi
done

echo ""

# 文件行數統計
echo -e "${YELLOW}📊 代碼統計...${NC}"

JAVA_FILES=$(find android -name "*.java" -type f | wc -l)
XML_FILES=$(find android -name "*.xml" -type f | wc -l)
GRADLE_FILES=$(find android -name "*.gradle" -type f | wc -l)
JAVA_LINES=$(find android -name "*.java" -type f -exec wc -l {} + | tail -1 | awk '{print $1}')

echo -e "${GREEN}ℹ️${NC}  Java 文件: $JAVA_FILES 個"
echo -e "${GREEN}ℹ️${NC}  XML 文件: $XML_FILES 個"
echo -e "${GREEN}ℹ️${NC}  Gradle 文件: $GRADLE_FILES 個"
echo -e "${GREEN}ℹ️${NC}  Java 代碼行: $JAVA_LINES 行"

echo ""

# 總結
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ 所有檢查通過！項目完整無誤${NC}"
    echo -e "${GREEN}可以開始構建 APK 了！${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  有 $WARNINGS 個警告（不影響構建）${NC}"
    echo -e "${YELLOW}建議檢查但可以繼續構建${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}❌ 有 $ERRORS 個錯誤需要修復${NC}"
    echo -e "${RED}請解決上述問題後重試${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    exit 1
fi
