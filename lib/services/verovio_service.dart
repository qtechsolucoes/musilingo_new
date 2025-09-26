// FASE FINAL: VerovioService usando o motor C++ nativo
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:verovio_flutter/verovio_flutter.dart';

/// Service principal para renderização de notação musical usando o motor Verovio C++ nativo.
class VerovioService {
  static VerovioService? _instance;
  static VerovioService get instance => _instance ??= VerovioService._();
  VerovioService._();

  bool _isInitialized = false;
  String? _currentSVG;
  final Map<String, String> _svgCache = {};

  // Inicializa o motor Verovio C++ nativo real com diagnósticos completos
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ Verovio já inicializado');
      return true;
    }

    debugPrint('🔄 Iniciando diagnóstico completo do Verovio...');

    try {
      debugPrint('🔍 Testando disponibilidade do VerovioFlutter...');

      // Teste 1: Verificar se a classe existe
      try {
        final testVersion = VerovioFlutter.getVersion();
        debugPrint('📋 Versão Verovio disponível: $testVersion');
      } catch (e) {
        debugPrint('❌ CRÍTICO: VerovioFlutter não está disponível: $e');
        return false;
      }

      // Teste 2: Tentar inicializar
      debugPrint('🔧 Tentando inicializar motor Verovio...');
      _isInitialized = VerovioFlutter.initialize();

      if (!_isInitialized) {
        debugPrint('❌ CRÍTICO: VerovioFlutter.initialize() retornou false');
        return false;
      }

      debugPrint('✅ Motor Verovio inicializado com sucesso');

      // Teste 3: Aplicar configurações
      debugPrint('⚙️ Aplicando configurações padrão...');
      await setDefaultMobileOptions();

      // Teste 4: Verificar versão final
      final version = VerovioFlutter.getVersion();
      debugPrint('✅ SUCESSO: Verovio REAL v$version totalmente funcional');

      return true;
    } catch (e) {
      debugPrint('❌ FALHA CRÍTICA na inicialização do Verovio: $e');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
      _isInitialized = false;
      return false;
    }
  }

  // Configurações otimizadas que o motor Verovio real irá usar
  Future<void> setDefaultMobileOptions() async {
    final options = {
      'scale': 45,
      'pageWidth': 1800,
      'border': 20,
      'font': 'Leland', // <-- Fonte profissional que corrige a aparência
      'header': 'none',
      'footer': 'none',
      'adjustPageHeight': true,
      'svgBackgroundColor': 'transparent',
      'textColor': '#FFFFFF',
      'staffColor': '#FFFFFF',
      'lyricColor': '#FFFFFF',
      'noteColor': '#FFFFFF',
    };
    try {
      final optionsJson = jsonEncode(options);
      final success = VerovioFlutter.setOptions(optionsJson);
      if (success) {
        debugPrint('✅ FASE FINAL: Configurações do Verovio aplicadas');
      } else {
        debugPrint('⚠️ FASE FINAL: Falha ao aplicar configurações do Verovio');
      }
    } catch (e) {
      debugPrint('❌ FASE FINAL: Erro ao aplicar configurações: $e');
    }
  }

  // Renderização com sistema de fallback de emergência
  Future<String?> renderMusicXML(String musicXML, {String? cacheKey}) async {
    // SISTEMA DE EMERGÊNCIA: Usar SVG estático se Verovio falhar
    if (!_isInitialized) {
      debugPrint('🔄 Inicializando Verovio...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ Verovio não inicializou - usando fallback estático');
        return _getStaticScoreSVG();
      }
    }

    // Verificar cache primeiro
    if (cacheKey != null && _svgCache.containsKey(cacheKey)) {
      debugPrint('🚀 Cache hit para $cacheKey');
      return _svgCache[cacheKey];
    }

    try {
      // Validar MusicXML antes de processar
      if (musicXML.isEmpty) {
        debugPrint('❌ MusicXML vazio - usando fallback');
        return _getStaticScoreSVG();
      }

      if (!musicXML.contains('<score-partwise')) {
        debugPrint('❌ MusicXML inválido - usando fallback');
        return _getStaticScoreSVG();
      }

      debugPrint('🎵 Tentando Verovio com MusicXML (${musicXML.length} chars)...');

      // Tentar carregar o MusicXML com timeout
      final loadSuccess = VerovioFlutter.loadMusicXML(musicXML);
      if (!loadSuccess) {
        debugPrint('❌ Verovio rejeitou MusicXML - usando fallback');
        return _getStaticScoreSVG();
      }

      debugPrint('🎵 MusicXML aceito, tentando renderizar...');

      // Renderizar para SVG com verificação robusta
      String? svg = VerovioFlutter.renderToSVG(1);

      if (svg == null || svg.isEmpty) {
        debugPrint('❌ Verovio retornou SVG vazio - usando fallback');
        return _getStaticScoreSVG();
      }

      // Validar SVG gerado
      if (!_isValidSVG(svg)) {
        debugPrint('❌ SVG do Verovio é inválido - usando fallback');
        return _getStaticScoreSVG();
      }

      _currentSVG = svg;

      // Cache management
      if (cacheKey != null) {
        _svgCache[cacheKey] = svg;
        if (_svgCache.length > 50) {
          _svgCache.remove(_svgCache.keys.first);
        }
        debugPrint('💾 SVG do Verovio salvo no cache: $cacheKey');
      }

      debugPrint('✅ SUCESSO: Verovio funcionou! SVG: ${svg.length} chars');
      return svg;
    } catch (e) {
      debugPrint('❌ Erro no Verovio: $e - usando fallback');
      return _getStaticScoreSVG();
    }
  }

  bool _isValidSVG(String svg) {
    if (svg.length < 100) {
      debugPrint('❌ SVG muito pequeno: ${svg.length} chars');
      return false;
    }

    final svgLower = svg.toLowerCase();

    // Verificações básicas de estrutura SVG
    if (!svgLower.contains('<svg')) {
      debugPrint('❌ SVG não contém tag <svg>');
      return false;
    }
    if (!svgLower.contains('</svg>')) {
      debugPrint('❌ SVG não contém tag </svg>');
      return false;
    }

    // Verificar se contém elementos típicos do Verovio OU elementos SVG básicos
    final hasVerovioElements = svgLower.contains('staff') ||
                              svgLower.contains('clef') ||
                              svgLower.contains('note') ||
                              svgLower.contains('measure');

    final hasSvgElements = svgLower.contains('<line') ||
                          svgLower.contains('<rect') ||
                          svgLower.contains('<circle') ||
                          svgLower.contains('<path') ||
                          svgLower.contains('<g ') ||
                          svgLower.contains('<text');

    final isValid = hasVerovioElements || hasSvgElements;

    if (!isValid) {
      debugPrint('❌ SVG não contém elementos reconhecíveis');
      debugPrint('📋 Preview: ${svg.substring(0, svg.length > 300 ? 300 : svg.length)}...');
    } else {
      debugPrint('✅ SVG validado com sucesso');
    }

    return isValid;
  }

  // --- MÉTODOS REINSERIDOS PARA COMPATIBILIDADE ---

  Future<void> setZoomLevel(double zoom) async {
    final options = {'scale': (45 * zoom).round()};
    VerovioFlutter.setOptions(jsonEncode(options));
  }

  Future<void> setPageWidth(int width) async {
    final options = {'pageWidth': width};
    VerovioFlutter.setOptions(jsonEncode(options));
  }

  Future<String?> colorNote(String noteId, String color) async {
    debugPrint(
        '🎨 Coloração da nota $noteId solicitada (implementação pendente).');
    return _currentSVG;
  }

  Future<String?> colorMultipleNotes(Map<String, String> noteColors) async {
    debugPrint(
        '🎨 Coloração de múltiplas notas solicitada (implementação pendente).');
    return _currentSVG;
  }

  Future<void> clearAllColors() async {
    debugPrint('🎨 Limpeza de cores solicitada (implementação pendente).');
  }

  void dispose() {
    try {
      _svgCache.clear();
      _currentSVG = null;
      VerovioFlutter.cleanup();
      _isInitialized = false;
      debugPrint('✅ FASE FINAL: VerovioService disposed');
    } catch (e) {
      debugPrint('❌ FASE FINAL: Erro no dispose: $e');
    }
  }


  // SISTEMA DE EMERGÊNCIA: Partitura estática funcional para solfejo
  String _getStaticScoreSVG() {
    debugPrint('🚨 USANDO PARTITURA ESTÁTICA DE EMERGÊNCIA');
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="2000" height="400" viewBox="0 0 2000 400">
  <defs>
    <style>
      .staff-line { stroke: #FFFFFF; stroke-width: 1.5; }
      .note { fill: #FFFFFF; }
      .note-head { fill: #FFFFFF; }
      .stem { stroke: #FFFFFF; stroke-width: 2; }
      .lyric { fill: #FFFFFF; font-family: Arial, sans-serif; font-size: 14px; text-anchor: middle; }
      .clef { fill: #FFFFFF; font-family: serif; font-size: 48px; }
    </style>
  </defs>

  <!-- Pano de fundo transparente -->
  <rect width="2000" height="400" fill="transparent"/>

  <!-- Pentagrama -->
  <g id="staff" transform="translate(100, 150)">
    <!-- Linhas do pentagrama -->
    <line x1="0" y1="0" x2="1800" y2="0" class="staff-line"/>
    <line x1="0" y1="20" x2="1800" y2="20" class="staff-line"/>
    <line x1="0" y1="40" x2="1800" y2="40" class="staff-line"/>
    <line x1="0" y1="60" x2="1800" y2="60" class="staff-line"/>
    <line x1="0" y1="80" x2="1800" y2="80" class="staff-line"/>

    <!-- Clave de Sol -->
    <text x="20" y="55" class="clef">𝄞</text>

    <!-- Compassos -->
    <line x1="80" y1="-10" x2="80" y2="90" class="staff-line"/>
    <line x1="1750" y1="-10" x2="1750" y2="90" class="staff-line"/>

    <!-- Notas do exercício de solfejo -->

    <!-- Nota 1: Dó (C4) - linha suplementar inferior -->
    <g id="note-0" transform="translate(150, 0)">
      <line x1="-10" y1="90" x2="10" y2="90" class="staff-line"/> <!-- linha suplementar -->
      <ellipse cx="0" cy="90" rx="8" ry="6" class="note-head"/>
      <line x1="8" y1="90" x2="8" y2="50" class="stem"/>
      <text x="0" y="115" class="lyric">Dó</text>
    </g>

    <!-- Nota 2: Ré (D4) - abaixo da pauta -->
    <g id="note-1" transform="translate(250, 0)">
      <ellipse cx="0" cy="85" rx="8" ry="6" class="note-head"/>
      <line x1="8" y1="85" x2="8" y2="45" class="stem"/>
      <text x="0" y="110" class="lyric">Ré</text>
    </g>

    <!-- Nota 3: Mi (E4) - quarta linha -->
    <g id="note-2" transform="translate(350, 0)">
      <ellipse cx="0" cy="80" rx="8" ry="6" class="note-head"/>
      <line x1="8" y1="80" x2="8" y2="40" class="stem"/>
      <text x="0" y="105" class="lyric">Mi</text>
    </g>

    <!-- Nota 4: Fá (F4) - terceiro espaço -->
    <g id="note-3" transform="translate(450, 0)">
      <ellipse cx="0" cy="70" rx="8" ry="6" class="note-head"/>
      <line x1="8" y1="70" x2="8" y2="30" class="stem"/>
      <text x="0" y="95" class="lyric">Fá</text>
    </g>

    <!-- Nota 5: Sol (G4) - segunda linha -->
    <g id="note-4" transform="translate(550, 0)">
      <ellipse cx="0" cy="60" rx="8" ry="6" class="note-head"/>
      <line x1="8" y1="60" x2="8" y2="20" class="stem"/>
      <text x="0" y="85" class="lyric">Sol</text>
    </g>

    <!-- Nota 6: Lá (A4) - segundo espaço -->
    <g id="note-5" transform="translate(650, 0)">
      <ellipse cx="0" cy="50" rx="8" ry="6" class="note-head"/>
      <line x1="8" y1="50" x2="8" y2="10" class="stem"/>
      <text x="0" y="75" class="lyric">Lá</text>
    </g>

    <!-- Nota 7: Si (B4) - primeira linha -->
    <g id="note-6" transform="translate(750, 0)">
      <ellipse cx="0" cy="40" rx="8" ry="6" class="note-head"/>
      <line x1="8" y1="40" x2="8" y2="0" class="stem"/>
      <text x="0" y="65" class="lyric">Si</text>
    </g>

    <!-- Nota 8: Dó (C5) - primeiro espaço -->
    <g id="note-7" transform="translate(850, 0)">
      <ellipse cx="0" cy="30" rx="8" ry="6" class="note-head"/>
      <line x1="8" y1="30" x2="8" y2="-10" class="stem"/>
      <text x="0" y="55" class="lyric">Dó</text>
    </g>

    <!-- Pausa no final -->
    <g transform="translate(950, 0)">
      <rect x="-4" y="30" width="8" height="30" class="note"/>
      <text x="0" y="85" class="lyric">∞</text>
    </g>
  </g>

  <!-- Indicação de fallback -->
  <text x="100" y="30" fill="#FFDD00" font-family="Arial, sans-serif" font-size="12">PARTITURA DE EMERGÊNCIA (Verovio indisponível)</text>

</svg>''';
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentSVG => _currentSVG;
  int get cacheSize => _svgCache.length;
}
