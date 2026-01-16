# Flutter APK Build Docker Image
# This Dockerfile builds a Flutter Android APK

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up environment
ENV ANDROID_HOME=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$PATH:$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK Command Line Tools
RUN mkdir -p $ANDROID_HOME/cmdline-tools && \
    cd $ANDROID_HOME/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip -q commandlinetools-linux-9477386_latest.zip && \
    rm commandlinetools-linux-9477386_latest.zip && \
    mv cmdline-tools latest

# Accept Android SDK licenses and install required components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" && \
    sdkmanager "ndk;25.1.8937393"

# Install Flutter
RUN cd /opt && \
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 && \
    flutter doctor --android-licenses && \
    flutter doctor

# Set working directory
WORKDIR /app

# Copy project files
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get || true

COPY . .

# Build the APK
RUN flutter build apk --release

# Create output directory
RUN mkdir -p /output && \
    cp build/app/outputs/flutter-apk/app-release.apk /output/

# Set the default command to copy the APK to the mounted volume
CMD ["sh", "-c", "cp /output/app-release.apk /dist/app-release.apk && echo 'APK built successfully and copied to /dist/app-release.apk'"]
