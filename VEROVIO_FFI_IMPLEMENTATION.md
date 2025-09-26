# Implementação Verovio FFI para MusiLingo
## Migração Completa de OSMD para Verovio C++ Nativo via Flutter FFI

### 🎯 Objetivo
Substituir completamente o sistema OSMD (OpenSheetMusicDisplay) por **Verovio C++** nativo usando **Flutter FFI** (Foreign Function Interface) para máxima performance, controle total da renderização musical e suporte completo a todos os símbolos musicais SMuFL.

### 📋 Visão Geral do Processo

#### **FASE 1: Preparação e Setup** ⚙️
1. Criação do plugin Flutter FFI
2. Configuração do ambiente de build C++
3. Download e preparação do Verovio C++
4. Configuração de headers FFI

#### **FASE 2: Implementação Core** 🔧
5. Criação da bridge C/C++
6. Implementação da interface Dart/Flutter
7. Compilação cross-platform (Android/iOS)
8. Testes básicos de renderização

#### **FASE 3: Integração MusiLingo** 🎵
9. Criação do VerovioService
10. Migração do sistema de solfejo
11. Atualização dos widgets de partitura
12. Implementação de controles avançados

#### **FASE 4: Otimização e Features** ⚡
13. Cache de renderização
14. Coloração de notas nativa
15. Scroll e zoom otimizados
16. Suporte a múltiplas partituras simultâneas

---

## 📐 Arquitetura Final

```
MusiLingo App
    ↕ Dart FFI
VerovioPlugin (C++)
    ↕ C++ API
Verovio Engine
    ↓ SVG Output
Flutter SVG Widget
```

---

## 🚀 FASE 1: Preparação e Setup

### 1.1 Criação do Plugin Flutter FFI

**Comando de criação:**
```bash
cd C:\desenvolvimento_musitech\musilingo
flutter create --template=plugin_ffi --platforms=android,ios,linux,macos,windows verovio_flutter
```

**Estrutura do plugin:**
```
verovio_flutter/
├── lib/
│   └── verovio_flutter.dart          # Interface Dart principal
├── src/
│   ├── verovio_flutter.h             # Headers C/C++
│   └── verovio_flutter.cpp           # Implementação C++
├── android/
│   └── CMakeLists.txt                # Build Android
├── ios/
│   └── verovio_flutter.podspec       # Build iOS
└── pubspec.yaml
```

### 1.2 Configuração do Ambiente

**Dependências necessárias:**
- **Android**: NDK 25+, CMake 3.22+
- **iOS**: Xcode 14+, CocoaPods
- **Windows**: Visual Studio 2022
- **macOS**: Xcode Command Line Tools

### 1.3 Download do Verovio

**Repositório oficial:**
```bash
git clone --recursive https://github.com/rism-digital/verovio.git
cd verovio
git checkout master  # Versão estável mais recente
```

---

## 🔧 FASE 2: Implementação Core

### 2.1 Bridge C/C++ (verovio_flutter.cpp)

**Processo: Criação da ponte entre Verovio C++ e Flutter FFI**

```cpp
// FASE 2.1: Bridge C/C++ - Wrapper para Verovio Engine
#include "verovio_flutter.h"
#include "vrv/toolkit.h"
#include <string>
#include <memory>

// Instância global do toolkit Verovio
static std::unique_ptr<vrv::Toolkit> g_vrvToolkit = nullptr;

// FASE 2.1.1: Inicialização do Verovio Engine
extern "C" {

    __declspec(dllexport) int verovio_initialize() {
        try {
            g_vrvToolkit = std::make_unique<vrv::Toolkit>();
            return 1; // Sucesso
        } catch (...) {
            return 0; // Falha
        }
    }

    // FASE 2.1.2: Configuração de opções de renderização
    __declspec(dllexport) int verovio_set_options(const char* options_json) {
        if (!g_vrvToolkit) return 0;

        try {
            std::string options(options_json);
            return g_vrvToolkit->setOptions(options) ? 1 : 0;
        } catch (...) {
            return 0;
        }
    }

    // FASE 2.1.3: Carregamento de MusicXML
    __declspec(dllexport) int verovio_load_data(const char* musicxml) {
        if (!g_vrvToolkit) return 0;

        try {
            std::string data(musicxml);
            return g_vrvToolkit->loadData(data) ? 1 : 0;
        } catch (...) {
            return 0;
        }
    }

    // FASE 2.1.4: Renderização para SVG
    __declspec(dllexport) const char* verovio_render_to_svg(int page_number) {
        if (!g_vrvToolkit) return nullptr;

        try {
            static std::string svg_result;
            svg_result = g_vrvToolkit->renderToSVG(page_number);
            return svg_result.c_str();
        } catch (...) {
            return nullptr;
        }
    }

    // FASE 2.1.5: Obter informações da partitura
    __declspec(dllexport) int verovio_get_page_count() {
        if (!g_vrvToolkit) return 0;
        return g_vrvToolkit->getPageCount();
    }

    // FASE 2.1.6: Coloração de elementos musicais
    __declspec(dllexport) const char* verovio_get_element_attr(const char* xml_id) {
        if (!g_vrvToolkit) return nullptr;

        try {
            std::string id(xml_id);
            static std::string attr_result;
            attr_result = g_vrvToolkit->getElementAttr(id);
            return attr_result.c_str();
        } catch (...) {
            return nullptr;
        }
    }

    // FASE 2.1.7: Cleanup
    __declspec(dllexport) void verovio_cleanup() {
        g_vrvToolkit.reset();
    }
}
```

### 2.2 Interface Dart (verovio_flutter.dart)

**Processo: Interface Flutter para comunicação com C++**

```dart
// FASE 2.2: Interface Dart - Comunicação Flutter ↔ C++
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// FASE 2.2.1: Definição de tipos FFI
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

typedef VerovioCleanupNative = Void Function();
typedef VerovioCleanup = void Function();

class VerovioFlutter {
  static DynamicLibrary? _lib;

  // FASE 2.2.2: Carregamento da biblioteca nativa
  static DynamicLibrary get _library {
    if (_lib != null) return _lib!;

    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libverovio_flutter.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.executable();
    } else if (Platform.isWindows) {
      _lib = DynamicLibrary.open('verovio_flutter.dll');
    } else if (Platform.isMacOS) {
      _lib = DynamicLibrary.open('libverovio_flutter.dylib');
    } else if (Platform.isLinux) {
      _lib = DynamicLibrary.open('libverovio_flutter.so');
    } else {
      throw UnsupportedError('Plataforma não suportada');
    }

    return _lib!;
  }

  // FASE 2.2.3: Binding das funções C++
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

  static final _cleanup = _library.lookupFunction<
    VerovioCleanupNative, VerovioCleanup>('verovio_cleanup');

  // FASE 2.2.4: Métodos públicos da API
  static bool initialize() {
    return _initialize() == 1;
  }

  static bool setOptions(String optionsJson) {
    final optionsPtr = optionsJson.toNativeUtf8();
    try {
      return _setOptions(optionsPtr) == 1;
    } finally {
      malloc.free(optionsPtr);
    }
  }

  static bool loadMusicXML(String musicXML) {
    final dataPtr = musicXML.toNativeUtf8();
    try {
      return _loadData(dataPtr) == 1;
    } finally {
      malloc.free(dataPtr);
    }
  }

  static String? renderToSVG(int pageNumber) {
    final resultPtr = _renderToSvg(pageNumber);
    if (resultPtr.address == 0) return null;
    return resultPtr.toDartString();
  }

  static int getPageCount() {
    return _getPageCount();
  }

  static void cleanup() {
    _cleanup();
  }
}
```

### 2.3 Configuração de Build

**Processo: Compilação cross-platform**

#### **2.3.1 Android CMakeLists.txt**
```cmake
# FASE 2.3.1: Build Android - Configuração CMake
cmake_minimum_required(VERSION 3.22)
project(verovio_flutter)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Verovio source path
set(VEROVIO_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../verovio")

# Include Verovio headers
include_directories(${VEROVIO_SOURCE_DIR}/include)
include_directories(${VEROVIO_SOURCE_DIR}/include/vrv)

# Verovio source files
file(GLOB_RECURSE VEROVIO_SOURCES
    "${VEROVIO_SOURCE_DIR}/src/*.cpp"
    "${VEROVIO_SOURCE_DIR}/libmei/src/*.cpp"
)

# Plugin source
add_library(verovio_flutter SHARED
    "../src/verovio_flutter.cpp"
    ${VEROVIO_SOURCES}
)

target_link_libraries(verovio_flutter
    android
    log
)
```

#### **2.3.2 iOS Configuration (verovio_flutter.podspec)**
```ruby
# FASE 2.3.2: Build iOS - Configuração CocoaPods
Pod::Spec.new do |spec|
  spec.name          = 'verovio_flutter'
  spec.version       = '0.0.1'
  spec.license       = { :file => '../LICENSE' }
  spec.homepage      = 'https://example.com'
  spec.authors       = { 'Your Company' => 'email@example.com' }
  spec.summary       = 'Verovio music notation rendering for Flutter'

  spec.source              = { :path => '.' }
  spec.source_files        = 'Classes/**/*', '../src/**/*', '../verovio/src/**/*'
  spec.public_header_files = 'Classes/**/*.h', '../src/**/*.h'

  spec.dependency 'Flutter'
  spec.platform = :ios, '12.0'

  # Configurações C++20
  spec.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }
end
```

---

## 🎵 FASE 3: Integração MusiLingo

### 3.1 VerovioService (Replacement para OSMD)

**Processo: Criação do service principal para renderização**

```dart
// FASE 3.1: VerovioService - Substituição completa do sistema OSMD
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../plugins/verovio_flutter.dart';

class VerovioService {
  static VerovioService? _instance;
  static VerovioService get instance => _instance ??= VerovioService._();
  VerovioService._();

  bool _isInitialized = false;
  String? _currentSVG;
  Map<String, String> _svgCache = {};

  // FASE 3.1.1: Inicialização do service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = VerovioFlutter.initialize();

      if (_isInitialized) {
        // Configurações padrão para mobile
        await setDefaultMobileOptions();
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Erro ao inicializar Verovio: $e');
      return false;
    }
  }

  // FASE 3.1.2: Configurações otimizadas para mobile
  Future<void> setDefaultMobileOptions() async {
    final options = {
      'scale': 35,                    // Escala para mobile
      'pageWidth': 350,               // Largura padrão mobile
      'pageHeight': 2970,             // Altura A4 proporcionalmente
      'spacingStaff': 6,              // Espaçamento entre pentagramas
      'spacingSystem': 8,             // Espaçamento entre sistemas
      'breaks': 'auto',               // Quebras automáticas
      'font': 'Leland',               // Fonte SMuFL padrão
      'header': 'none',               // Sem cabeçalho
      'footer': 'none',               // Sem rodapé
      'adjustPageHeight': true,       // Ajustar altura da página
      'pageMarginTop': 50,            // Margem superior
      'pageMarginBottom': 50,         // Margem inferior
      'pageMarginLeft': 50,           // Margem esquerda
      'pageMarginRight': 50,          // Margem direita
    };

    VerovioFlutter.setOptions(jsonEncode(options));
  }

  // FASE 3.1.3: Renderização com cache
  Future<String?> renderMusicXML(String musicXML, {String? cacheKey}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Verificar cache
    if (cacheKey != null && _svgCache.containsKey(cacheKey)) {
      return _svgCache[cacheKey];
    }

    try {
      // Carregar MusicXML no Verovio
      final loaded = VerovioFlutter.loadMusicXML(musicXML);
      if (!loaded) {
        throw Exception('Falha ao carregar MusicXML');
      }

      // Renderizar primeira página
      final svg = VerovioFlutter.renderToSVG(1);
      if (svg == null) {
        throw Exception('Falha ao renderizar SVG');
      }

      _currentSVG = svg;

      // Armazenar em cache
      if (cacheKey != null) {
        _svgCache[cacheKey] = svg;
      }

      return svg;
    } catch (e) {
      debugPrint('Erro ao renderizar MusicXML: $e');
      return null;
    }
  }

  // FASE 3.1.4: Controles avançados de renderização
  Future<void> setZoomLevel(double zoom) async {
    final options = {
      'scale': (35 * zoom).round(),
    };

    VerovioFlutter.setOptions(jsonEncode(options));

    // Re-renderizar se há conteúdo carregado
    if (_currentSVG != null) {
      _currentSVG = VerovioFlutter.renderToSVG(1);
    }
  }

  Future<void> setPageWidth(int width) async {
    final options = {
      'pageWidth': width,
    };

    VerovioFlutter.setOptions(jsonEncode(options));
  }

  // FASE 3.1.5: Coloração de notas (substituição do OSMD)
  Future<String?> colorNote(String noteId, String color) async {
    // Implementação de coloração via manipulação SVG
    if (_currentSVG == null) return null;

    try {
      // Aplicar cor diretamente no SVG
      String coloredSVG = _currentSVG!.replaceAll(
        'id="$noteId"',
        'id="$noteId" fill="$color" stroke="$color"'
      );

      return coloredSVG;
    } catch (e) {
      debugPrint('Erro ao colorir nota: $e');
      return _currentSVG;
    }
  }

  // FASE 3.1.6: Limpeza de recursos
  void dispose() {
    _svgCache.clear();
    _currentSVG = null;
    VerovioFlutter.cleanup();
    _isInitialized = false;
  }
}
```

### 3.2 VerovioScoreWidget (Replacement para OptimizedScoreView)

**Processo: Widget Flutter para exibir partituras renderizadas**

```dart
// FASE 3.2: VerovioScoreWidget - Substituição do OptimizedScoreView OSMD
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/verovio_service.dart';

class VerovioScoreWidget extends StatefulWidget {
  final String musicXML;
  final String? cacheKey;
  final double zoom;
  final VoidCallback? onScoreLoaded;
  final Function(String noteId)? onNotePressed;

  const VerovioScoreWidget({
    Key? key,
    required this.musicXML,
    this.cacheKey,
    this.zoom = 1.0,
    this.onScoreLoaded,
    this.onNotePressed,
  }) : super(key: key);

  @override
  State<VerovioScoreWidget> createState() => _VerovioScoreWidgetState();
}

class _VerovioScoreWidgetState extends State<VerovioScoreWidget> {
  String? _svgContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  @override
  void didUpdateWidget(VerovioScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-renderizar se MusicXML ou zoom mudaram
    if (oldWidget.musicXML != widget.musicXML ||
        oldWidget.zoom != widget.zoom) {
      _loadScore();
    }
  }

  // FASE 3.2.1: Carregamento da partitura
  Future<void> _loadScore() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Aplicar zoom antes de renderizar
      await VerovioService.instance.setZoomLevel(widget.zoom);

      // Renderizar partitura
      final svg = await VerovioService.instance.renderMusicXML(
        widget.musicXML,
        cacheKey: widget.cacheKey,
      );

      if (!mounted) return;

      if (svg != null) {
        setState(() {
          _svgContent = svg;
          _isLoading = false;
        });

        widget.onScoreLoaded?.call();
      } else {
        throw Exception('Falha ao renderizar partitura');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // FASE 3.2.2: Coloração de notas em tempo real
  Future<void> colorNote(String noteId, String color) async {
    if (_svgContent == null) return;

    final coloredSVG = await VerovioService.instance.colorNote(noteId, color);
    if (coloredSVG != null && mounted) {
      setState(() {
        _svgContent = coloredSVG;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // FASE 3.2.3: UI da partitura
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Renderizando partitura...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erro ao carregar partitura'),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScore,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_svgContent == null) {
      return const Center(child: Text('Nenhuma partitura para exibir'));
    }

    // FASE 3.2.4: Exibição do SVG com interação
    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 3.0,
      child: GestureDetector(
        onTapDown: (details) {
          // FASE 3.2.5: Detecção de toque em notas (futuro)
          // Implementar detecção de elementos SVG tocados
          // widget.onNotePressed?.call(noteId);
        },
        child: SvgPicture.string(
          _svgContent!,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
```

### 3.3 Migração do Sistema de Solfejo

**Processo: Atualização do SolfegeExerciseProvider para usar Verovio**

```dart
// FASE 3.3: Migração Solfejo - Atualização do provider para Verovio
// Localização: lib/features/practice_solfege/providers/solfege_exercise_provider.dart

// FASE 3.3.1: Imports atualizados
import '../../../services/verovio_service.dart';
import '../widgets/verovio_score_widget.dart';

class SolfegeExerciseProvider extends StateNotifier<SolfegeExerciseState> {
  // ... código existente ...

  // FASE 3.3.2: Substituição do método de renderização
  Future<void> _generateAndRenderScore() async {
    try {
      // Gerar MusicXML (método existente)
      final musicXML = _musicXmlBuilder.generateMusicXML(
        exercise: state.exercise!,
        isOctaveDown: state.isOctaveDown,
      );

      // NOVA IMPLEMENTAÇÃO: Usar Verovio em vez de OSMD
      await VerovioService.instance.initialize();

      state = state.copyWith(
        musicXML: musicXML,
        // Remover campos relacionados ao OSMD se existirem
        isScoreLoaded: true,
      );

      debugPrint('✅ FASE 3.3: Partitura renderizada com Verovio');
    } catch (e) {
      debugPrint('❌ FASE 3.3: Erro ao renderizar com Verovio: $e');
      state = state.copyWith(
        error: 'Erro ao carregar partitura: $e',
      );
    }
  }

  // FASE 3.3.3: Nova implementação de coloração de notas
  Future<void> highlightNote(int noteIndex) async {
    if (!state.isScoreLoaded || state.musicXML == null) return;

    try {
      // Identificar nota no SVG (implementação simplificada)
      final noteId = 'note-$noteIndex';

      // Usar Verovio para colorir nota
      await VerovioService.instance.colorNote(noteId, '#FFD700');

      state = state.copyWith(currentNoteIndex: noteIndex);

      debugPrint('✅ FASE 3.3: Nota $noteIndex destacada com Verovio');
    } catch (e) {
      debugPrint('❌ FASE 3.3: Erro ao destacar nota: $e');
    }
  }

  // FASE 3.3.4: Aplicação de feedback visual
  Future<void> applyResultsFeedback(List<NoteResult> results) async {
    if (!state.isScoreLoaded) return;

    try {
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final noteId = 'note-$i';
        final color = result.pitchCorrect ? '#00CC00' : '#CC0000';

        await VerovioService.instance.colorNote(noteId, color);
      }

      debugPrint('✅ FASE 3.3: Feedback visual aplicado com Verovio');
    } catch (e) {
      debugPrint('❌ FASE 3.3: Erro ao aplicar feedback: $e');
    }
  }
}
```

---

## ⚡ FASE 4: Otimização e Features Avançadas

### 4.1 Sistema de Cache Avançado

**Processo: Cache inteligente para melhor performance**

```dart
// FASE 4.1: Sistema de Cache - Otimização de performance
class VerovioCache {
  static const int maxCacheSize = 50;
  static final Map<String, CachedScore> _cache = <String, CachedScore>{};

  // FASE 4.1.1: Estrutura do cache
  static String generateCacheKey(String musicXML, double zoom, Map<String, dynamic>? options) {
    final optionsStr = options != null ? jsonEncode(options) : '';
    return '${musicXML.hashCode}_${zoom}_${optionsStr.hashCode}';
  }

  // FASE 4.1.2: Armazenamento com TTL
  static void store(String key, String svg) {
    if (_cache.length >= maxCacheSize) {
      // Remove o item mais antigo
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = CachedScore(
      svg: svg,
      timestamp: DateTime.now(),
    );
  }

  // FASE 4.1.3: Recuperação com validação TTL
  static String? get(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    // Cache válido por 1 hora
    if (DateTime.now().difference(cached.timestamp).inHours > 1) {
      _cache.remove(key);
      return null;
    }

    return cached.svg;
  }
}

class CachedScore {
  final String svg;
  final DateTime timestamp;

  CachedScore({required this.svg, required this.timestamp});
}
```

### 4.2 Controles Avançados

**Processo: Zoom, layout e configurações avançadas**

```dart
// FASE 4.2: Controles Avançados - Substituição dos controles OSMD
class VerovioAdvancedControls extends StatefulWidget {
  final Function(double zoom)? onZoomChanged;
  final Function(int width)? onWidthChanged;
  final Function(String font)? onFontChanged;

  @override
  State<VerovioAdvancedControls> createState() => _VerovioAdvancedControlsState();
}

class _VerovioAdvancedControlsState extends State<VerovioAdvancedControls> {
  double _zoom = 1.0;
  int _pageWidth = 350;
  String _selectedFont = 'Leland';

  // FASE 4.2.1: Controle de zoom nativo
  void _handleZoomChange(double zoom) async {
    setState(() => _zoom = zoom);

    await VerovioService.instance.setZoomLevel(zoom);
    widget.onZoomChanged?.call(zoom);
  }

  // FASE 4.2.2: Controle de largura
  void _handleWidthChange(int width) async {
    setState(() => _pageWidth = width);

    await VerovioService.instance.setPageWidth(width);
    widget.onWidthChanged?.call(width);
  }

  // FASE 4.2.3: Seleção de fonte SMuFL
  void _handleFontChange(String font) async {
    setState(() => _selectedFont = font);

    final options = {'font': font};
    await VerovioService.instance.setOptions(jsonEncode(options));
    widget.onFontChanged?.call(font);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FASE 4.2.4: Slider de zoom
        ListTile(
          title: Text('Zoom: ${(_zoom * 100).round()}%'),
          subtitle: Slider(
            value: _zoom,
            min: 0.5,
            max: 3.0,
            divisions: 25,
            onChanged: _handleZoomChange,
          ),
        ),

        // FASE 4.2.5: Controle de largura
        ListTile(
          title: Text('Largura: $_pageWidth px'),
          subtitle: Slider(
            value: _pageWidth.toDouble(),
            min: 200,
            max: 500,
            divisions: 30,
            onChanged: (value) => _handleWidthChange(value.round()),
          ),
        ),

        // FASE 4.2.6: Seleção de fonte
        ListTile(
          title: const Text('Fonte Musical'),
          subtitle: DropdownButton<String>(
            value: _selectedFont,
            onChanged: (font) => font != null ? _handleFontChange(font) : null,
            items: const [
              DropdownMenuItem(value: 'Leland', child: Text('Leland')),
              DropdownMenuItem(value: 'Bravura', child: Text('Bravura')),
              DropdownMenuItem(value: 'Petaluma', child: Text('Petaluma')),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## 📋 Checklist de Implementação

### ✅ FASE 1: Setup
- [ ] 1.1 Criar plugin Flutter FFI
- [ ] 1.2 Configurar ambiente de build
- [ ] 1.3 Download e setup do Verovio
- [ ] 1.4 Configurar headers FFI

### ✅ FASE 2: Core
- [ ] 2.1 Implementar bridge C/C++
- [ ] 2.2 Criar interface Dart
- [ ] 2.3 Configurar build Android
- [ ] 2.4 Configurar build iOS
- [ ] 2.5 Testes básicos

### ✅ FASE 3: Integração
- [ ] 3.1 Criar VerovioService
- [ ] 3.2 Implementar VerovioScoreWidget
- [ ] 3.3 Migrar SolfegeExerciseProvider
- [ ] 3.4 Atualizar SolfegeExerciseScreen
- [ ] 3.5 Testes de integração

### ✅ FASE 4: Otimização
- [ ] 4.1 Sistema de cache
- [ ] 4.2 Controles avançados
- [ ] 4.3 Coloração de notas
- [ ] 4.4 Múltiplas partituras
- [ ] 4.5 Performance profiling

---

## 🔧 Comandos de Build

### Android
```bash
cd android
./gradlew assembleDebug
```

### iOS
```bash
cd ios
pod install
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug
```

### Teste do Plugin
```bash
cd verovio_flutter/example
flutter run
```

---

## 🚨 Pontos de Atenção

### Performance
- Cache agressivo de SVGs renderizados
- Lazy loading de partituras grandes
- Profiling de memória regularmente

### Compatibilidade
- Testar em diferentes versões Android/iOS
- Verificar tamanhos de fonte para diferentes DPIs
- Validar em devices low-end

### Debug
- Logs detalhados em cada fase
- Comentários indicando fase de implementação
- Fallbacks para problemas de renderização

---

## 🔄 Processo de Continuação

**Em caso de interrupção, verificar:**

1. **Última fase completada** nos comentários de código
2. **Estado dos arquivos** usando git status
3. **Logs de erro** para debugging
4. **Cache limpo** antes de continuar

**Para continuar de qualquer ponto:**
- Buscar comentários `// FASE X.Y:`
- Verificar checklist acima
- Executar testes da fase atual
- Prosseguir para próxima fase

---

*Documento criado para garantir continuidade da implementação Verovio FFI no MusiLingo*
*Última atualização: 2025-01-25*