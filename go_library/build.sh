#!/bin/bash

# Clean previous builds
rm -rf build/
mkdir -p build

echo "Building Go shared libraries..."

# Set Android NDK path for macOS
export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.0.12077973

# Android ARM64
echo "Building for Android ARM64..."
CGO_ENABLED=1 GOOS=android GOARCH=arm64 CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-clang go build -buildmode=c-shared -o build/libgo_library.so .

# Android ARM
echo "Building for Android ARM..."
CGO_ENABLED=1 GOOS=android GOARCH=arm CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/armv7a-linux-androideabi21-clang go build -buildmode=c-shared -o build/libgo_library_arm.so .

# iOS (requires Go 1.16+)
echo "Building for iOS..."
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 go build -buildmode=c-archive -o build/libgo_library.a .

# macOS
echo "Building for macOS..."
CGO_ENABLED=1 GOOS=darwin GOARCH=amd64 go build -buildmode=c-shared -o build/libgo_library.dylib .

# macOS ARM64 (Apple Silicon)
echo "Building for macOS ARM64..."
CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 go build -buildmode=c-shared -o build/libgo_library_arm64.dylib .

# Windows
echo "Building for Windows..."
CGO_ENABLED=1 GOOS=windows GOARCH=amd64 go build -buildmode=c-shared -o build/go_library.dll .

# Linux
echo "Building for Linux..."
CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o build/libgo_library.so .

echo "Build completed!"
