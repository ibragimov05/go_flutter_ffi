# Flutter Go FFI Integration Guide

This guide demonstrates how to integrate Go code with Flutter using Foreign Function Interface (FFI), with special focus on iOS configuration.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Go Library Setup](#go-library-setup)
- [Building Go Libraries](#building-go-libraries)
- [Flutter FFI Setup](#flutter-ffi-setup)
- [iOS Configuration](#ios-configuration)
- [Android Configuration](#android-configuration)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- **Flutter SDK**: Latest stable version
- **Go**: Version 1.19+ (tested with 1.24.3)
- **Xcode**: Latest version (for iOS development)
- **Android Studio**: Latest version (for Android development)
- **macOS**: Required for iOS development

## Project Structure

```
your_project/
├── lib/
│   ├── main.dart
│   ├── home_screen.dart
│   └── native_bridge.dart
├── go_library/
│   ├── main.go
│   ├── go.mod
│   ├── build.sh
│   ├── build_ios.sh
│   └── build/
├── ios/
│   ├── Runner/
│   │   ├── Runner-Bridging-Header.h
│   │   └── libgo_library.h
│   └── libgo_library.a
├── android/
│   └── app/src/main/jniLibs/
└── pubspec.yaml
```

## Go Library Setup

### 1. Create Go Module

```bash
mkdir go_library
cd go_library
go mod init go_library
```

### 2. Write Go Code (`main.go`)

```go
package main

/*
#include <stdlib.h>
*/
import "C"
import "unsafe"

//export HelloWorld
func HelloWorld() *C.char {
    message := "Hello, world from Go!"
    return C.CString(message)
}

//export FreeString
func FreeString(str *C.char) {
    C.free(unsafe.Pointer(str))
}

//export AddNumbers
func AddNumbers(a, b C.int) C.int {
    return a + b
}

func main() {}
```

**Important Notes:**
- Use `//export` comments to expose functions to C
- Include `import "C"` for CGO functionality
- Always provide a `FreeString` function to prevent memory leaks
- Include `func main() {}` even though it's not used

## Building Go Libraries

### 1. Android Build Script (`build.sh`)

```bash
#!/bin/bash

# Clean previous builds
rm -rf build/
mkdir -p build

echo "Building Go libraries for Android..."

# Android ARM64
CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -buildmode=c-shared -o build/libgo_library.so .

echo "Android build completed!"
```

### 2. iOS Build Script (`build_ios.sh`)

```bash
#!/bin/bash

# Clean previous iOS builds
rm -rf build/ios/
mkdir -p build/ios

echo "Building Go libraries for iOS..."

# iOS Device (ARM64)
echo "Building for iOS Device (ARM64)..."
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 go build -buildmode=c-archive -o build/ios/libgo_library_device.a .

# iOS Simulator (ARM64 - for Apple Silicon Macs)
echo "Building for iOS Simulator (ARM64)..."
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 \
CGO_CFLAGS="-isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -target arm64-apple-ios14.0-simulator" \
CGO_LDFLAGS="-isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -target arm64-apple-ios14.0-simulator" \
go build -buildmode=c-archive -o build/ios/libgo_library_sim_arm64.a .

echo "iOS builds completed!"
```

### 3. Build Commands

```bash
# Make scripts executable
chmod +x build.sh
chmod +x build_ios.sh

# Build for Android
./build.sh

# Build for iOS
./build_ios.sh
```

## Flutter FFI Setup

### 1. Add Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  ffi: ^2.1.4
  path: ^1.9.1
```

### 2. Create Native Bridge (`lib/native_bridge.dart`)

```dart
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef HelloWorldNative = ffi.Pointer<Utf8> Function();
typedef HelloWorldDart = ffi.Pointer<Utf8> Function();

typedef FreeStringNative = ffi.Void Function(ffi.Pointer<Utf8>);
typedef FreeStringDart = void Function(ffi.Pointer<Utf8>);

typedef AddNumbersNative = ffi.Int32 Function(ffi.Int32, ffi.Int32);
typedef AddNumbersDart = int Function(int, int);

class NativeBridge {
  const NativeBridge._();

  static ffi.DynamicLibrary? _library;
  static HelloWorldDart? _helloWorld;
  static FreeStringDart? _freeString;
  static AddNumbersDart? _addNumbers;

  static ffi.DynamicLibrary get library {
    if (_library != null) return _library!;
    _library = _loadLibrary();
    return _library!;
  }

  static ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libgo_library.so');
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('go_library.dll');
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open('libgo_library.dylib');
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('libgo_library.so');
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  static HelloWorldDart get helloWorld =>
      _helloWorld ??= library.lookup<ffi.NativeFunction<HelloWorldNative>>('HelloWorld').asFunction<HelloWorldDart>();

  static FreeStringDart get freeString =>
      _freeString ??= library.lookup<ffi.NativeFunction<FreeStringNative>>('FreeString').asFunction<FreeStringDart>();

  static AddNumbersDart get addNumbers =>
      _addNumbers ??= library.lookup<ffi.NativeFunction<AddNumbersNative>>('AddNumbers').asFunction<AddNumbersDart>();

  static String getHelloWorld() {
    final pointer = helloWorld();
    if (pointer == ffi.nullptr) {
      throw Exception('Failed to get hello world string');
    }
    try {
      return pointer.toDartString();
    } finally {
      freeString(pointer);
    }
  }

  static int addTwoNumbers({required int a, required int b}) => addNumbers(a, b);

  static void dispose() {
    _library = null;
    _helloWorld = null;
    _freeString = null;
    _addNumbers = null;
  }
}
```

## iOS Configuration

### 1. Copy Library Files

```bash
# For iOS Simulator (during development)
cp go_library/build/ios/libgo_library_sim_arm64.a ios/libgo_library.a
cp go_library/build/ios/libgo_library_sim_arm64.a ios/Runner/libgo_library.a
cp go_library/build/ios/libgo_library_sim_arm64.h ios/Runner/libgo_library.h

# For iOS Device (for production)
cp go_library/build/ios/libgo_library_device.a ios/libgo_library.a
cp go_library/build/ios/libgo_library_device.a ios/Runner/libgo_library.a
cp go_library/build/ios/libgo_library_device.h ios/Runner/libgo_library.h
```

### 2. Update Bridging Header (`ios/Runner/Runner-Bridging-Header.h`)

```objc
#import "GeneratedPluginRegistrant.h"
#include "libgo_library.h"
```

### 3. Configure Xcode Project

Add the following to your iOS target's build settings in `ios/Runner.xcodeproj/project.pbxproj`:

For **Debug**, **Release**, and **Profile** configurations, add:

```xml
OTHER_LDFLAGS = (
    "$(inherited)",
    "-force_load",
    "$(PROJECT_DIR)/libgo_library.a",
);
```

**Complete example for Debug configuration:**

```xml
97C147061CF9000F007C117D /* Debug */ = {
    isa = XCBuildConfiguration;
    baseConfigurationReference = 9740EEB21CF90195004384FC /* Debug.xcconfig */;
    buildSettings = {
        ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        CLANG_ENABLE_MODULES = YES;
        CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
        DEVELOPMENT_TEAM = YOUR_TEAM_ID;
        ENABLE_BITCODE = NO;
        INFOPLIST_FILE = Runner/Info.plist;
        LD_RUNPATH_SEARCH_PATHS = (
            "$(inherited)",
            "@executable_path/Frameworks",
        );
        LIBRARY_SEARCH_PATHS = (
            "$(inherited)",
            "$(PROJECT_DIR)",
        );
        OTHER_LDFLAGS = (
            "$(inherited)",
            "-force_load",
            "$(PROJECT_DIR)/libgo_library.a",
        );
        PRODUCT_BUNDLE_IDENTIFIER = com.example.yourapp;
        PRODUCT_NAME = "$(TARGET_NAME)";
        SWIFT_OBJC_BRIDGING_HEADER = "Runner/Runner-Bridging-Header.h";
        SWIFT_OPTIMIZATION_LEVEL = "-Onone";
        SWIFT_VERSION = 5.0;
        VERSIONING_SYSTEM = "apple-generic";
    };
    name = Debug;
};
```

## Android Configuration

### 1. Copy Library Files

```bash
# Create JNI directories
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Copy Android library
cp go_library/build/libgo_library.so android/app/src/main/jniLibs/arm64-v8a/
```

### 2. Update Android Build (`android/app/build.gradle`)

```gradle
android {
    compileSdkVersion 34
    ndkVersion "25.1.8937393"

    defaultConfig {
        ndk {
            abiFilters 'arm64-v8a'
        }
    }
}
```

## Usage Examples

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'native_bridge.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _message = 'Tap the button to call Go function';
  String _additionResult = '';

  Future<void> _callGoFunction() async {
    try {
      final result = NativeBridge.getHelloWorld();
      setState(() => _message = result);
    } catch (e) {
      setState(() => _message = 'Error: $e');
    }
  }

  void _addNumbers() {
    try {
      final result = NativeBridge.addTwoNumbers(a: 10, b: 5);
      setState(() => _additionResult = '10 + 5 = $result');
    } catch (e) {
      setState(() => _additionResult = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter Go FFI Demo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_message, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _callGoFunction,
              child: Text('Call Go Function'),
            ),
            SizedBox(height: 20),
            Text(_additionResult, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNumbers,
              child: Text('Add Numbers in Go'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    NativeBridge.dispose();
    super.dispose();
  }
}
```

## Troubleshooting

### Common iOS Issues

#### 1. Symbol Not Found Error
```
Failed to lookup symbol 'HelloWorld': dlsym(RTLD_DEFAULT, HelloWorld): symbol not found
```

**Solutions:**
- Ensure the bridging header includes the Go library header
- Add `-force_load` flag to `OTHER_LDFLAGS` in Xcode project
- Verify the library is built for the correct architecture

#### 2. Architecture Mismatch
```
Building for 'iOS-simulator', but linking in object file built for 'macOS'
```

**Solutions:**
- Build the library specifically for iOS simulator:
```bash
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 \
CGO_CFLAGS="-isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -target arm64-apple-ios14.0-simulator" \
CGO_LDFLAGS="-isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -target arm64-apple-ios14.0-simulator" \
go build -buildmode=c-archive -o libgo_library_ios_sim.a .
```

#### 3. Header File Not Found
```
'libgo_library.h' file not found
```

**Solutions:**
- Copy the header file to `ios/Runner/` directory
- Ensure the bridging header includes the correct path

### Common Android Issues

#### 1. Library Not Found
```
java.lang.UnsatisfiedLinkError: dlopen failed
```

**Solutions:**
- Ensure the `.so` file is in the correct JNI directory
- Verify the library is built for the correct Android architecture
- Check that the library name matches exactly

### Build Script Debugging

#### Check Library Architecture
```bash
# For iOS
lipo -info ios/Runner/libgo_library.a

# For Android
file android/app/src/main/jniLibs/arm64-v8a/libgo_library.so
```

#### Verify Exported Symbols
```bash
# For iOS
nm -D ios/Runner/libgo_library.a | grep HelloWorld

# For Android
objdump -T android/app/src/main/jniLibs/arm64-v8a/libgo_library.so | grep HelloWorld
```

## Best Practices

1. **Memory Management**: Always provide and use `FreeString` functions for string returns
2. **Error Handling**: Wrap FFI calls in try-catch blocks
3. **Architecture Support**: Build for all required architectures (ARM64, x86_64)
4. **Testing**: Test on both simulators and physical devices
5. **Documentation**: Keep function signatures documented in both Go and Dart

## Additional Resources

- [Dart FFI Documentation](https://dart.dev/guides/libraries/c-interop)
- [Go CGO Documentation](https://golang.org/cmd/cgo/)
- [Flutter Platform Integration](https://docs.flutter.dev/development/platform-integration/c-interop)

---

This guide provides a complete setup for Flutter Go FFI integration with special attention to iOS configuration challenges. The key is proper library building, correct architecture targeting, and proper Xcode project configuration.
