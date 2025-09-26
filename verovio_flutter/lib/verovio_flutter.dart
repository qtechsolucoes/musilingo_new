
// FASE 2.2: Interface Dart - Comunicação Flutter ↔ C++ Verovio nativo

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// FASE 2.2.1: Definição de tipos FFI para Verovio
typedef VerovioInitializeNative = Int32 Function();
typedef VerovioInitialize = int Function();

typedef VerovioSetOptionsNative = Int32 Function(Pointer<Utf8>);
typedef VerovioSetOptions = int Function(Pointer<Utf8>);

typedef VerovioLoadDataNative = Int32 Function(Pointer<Utf8>);
typedef VerovioLoadData = int Function(Pointer<Utf8>);

typedef VerovioRenderToSvgNative = Pointer<Utf8> Function(Int32);
typedef VerovioRenderToSvg = Pointer<Utf8> Function(int);

typedef VerovioGetPageCountNative = Int32 Function();
typedef VerovioGetPageCount = int Function();

typedef VerovioGetElementAttrNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef VerovioGetElementAttr = Pointer<Utf8> Function(Pointer<Utf8>);

typedef VerovioGetElementsAtTimeNative = Pointer<Utf8> Function(Int32);
typedef VerovioGetElementsAtTime = Pointer<Utf8> Function(int);

typedef VerovioRenderToMidiNative = Pointer<Utf8> Function();
typedef VerovioRenderToMidi = Pointer<Utf8> Function();

typedef VerovioValidateMusicXmlNative = Int32 Function(Pointer<Utf8>);
typedef VerovioValidateMusicXml = int Function(Pointer<Utf8>);

typedef VerovioConvertFileNative = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef VerovioConvertFile = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);

typedef VerovioCleanupNative = Void Function();
typedef VerovioCleanup = void Function();

typedef VerovioGetVersionNative = Pointer<Utf8> Function();
typedef VerovioGetVersion = Pointer<Utf8> Function();

class VerovioFlutter {
  static DynamicLibrary? _lib;

  // FASE 2.2.2: Carregamento da biblioteca nativa cross-platform
  static DynamicLibrary get _library {
    if (_lib != null) return _lib!;

    const String libName = 'verovio_flutter';

    if (Platform.isAndroid || Platform.isLinux) {
      _lib = DynamicLibrary.open('lib$libName.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      _lib = DynamicLibrary.open('$libName.framework/$libName');
    } else if (Platform.isWindows) {
      _lib = DynamicLibrary.open('$libName.dll');
    } else {
      throw UnsupportedError('Plataforma ${Platform.operatingSystem} não suportada');
    }

    return _lib!;
  }

  // FASE 2.2.3: Binding das funções C++ do Verovio
  static final _initialize = _library.lookupFunction<
      VerovioInitializeNative, VerovioInitialize>('verovio_initialize');

  static final _setOptions = _library.lookupFunction<
      VerovioSetOptionsNative, VerovioSetOptions>('verovio_set_options');

  static final _loadData = _library.lookupFunction<
      VerovioLoadDataNative, VerovioLoadData>('verovio_load_data');

  static final _renderToSvg = _library.lookupFunction<
      VerovioRenderToSvgNative, VerovioRenderToSvg>('verovio_render_to_svg');

  static final _getPageCount = _library.lookupFunction<
      VerovioGetPageCountNative, VerovioGetPageCount>('verovio_get_page_count');

  static final _getElementAttr = _library.lookupFunction<
      VerovioGetElementAttrNative, VerovioGetElementAttr>('verovio_get_element_attr');

  static final _getElementsAtTime = _library.lookupFunction<
      VerovioGetElementsAtTimeNative, VerovioGetElementsAtTime>('verovio_get_elements_at_time');

  static final _renderToMidi = _library.lookupFunction<
      VerovioRenderToMidiNative, VerovioRenderToMidi>('verovio_render_to_midi');

  static final _validateMusicXml = _library.lookupFunction<
      VerovioValidateMusicXmlNative, VerovioValidateMusicXml>('verovio_validate_musicxml');

  static final _convertFile = _library.lookupFunction<
      VerovioConvertFileNative, VerovioConvertFile>('verovio_convert_file');

  static final _cleanup = _library.lookupFunction<
      VerovioCleanupNative, VerovioCleanup>('verovio_cleanup');

  static final _getVersion = _library.lookupFunction<
      VerovioGetVersionNative, VerovioGetVersion>('verovio_get_version');

  // FASE 2.2.4: Métodos públicos da API Verovio

  /// Inicializa o engine Verovio com configurações padrão para mobile
  static bool initialize() {
    try {
      return _initialize() == 1;
    } catch (e) {
      return false;
    }
  }

  /// Configura opções de renderização via JSON
  static bool setOptions(String optionsJson) {
    final optionsPtr = optionsJson.toNativeUtf8();
    try {
      return _setOptions(optionsPtr) == 1;
    } finally {
      malloc.free(optionsPtr);
    }
  }

  /// Carrega dados MusicXML para renderização
  static bool loadMusicXML(String musicXML) {
    final dataPtr = musicXML.toNativeUtf8();
    try {
      return _loadData(dataPtr) == 1;
    } finally {
      malloc.free(dataPtr);
    }
  }

  /// Renderiza página específica para SVG
  static String? renderToSVG(int pageNumber) {
    try {
      final resultPtr = _renderToSvg(pageNumber);
      if (resultPtr.address == 0) return null;
      return resultPtr.toDartString();
    } catch (e) {
      return null;
    }
  }

  /// Obtém número total de páginas da partitura carregada
  static int getPageCount() {
    try {
      return _getPageCount();
    } catch (e) {
      return 0;
    }
  }

  /// Obtém atributos de elemento musical específico
  static String? getElementAttr(String xmlId) {
    final idPtr = xmlId.toNativeUtf8();
    try {
      final resultPtr = _getElementAttr(idPtr);
      if (resultPtr.address == 0) return null;
      return resultPtr.toDartString();
    } finally {
      malloc.free(idPtr);
    }
  }

  /// Obtém elementos musicais em tempo específico (para sincronização)
  static String? getElementsAtTime(int timeMs) {
    try {
      final resultPtr = _getElementsAtTime(timeMs);
      if (resultPtr.address == 0) return null;
      return resultPtr.toDartString();
    } catch (e) {
      return null;
    }
  }

  /// Renderiza partitura para MIDI
  static String? renderToMidi() {
    try {
      final resultPtr = _renderToMidi();
      if (resultPtr.address == 0) return null;
      return resultPtr.toDartString();
    } catch (e) {
      return null;
    }
  }

  /// Valida se MusicXML está bem formado
  static bool validateMusicXML(String musicXML) {
    final dataPtr = musicXML.toNativeUtf8();
    try {
      return _validateMusicXml(dataPtr) == 1;
    } finally {
      malloc.free(dataPtr);
    }
  }

  /// Converte arquivo de formato para MusicXML
  static String? convertFile(String data, String fromFormat) {
    final dataPtr = data.toNativeUtf8();
    final formatPtr = fromFormat.toNativeUtf8();
    try {
      final resultPtr = _convertFile(dataPtr, formatPtr);
      if (resultPtr.address == 0) return null;
      return resultPtr.toDartString();
    } finally {
      malloc.free(dataPtr);
      malloc.free(formatPtr);
    }
  }

  /// Limpa recursos e libera memória
  static void cleanup() {
    try {
      _cleanup();
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Obtém versão do Verovio
  static String getVersion() {
    try {
      final resultPtr = _getVersion();
      if (resultPtr.address == 0) return 'unknown';
      return resultPtr.toDartString();
    } catch (e) {
      return 'unknown';
    }
  }
}

// FASE 2.2.5: Classe de exceções específicas do Verovio
class VerovioException implements Exception {
  final String message;
  const VerovioException(this.message);

  @override
  String toString() => 'VerovioException: $message';
}
