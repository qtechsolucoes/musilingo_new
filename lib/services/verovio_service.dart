// lib/services/verovio_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:verovio_flutter/verovio_flutter.dart';

class VerovioService {
  static VerovioService? _instance;
  static VerovioService get instance => _instance ??= VerovioService._();
  VerovioService._();

  bool _isInitialized = false;
  String? currentSVG;
  final Map<String, String> _svgCache = {};

  // O estado do toolkit é mantido nativamente, então não precisamos de uma instância de _verovio aqui.

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    try {
      debugPrint('🔄 Inicializando Verovio...');
      // Chamada estática correta
      VerovioFlutter.initialize();
      await _runDiagnostics();
      _isInitialized = true;
      debugPrint('✅ FASE 3.1: Verovio inicializado com sucesso!');
    } catch (e) {
      _isInitialized = false;
      debugPrint('❌ FASE 3.1: Falha ao inicializar Verovio: $e');
      rethrow;
    }
  }

  Future<void> _runDiagnostics() async {
    debugPrint('🔄 Iniciando diagnóstico completo do Verovio...');
    try {
      debugPrint('🔍 Testando disponibilidade do VerovioFlutter...');
      // Chamada estática correta
      final version = VerovioFlutter.getVersion();
      if (version.isNotEmpty && version != 'unknown') {
        debugPrint('📋 Versão Verovio disponível: $version');
      } else {
        throw Exception('Versão do Verovio não encontrada');
      }
      await _applyDefaultOptions();
      debugPrint('✅ SUCESSO: Verovio REAL $version totalmente funcional');
    } catch (e) {
      debugPrint('❌ FASE 3.1: Diagnóstico falhou: $e');
      throw Exception('Diagnóstico completo do Verovio falhou');
    }
  }

  Future<void> _applyDefaultOptions() async {
    final options = {
      'pageWidth': 1200,
      'pageHeight': 400,
      'scale': 50,
      'font': 'Bravura',
      'bgColor': 'transparent',
      'stroke': '#000000', // Cor preta para visibilidade no fundo branco
      'pageMarginTop': 0,
      'pageMarginBottom': 0,
      'pageMarginLeft': 0,
      'pageMarginRight': 0,
    };
    // Converte o Map para uma String JSON e chama o método estático
    VerovioFlutter.setOptions(jsonEncode(options));
  }

  Future<String?> renderMusicXML(
    String musicXML, {
    String? cacheKey,
    double zoomLevel = 1.0,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final effectiveCacheKey = cacheKey ?? musicXML.hashCode.toString();
    if (_svgCache.containsKey(effectiveCacheKey)) {
      debugPrint('🚀 Cache hit para $effectiveCacheKey');
      currentSVG = _svgCache[effectiveCacheKey];
      // Recarregar os dados no toolkit para garantir que ele esteja no estado certo para edições
      VerovioFlutter.loadMusicXML(musicXML);
      return currentSVG;
    }

    try {
      debugPrint(
          '🎵 Tentando Verovio com MusicXML (${musicXML.length} chars)...');

      final scale = (50 * zoomLevel).round();
      final options = {
        'pageWidth': (2000 * zoomLevel).round(),
        'pageHeight': (400 * zoomLevel).round(),
        'scale': scale,
        'stroke': '#000000', // Garante a cor preta para visibilidade
      };

      // Chamadas estáticas e na ordem correta
      VerovioFlutter.setOptions(jsonEncode(options));
      VerovioFlutter.loadMusicXML(musicXML);
      final svg = VerovioFlutter.renderToSVG(1); // Renderiza a primeira página

      if (svg != null && svg.isNotEmpty) {
        currentSVG = svg;
        _svgCache[effectiveCacheKey] = svg;
        debugPrint('💾 SVG do Verovio salvo no cache: $effectiveCacheKey');
        return svg;
      } else {
        throw Exception('SVG gerado é inválido ou vazio');
      }
    } catch (e) {
      debugPrint('❌ FASE 3.1: Erro na renderização do Verovio: $e');
      return null;
    }
  }

  // Métodos de coloração agora são simulados, pois a FFI atual não os expõe.
  // A lógica correta seria adicionar `colorNote` à sua FFI em C++.
  // Por enquanto, vamos retornar o SVG atual para não quebrar a UI.
  Future<String?> colorNote(String noteId, String color) async {
    debugPrint(
        "⚠️ AVISO: A função 'colorNote' não está implementada na FFI atual. Nenhuma mudança visual ocorrerá.");
    return currentSVG;
  }

  Future<String?> colorMultipleNotes(Map<String, String> noteColors) async {
    debugPrint(
        "⚠️ AVISO: A função 'colorMultipleNotes' não está implementada na FFI atual. Nenhuma mudança visual ocorrerá.");
    return currentSVG;
  }

  Future<void> clearAllColors() async {
    debugPrint(
        "⚠️ AVISO: A função 'clearAllColors' não está implementada na FFI atual.");
    // Para limpar as cores, precisaríamos recarregar o SVG original.
    // O sistema de cache já lida com isso na próxima renderização.
  }

  // Funções de zoom e largura da página agora funcionam corretamente
  Future<void> setZoomLevel(double zoom) async {
    if (!_isInitialized) return;
    final options = {'scale': (50 * zoom).round()};
    VerovioFlutter.setOptions(jsonEncode(options));
  }

  Future<void> setPageWidth(int width) async {
    if (!_isInitialized) return;
    final options = {'pageWidth': width};
    VerovioFlutter.setOptions(jsonEncode(options));
  }

  void clearCache() {
    _svgCache.clear();
    debugPrint('🗑️ Cache do Verovio limpo');
  }
}
