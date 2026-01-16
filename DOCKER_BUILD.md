# Docker Build Guide

This guide explains how to build the Flutter APK using Docker, without needing to install Flutter or Android SDK on your local machine.

## Prerequisites

- Docker installed on your system
  - [Docker Desktop for Windows/Mac](https://www.docker.com/products/docker-desktop)
  - [Docker Engine for Linux](https://docs.docker.com/engine/install/)

## Quick Start

### Linux/Mac

```bash
./build-apk.sh
```

### Windows

```cmd
build-apk.bat
```

### Manual Docker Command

```bash
# Build the Docker image
docker build -t fileserveapp-builder .

# Run the container to build APK
docker run --rm -v $(pwd)/dist:/dist fileserveapp-builder
```

## Output

The built APK will be located at:
```
./dist/app-release.apk
```

## Using Docker Compose

Alternatively, you can use docker-compose:

```bash
# Build and run
docker-compose up --build

# The APK will be in ./dist/app-release.apk
```

## Build Process

The Docker build does the following:

1. **Base Image**: Uses Ubuntu 22.04
2. **Install Dependencies**: 
   - Java 11 (for Android builds)
   - Git, curl, unzip, etc.
3. **Install Android SDK**: 
   - Command Line Tools
   - Platform Tools
   - Android 34 SDK
   - Build Tools 34.0.0
   - NDK 25.1.8937393
4. **Install Flutter**: 
   - Clones Flutter stable branch
   - Runs flutter doctor
5. **Build APK**:
   - Copies project files
   - Runs `flutter pub get`
   - Runs `flutter build apk --release`
6. **Output**: Copies APK to `/dist` volume

## Troubleshooting

### Docker not found

Make sure Docker is installed and running:

```bash
docker --version
```

### Permission denied (Linux/Mac)

Make the script executable:

```bash
chmod +x build-apk.sh
```

### Build fails

1. Check Docker logs:
   ```bash
   docker logs fileserveapp-builder
   ```

2. Try cleaning Docker cache:
   ```bash
   docker system prune -a
   ```

3. Rebuild without cache:
   ```bash
   docker build --no-cache -t fileserveapp-builder .
   ```

### Out of disk space

Docker images can be large (3-4 GB). Make sure you have enough disk space:

```bash
docker system df
```

Clean up unused Docker resources:

```bash
docker system prune -a
```

## Advanced Usage

### Build debug APK

Modify the Dockerfile to build debug APK instead:

```dockerfile
RUN flutter build apk --debug
```

### Custom output location

```bash
docker run --rm -v /path/to/output:/dist fileserveapp-builder
```

### Interactive shell (for debugging)

```bash
docker run --rm -it fileserveapp-builder /bin/bash
```

### Build with specific Flutter version

Edit the Dockerfile and change the Flutter branch:

```dockerfile
RUN cd /opt && \
    git clone https://github.com/flutter/flutter.git -b 3.16.0 --depth 1
```

## Image Size

The Docker image is approximately 3-4 GB due to:
- Android SDK (~2 GB)
- Flutter SDK (~1 GB)
- System dependencies (~500 MB)

## CI/CD Integration

### GitHub Actions

```yaml
name: Build APK

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build APK with Docker
        run: |
          docker build -t fileserveapp-builder .
          docker run --rm -v $(pwd)/dist:/dist fileserveapp-builder
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release
          path: dist/app-release.apk
```

### GitLab CI

```yaml
build-apk:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t fileserveapp-builder .
    - docker run --rm -v $(pwd)/dist:/dist fileserveapp-builder
  artifacts:
    paths:
      - dist/app-release.apk
```

## Security Considerations

- The Docker image downloads Flutter and Android SDK from official sources
- All licenses are automatically accepted (for non-interactive builds)
- The built APK is unsigned (uses debug keystore)
- For production releases, sign the APK with your own keystore

## Performance Tips

### Use Docker BuildKit

Enable BuildKit for faster builds:

```bash
DOCKER_BUILDKIT=1 docker build -t fileserveapp-builder .
```

### Reuse Docker layers

The Dockerfile is optimized to cache layers. Dependencies are installed before copying source code, so rebuilds are faster.

### Multi-stage builds

For smaller images, consider using multi-stage builds (only copies the APK):

```dockerfile
FROM ubuntu:22.04 as builder
# ... build steps ...

FROM scratch
COPY --from=builder /output/app-release.apk /app-release.apk
```

## Comparison with Local Build

| Feature | Docker Build | Local Build |
|---------|-------------|-------------|
| Setup Time | First build: ~20 min | First setup: ~30 min |
| Disk Space | ~3-4 GB | ~3-4 GB |
| Build Time | ~5-10 min | ~3-5 min |
| Portability | ✅ Works anywhere | ❌ Machine-specific |
| Reproducibility | ✅ Consistent | ⚠️ May vary |
| Updates | Rebuild image | `flutter upgrade` |

## Maintenance

### Update Flutter version

Edit Dockerfile and rebuild:

```dockerfile
RUN cd /opt && \
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
```

### Update Android SDK

Edit sdkmanager commands in Dockerfile:

```dockerfile
RUN sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
```

## Support

For issues with:
- **Docker setup**: Check [Docker documentation](https://docs.docker.com/)
- **Flutter build errors**: Check [Flutter documentation](https://docs.flutter.dev/)
- **App-specific issues**: Create an issue on GitHub

## License

The Docker build scripts are part of this project and follow the same license as the main project.
