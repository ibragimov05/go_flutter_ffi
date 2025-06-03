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
