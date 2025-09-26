// lib/app/presentation/widgets/score_viewer_widget.dart - MIGRADO PARA VEROVIO

import 'package:flutter/material.dart';
import '../../../widgets/verovio_score_widget.dart';
import '../../../services/verovio_service.dart';

class ScoreViewerWidget extends StatefulWidget {
  final String musicXML;
  final double? height;
  final Function(String noteId)? onNotePressed;

  const ScoreViewerWidget({
    super.key,
    required this.musicXML,
    this.height = 300.0,
    this.onNotePressed,
  });

  @override
  ScoreViewerWidgetState createState() => ScoreViewerWidgetState();
}

class ScoreViewerWidgetState extends State<ScoreViewerWidget> {
  final GlobalKey _scoreKey = GlobalKey();

  // --- MÉTODOS PÚBLICOS MIGRADOS PARA VEROVIO ---

  /// Colore uma nota específica na partitura usando Verovio
  Future<void> colorNote(int noteIndex, String colorHex) async {
    try {
      await VerovioService.instance.colorNote('note-$noteIndex', colorHex);
    } catch (e) {
      debugPrint('❌ ScoreViewerWidget: Erro ao colorir nota: $e');
    }
  }

  /// Remove a cor de todas as notas usando Verovio
  Future<void> clearAllNoteColors() async {
    try {
      await VerovioService.instance.clearAllColors();
    } catch (e) {
      debugPrint('❌ ScoreViewerWidget: Erro ao limpar cores: $e');
    }
  }

  /// Colore uma letra específica (simulado - Verovio não tem API específica para letras)
  Future<void> colorLyric(int lyricIndex, String colorHex) async {
    try {
      // Como Verovio não tem API específica para letras, colorimos a nota associada
      await VerovioService.instance.colorNote('lyric-$lyricIndex', colorHex);
    } catch (e) {
      debugPrint('❌ ScoreViewerWidget: Erro ao colorir letra: $e');
    }
  }

  /// Aplica feedback visual completo
  Future<void> applyNoteFeedback(int noteIndex, String noteColor, String lyricColor) async {
    try {
      await colorNote(noteIndex, noteColor);
      // Se lyricColor for diferente de noteColor, aplicar também
      if (lyricColor != noteColor) {
        await colorLyric(noteIndex, lyricColor);
      }
    } catch (e) {
      debugPrint('❌ ScoreViewerWidget: Erro ao aplicar feedback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: VerovioScoreWidget(
        key: _scoreKey,
        musicXML: widget.musicXML,
        cacheKey: 'score_viewer_${widget.musicXML.hashCode}',
        onScoreLoaded: () => debugPrint('✅ ScoreViewerWidget: Partitura carregada com Verovio'),
        enableInteraction: widget.onNotePressed != null,
        onNotePressed: widget.onNotePressed,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
