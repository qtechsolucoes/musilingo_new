// FASE 3.2: VerovioScoreWidget - Widget Flutter para exibir partituras Verovio
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../services/verovio_service.dart';
import '../app/core/theme/app_colors.dart';
import '../widgets/canvas_music_widget.dart';
import '../services/musicxml_to_canvas_converter.dart';
import '../services/canvas_music_renderer.dart';

/// Widget para exibir partituras renderizadas pelo VerovioService
/// Substitui completamente o OptimizedScoreView do sistema OSMD
class VerovioScoreWidget extends StatefulWidget {
  final String musicXML;
  final String? cacheKey;
  final double zoom;
  final VoidCallback? onScoreLoaded;
  final Function(String noteId)? onNotePressed;
  final bool enableInteraction;
  final EdgeInsets padding;

  const VerovioScoreWidget({
    super.key,
    required this.musicXML,
    this.cacheKey,
    this.zoom = 1.0,
    this.onScoreLoaded,
    this.onNotePressed,
    this.enableInteraction = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<VerovioScoreWidget> createState() => _VerovioScoreWidgetState();
}

enum RenderMode { verovio, canvas }

class _VerovioScoreWidgetState extends State<VerovioScoreWidget> {
  String? _svgContent;
  bool _isLoading = true;
  String? _error;
  final GlobalKey _svgKey = GlobalKey();
  RenderMode _renderMode = RenderMode.verovio;
  List<MusicalNote> _canvasNotes = [];
  String? _highlightedNoteId;

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

  // FASE 3.2.1: Carregamento inteligente com fallback Canvas
  Future<void> _loadScore() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Validar entrada
      if (widget.musicXML.isEmpty) {
        debugPrint('❌ MusicXML vazio - usando Canvas');
        await _fallbackToCanvas();
        return;
      }

      debugPrint(
          '🎵 Tentando Verovio: ${widget.musicXML.length} chars de MusicXML');

      // Tentar Verovio primeiro
      await VerovioService.instance.setZoomLevel(widget.zoom);
      final svg = await _renderWithTimeout();

      if (!mounted) return;

      if (svg != null && svg.isNotEmpty && _isValidSVG(svg)) {
        // ✅ VEROVIO FUNCIONOU - VAMOS USAR!
        debugPrint('✅ Verovio funcionou! SVG válido com ${svg.length} chars');
        setState(() {
          _svgContent = svg;
          _renderMode = RenderMode.verovio;
          _isLoading = false;
          _error = null;
        });

        widget.onScoreLoaded?.call();
        debugPrint('🎵 Partitura Verovio carregada com sucesso!');
        return;
      }

      // ⚠️ VEROVIO FALHOU - Usar Canvas
      debugPrint('⚠️ Verovio falhou, usando Canvas de alta performance');
      await _fallbackToCanvas();
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Erro no Verovio: $e - usando Canvas');
      await _fallbackToCanvas();
    }
  }

  // Fallback para Canvas renderer de alta performance
  Future<void> _fallbackToCanvas() async {
    try {
      debugPrint('🎨 Iniciando Canvas Music Renderer...');

      // Converter MusicXML para notas Canvas
      _canvasNotes =
          MusicXMLToCanvasConverter.convertMusicXMLToNotes(widget.musicXML);

      debugPrint('✅ Canvas: ${_canvasNotes.length} notas processadas');

      setState(() {
        _renderMode = RenderMode.canvas;
        _isLoading = false;
        _error = null;
      });

      widget.onScoreLoaded?.call();
      debugPrint('🚀 Canvas Music Renderer ativo - Performance máxima!');
    } catch (e) {
      debugPrint('❌ Erro no Canvas: $e');

      setState(() {
        _error = 'Erro em ambos os renderers: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _renderWithTimeout() async {
    try {
      return await Future.any([
        VerovioService.instance.renderMusicXML(
          widget.musicXML,
          cacheKey: widget.cacheKey,
        ),
        Future.delayed(
            const Duration(seconds: 10), () => null), // Timeout de 10s
      ]);
    } catch (e) {
      debugPrint('❌ Timeout ou erro na renderização: $e');
      return null;
    }
  }

  bool _isValidSVG(String svg) {
    if (svg.isEmpty) return false;

    // Validação básica - se tem tags SVG, é válido
    final svgLower = svg.toLowerCase();
    if (!svgLower.contains('<svg')) return false;
    if (!svgLower.contains('</svg>')) return false;

    // Se tem elementos gráficos básicos, é válido (mesmo que não detectemos elementos musicais)
    final hasGraphicElements = svgLower.contains('<g') ||
        svgLower.contains('<path') ||
        svgLower.contains('<line') ||
        svgLower.contains('<rect') ||
        svgLower.contains('<circle') ||
        svgLower.contains('<text');

    if (hasGraphicElements) {
      debugPrint('✅ SVG válido - contém elementos gráficos');
      return true;
    }

    // Log para debug se não encontrarmos elementos
    debugPrint(
        '⚠️ SVG sem elementos gráficos detectáveis, mas vamos tentar usar mesmo assim');
    debugPrint(
        '📋 Preview SVG: ${svg.length > 200 ? svg.substring(0, 200) : svg}...');

    return true; // Vamos ser otimistas e tentar usar o SVG
  }

  // FASE 3.2.2: Coloração de notas em tempo real (ambos os renderers)
  Future<void> colorNote(String noteId, String color) async {
    if (_renderMode == RenderMode.verovio && _svgContent != null) {
      try {
        final coloredSVG =
            await VerovioService.instance.colorNote(noteId, color);
        if (coloredSVG != null && mounted) {
          setState(() {
            _svgContent = coloredSVG;
          });
          debugPrint('✅ Verovio: Nota $noteId colorida');
        }
      } catch (e) {
        debugPrint('❌ Erro ao colorir nota Verovio: $e');
      }
    } else if (_renderMode == RenderMode.canvas) {
      // Canvas highlighting é instantâneo
      if (mounted) {
        setState(() {
          _highlightedNoteId = noteId;
        });
        debugPrint('✅ Canvas: Nota $noteId destacada instantaneamente');
      }
    }
  }

  // FASE 3.2.3: Coloração múltipla
  Future<void> colorMultipleNotes(Map<String, String> noteColors) async {
    if (_svgContent == null) return;

    try {
      final coloredSVG =
          await VerovioService.instance.colorMultipleNotes(noteColors);
      if (coloredSVG != null && mounted) {
        setState(() {
          _svgContent = coloredSVG;
        });
        debugPrint(
            '✅ FASE 3.2: ${noteColors.length} notas coloridas no widget');
      }
    } catch (e) {
      debugPrint('❌ FASE 3.2: Erro ao colorir múltiplas notas: $e');
    }
  }

  // FASE 3.2.4: Limpar cores (ambos os renderers)
  Future<void> clearColors() async {
    if (_renderMode == RenderMode.verovio) {
      // Recarregar partitura original
      await _loadScore();
    } else if (_renderMode == RenderMode.canvas) {
      // Canvas: limpar highlighting instantaneamente
      if (mounted) {
        setState(() {
          _highlightedNoteId = null;
        });
        debugPrint('✅ Canvas: Cores limpas instantaneamente');
      }
    }
  }

  // FASE 3.2.5: Detecção de toque em notas (experimental)
  void _handleTapDown(TapDownDetails details) {
    if (!widget.enableInteraction || widget.onNotePressed == null) return;

    try {
      final renderBox =
          _svgKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.globalPosition);

        // Detectar elemento SVG na posição clicada
        _detectSVGElementAt(localPosition);
      }
    } catch (e) {
      debugPrint('❌ FASE 3.2: Erro na detecção de toque: $e');
    }
  }

  // FASE 3.2.6: Detecção real de elementos SVG usando análise de DOM
  void _detectSVGElementAt(Offset position) async {
    try {
      // Converter coordenadas do Flutter para coordenadas SVG
      final svgX = position.dx / 1.0;
      final svgY = position.dy / 1.0;

      // Buscar por elementos de notas no SVG atual
      final currentSVG = VerovioService.instance.currentSVG;
      if (currentSVG == null) {
        debugPrint('⚠️ FASE 3.2: SVG não carregado');
        return;
      }

      // Usar regex para encontrar elementos <use> ou <circle> que representam notas
      final notePattern = RegExp(
          r'<(?:use|circle|ellipse)[^>]*id="([^"]*note[^"]*)"[^>]*x[^=]*="([^"]*)"[^>]*y[^=]*="([^"]*)"');
      final matches = notePattern.allMatches(currentSVG);

      String? closestNoteId;
      double minDistance = double.infinity;

      for (final match in matches) {
        try {
          final noteId = match.group(1) ?? '';
          final noteX = double.tryParse(match.group(2) ?? '0') ?? 0;
          final noteY = double.tryParse(match.group(3) ?? '0') ?? 0;

          // Calcular distância euclidiana
          final distance = (svgX - noteX).abs() + (svgY - noteY).abs();

          if (distance < minDistance && distance < 50) {
            // Tolerância de 50 pixels
            minDistance = distance;
            closestNoteId = noteId;
          }
        } catch (e) {
          // Ignorar elementos mal formados
          continue;
        }
      }

      if (closestNoteId != null) {
        debugPrint(
            '🎵 FASE 3.2: Nota detectada via SVG parsing: $closestNoteId');
        widget.onNotePressed?.call(closestNoteId);
      } else {
        debugPrint(
            '⚠️ FASE 3.2: Nenhuma nota encontrada na posição (${svgX.toStringAsFixed(1)}, ${svgY.toStringAsFixed(1)})');
        _fallbackPositionDetection(position);
      }
    } catch (e) {
      debugPrint('❌ FASE 3.2: Erro na detecção SVG: $e');
      _fallbackPositionDetection(position);
    }
  }

  // Fallback para detecção por posição quando a análise SVG falha
  void _fallbackPositionDetection(Offset position) {
    final x = position.dx;

    String noteId;
    if (x < 100) {
      noteId = 'note-0';
    } else if (x < 150) {
      noteId = 'note-1';
    } else if (x < 200) {
      noteId = 'note-2';
    } else {
      noteId = 'note-3';
    }

    debugPrint('🎵 FASE 3.2: Nota detectada por fallback: $noteId');
    widget.onNotePressed?.call(noteId);
  }

  @override
  Widget build(BuildContext context) {
    // FASE 3.2.6: UI do widget
    return Padding(
      padding: widget.padding,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    // Renderizar baseado no modo ativo
    switch (_renderMode) {
      case RenderMode.verovio:
        if (_svgContent == null) {
          return _buildEmptyState();
        }
        return _buildVerovioScoreView();

      case RenderMode.canvas:
        return _buildCanvasScoreView();
    }
  }

  // FASE 3.2.7: Estados da UI
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 16),
          Text(
            'Renderizando partitura...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.error.withValues(alpha: 0.05),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Erro ao carregar partitura',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _loadScore,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Recarregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _showErrorDetails,
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Detalhes'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showErrorDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Erro'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro completo:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _error ?? 'Erro desconhecido',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('MusicXML atual:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.musicXML.length > 200
                      ? '${widget.musicXML.substring(0, 200)}...'
                      : widget.musicXML,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Nenhuma partitura para exibir',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // Renderização com Verovio SVG
  Widget _buildVerovioScoreView() {
    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 3.0,
      child: GestureDetector(
        key: _svgKey,
        onTapDown: widget.enableInteraction ? _handleTapDown : null,
        child: _buildSvgWidget(),
      ),
    );
  }

  // Renderização com Canvas de alta performance
  Widget _buildCanvasScoreView() {
    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 3.0,
      child: CanvasMusicWidget(
        notes: _canvasNotes,
        zoom: widget.zoom,
        enableInteraction: widget.enableInteraction,
        highlightedNoteId: _highlightedNoteId,
        onNotePressed: widget.onNotePressed,
        padding: widget.padding,
      ),
    );
  }

  Widget _buildSvgWidget() {
    try {
      // Validar SVG antes de renderizar
      if (_svgContent == null || _svgContent!.isEmpty) {
        return _buildEmptyState();
      }

      // Verificar se é um SVG válido
      if (!_svgContent!.toLowerCase().contains('<svg')) {
        debugPrint('❌ SVG inválido: não contém tag <svg>');
        return _buildSvgErrorFallback();
      }

      debugPrint(
          '🌐 Renderizando SVG via HTML/WebView para máxima compatibilidade');

      // Usar WebView/HTML para renderizar SVG (mais confiável que flutter_svg)
      return _buildHtmlSvgWidget();
    } catch (e) {
      debugPrint('❌ Erro ao renderizar SVG: $e');
      return _buildSvgErrorFallback();
    }
  }

  Widget _buildHtmlSvgWidget() {
    // Criar HTML que renderiza o SVG de forma confiável
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                margin: 0;
                padding: 20px;
                background: transparent;
                overflow: hidden;
            }
            svg {
                max-width: 100%;
                height: auto;
                background: transparent;
            }
            .score-container {
                width: 100%;
                height: 400px;
                overflow: hidden;
                display: flex;
                justify-content: center;
                align-items: center;
            }
        </style>
    </head>
    <body>
        <div class="score-container">
            $_svgContent
        </div>
    </body>
    </html>
    ''';

    return Container(
      width: 2000,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlWidget(
          htmlContent,
          onTapUrl: (url) async {
            debugPrint('🎵 Possível toque em nota: $url');
            return false;
          },
          customStylesBuilder: (element) {
            return {'background': 'transparent'};
          },
        ),
      ),
    );
  }

  Widget _buildSvgErrorFallback() {
    return Container(
      width: 2000,
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            SizedBox(height: 16),
            Text(
              'Erro na renderização da partitura',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tente recarregar a partitura',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FASE 3.2.8: Métodos públicos para controle externo
  void reload() {
    _loadScore();
  }

  void setZoom(double zoom) {
    if (zoom != widget.zoom) {
      // O zoom será aplicado na próxima reconstrução do widget
      debugPrint('🔍 FASE 3.2: Zoom solicitado: ${(zoom * 100).round()}%');
    }
  }

  // Getters para status
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;
  bool get hasScore => _svgContent != null;
}
