@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

setlocal enabledelayedexpansion

set GRADLE_VERSION=8.5
set GRADLE_HOME_URL=https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-bin.zip
set GRADLE_HOME=%APP_PATH%\.gradle
set GRADLE_ZIP=%GRADLE_HOME%\gradle-%GRADLE_VERSION%.zip
set GRADLE_HOME_PATH=%GRADLE_HOME%\gradle-%GRADLE_VERSION%

if not exist "%GRADLE_HOME%" mkdir "%GRADLE_HOME%"

if not exist "%GRADLE_HOME_PATH%" (
    echo Downloading Gradle %GRADLE_VERSION%...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%GRADLE_HOME_URL%' -OutFile '%GRADLE_ZIP%'}"
    powershell -Command "& {Expand-Archive -Path '%GRADLE_ZIP%' -DestinationPath '%GRADLE_HOME%'}"
    del "%GRADLE_ZIP%"
)

"%GRADLE_HOME_PATH%\bin\gradle.bat" %*

endlocal
