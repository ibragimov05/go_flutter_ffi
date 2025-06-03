#!/bin/bash

# Clean previous iOS builds
rm -rf build/ios/
mkdir -p build/ios

echo "Building Go libraries for iOS..."

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
echo "Using Go version: $GO_VERSION"

# iOS Device (ARM64)
echo "Building for iOS Device (ARM64)..."
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 go build -buildmode=c-archive -o build/ios/libgo_library_device.a .

# iOS Simulator (ARM64 - for Apple Silicon Macs)
echo "Building for iOS Simulator (ARM64)..."
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 go build -buildmode=c-archive -o build/ios/libgo_library_sim_arm64.a .

# Note: iOS Simulator x86_64 build is problematic with newer Go versions
# If you need x86_64 simulator support, consider using older Go versions or alternative approaches

echo "iOS builds completed!"
echo "Files created:"
ls -la build/ios/

echo ""
echo "To use in Xcode:"
echo "1. Copy the .a files to your iOS project"
echo "2. Copy the .h file to your iOS project"
echo "3. Add the .a files to your Xcode project's 'Link Binary With Libraries'"
echo "4. Import the header file in your Objective-C/Swift code"
