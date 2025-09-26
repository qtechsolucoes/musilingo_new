// Canvas Music Widget - Widget de alta performance para partituras
import 'package:flutter/material.dart';
import '../services/canvas_music_renderer.dart';

/// Widget customizado que renderiza partituras usando Canvas
class CanvasMusicWidget extends StatefulWidget {
  final List<MusicalNote> notes;
  final double zoom;
  final Function(String noteId)? onNotePressed;
  final bool enableInteraction;
  final String? highlightedNoteId;
  final EdgeInsets padding;

  const CanvasMusicWidget({
    super.key,
    required this.notes,
    this.zoom = 1.0,
    this.onNotePressed,
    this.enableInteraction = false,
    this.highlightedNoteId,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<CanvasMusicWidget> createState() => _CanvasMusicWidgetState();
}

class _CanvasMusicWidgetState extends State<CanvasMusicWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: GestureDetector(
        onTapDown: widget.enableInteraction ? _handleTapDown : null,
        child: CustomPaint(
          painter: _MusicScorePainter(
            notes: _getNotesWithHighlight(),
            zoom: widget.zoom,
          ),
          size: Size(2000 * widget.zoom, 400 * widget.zoom),
        ),
      ),
    );
  }

  List<MusicalNote> _getNotesWithHighlight() {
    return widget.notes.map((note) {
      return note.copyWith(
        isHighlighted: note.noteId == widget.highlightedNoteId,
      );
    }).toList();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onNotePressed == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = details.localPosition;
    final canvasSize = renderBox.size;

    final noteId = CanvasMusicRenderer.detectNoteAt(
      localPosition,
      widget.notes,
      canvasSize,
      const MusicRenderConfig(),
      widget.zoom,
    );

    if (noteId != null) {
      widget.onNotePressed!(noteId);
      debugPrint('🎵 Nota Canvas detectada: $noteId');
    }
  }
}

/// Painter customizado para renderizar a partitura
class _MusicScorePainter extends CustomPainter {
  final List<MusicalNote> notes;
  final double zoom;

  _MusicScorePainter({
    required this.notes,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo transparente
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.transparent,
    );

    // Renderizar partitura
    CanvasMusicRenderer.renderMusicScore(
      canvas: canvas,
      notes: notes,
      size: size,
      zoom: zoom,
    );

    // Adicionar título/indicador no canto
    _drawTitle(canvas, size);
  }

  void _drawTitle(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🚀 CANVAS MUSIC RENDERER - MÁXIMA PERFORMANCE',
        style: TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      const Offset(20, 20),
    );

    // Desenhar indicador de status
    final statusPainter = TextPainter(
      text: const TextSpan(
        text: '✅ SOLFEJO FUNCIONANDO COM CANVAS NATIVO',
        style: TextStyle(
          color: Color(0xFFFFDD00),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    statusPainter.layout();
    statusPainter.paint(
      canvas,
      const Offset(20, 40),
    );
  }

  @override
  bool shouldRepaint(covariant _MusicScorePainter oldDelegate) {
    return oldDelegate.notes != notes || oldDelegate.zoom != zoom;
  }
}