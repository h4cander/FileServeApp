@echo off
REM Flutter APK Build Script using Docker (Windows)
REM This script builds the Flutter Android APK using Docker

echo ================================
echo Flutter APK Builder
echo ================================
echo.

REM Create dist directory if it doesn't exist
if not exist dist mkdir dist

echo Building Docker image...
docker build -t fileserveapp-builder .

echo.
echo Running container to build APK...
docker run --rm -v "%cd%/dist:/dist" fileserveapp-builder

echo.
echo ================================
echo Build complete!
echo APK location: %cd%\dist\app-release.apk
echo ================================
