// Canvas Music Renderer - Sistema de renderização musical de alta performance
import 'package:flutter/material.dart';

/// Estrutura de dados para uma nota musical
class MusicalNote {
  final String pitch; // C4, D4, E4, etc.
  final String lyric; // Dó, Ré, Mi, etc.
  final double duration; // 1.0 = semibreve, 0.5 = mínima, 0.25 = semínima
  final String noteId; // note-0, note-1, etc.
  final bool isHighlighted; // Para destacar nota atual

  const MusicalNote({
    required this.pitch,
    required this.lyric,
    required this.duration,
    required this.noteId,
    this.isHighlighted = false,
  });

  MusicalNote copyWith({bool? isHighlighted}) {
    return MusicalNote(
      pitch: pitch,
      lyric: lyric,
      duration: duration,
      noteId: noteId,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }
}

/// Configurações de renderização profissional
class MusicRenderConfig {
  final double staffLineSpacing;
  final double noteSize;
  final double staffWidth;
  final double staffHeight;
  final Color staffColor;
  final Color noteColor;
  final Color highlightColor;
  final Color lyricColor;
  final double fontSize;
  final double noteSpacing;
  final double staffLineThickness;
  final double stemThickness;
  final bool enableShadows;
  final bool enableAntiAliasing;

  const MusicRenderConfig({
    this.staffLineSpacing = 12.0,
    this.noteSize = 12.0,
    this.staffWidth = 2200.0,
    this.staffHeight = 120.0,
    this.staffColor = const Color(0xFFE8E8E8), // Cinza claro profissional
    this.noteColor = const Color(0xFF2C2C2C), // Preto profissional
    this.highlightColor = const Color(0xFFFF6B35), // Laranja vibrante
    this.lyricColor = const Color(0xFF4A4A4A), // Cinza escuro para texto
    this.fontSize = 14.0,
    this.noteSpacing = 120.0,
    this.staffLineThickness = 1.2,
    this.stemThickness = 2.0,
    this.enableShadows = true,
    this.enableAntiAliasing = true,
  });
}

/// Renderer principal para notação musical
class CanvasMusicRenderer {
  static const Map<String, double> _pitchPositions = {
    'C4': 72.0, // Dó - linha suplementar inferior
    'D4': 66.0, // Ré - abaixo da pauta
    'E4': 60.0, // Mi - 4ª linha
    'F4': 54.0, // Fá - 3º espaço
    'G4': 48.0, // Sol - 3ª linha
    'A4': 42.0, // Lá - 2º espaço
    'B4': 36.0, // Si - 2ª linha
    'C5': 30.0, // Dó - 1º espaço
    'D5': 24.0, // Ré - 1ª linha
    'E5': 18.0, // Mi - acima da pauta
    'F5': 12.0, // Fá - linha suplementar superior
  };

  /// Renderiza uma sequência de notas musicais com qualidade profissional
  static void renderMusicScore({
    required Canvas canvas,
    required List<MusicalNote> notes,
    required Size size,
    MusicRenderConfig config = const MusicRenderConfig(),
    double zoom = 1.0,
  }) {
    final scaledConfig = _scaleConfig(config, zoom);

    // Configurar anti-aliasing para qualidade superior
    if (scaledConfig.enableAntiAliasing) {
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    // Calcular posição central otimizada
    final startX = (size.width - scaledConfig.staffWidth) / 2;
    final startY = (size.height - scaledConfig.staffHeight) / 2;

    // Desenhar fundo sutil para destaque
    _drawBackground(canvas, size, scaledConfig);

    // Renderizar pentagrama com alta qualidade
    _drawProfessionalStaff(canvas, startX, startY, scaledConfig);

    // Renderizar clave de sol profissional
    _drawProfessionalTrebleClef(canvas, startX + 30, startY, scaledConfig);

    // Renderizar fórmula de compasso
    _drawTimeSignature(canvas, startX + 90, startY, scaledConfig);

    // Renderizar notas com qualidade superior
    _drawProfessionalNotes(canvas, notes, startX + 140, startY, scaledConfig);

    // Renderizar barras de compasso elegantes
    _drawProfessionalMeasureLines(canvas, startX, startY, scaledConfig);

    // Adicionar bordas elegantes
    _drawScoreBorders(canvas, startX, startY, scaledConfig);
  }

  static MusicRenderConfig _scaleConfig(MusicRenderConfig config, double zoom) {
    return MusicRenderConfig(
      staffLineSpacing: config.staffLineSpacing * zoom,
      noteSize: config.noteSize * zoom,
      staffWidth: config.staffWidth * zoom,
      staffHeight: config.staffHeight * zoom,
      staffColor: config.staffColor,
      noteColor: config.noteColor,
      highlightColor: config.highlightColor,
      lyricColor: config.lyricColor,
      fontSize: config.fontSize * zoom,
      noteSpacing: config.noteSpacing * zoom,
    );
  }

  // ============ MÉTODOS PROFISSIONAIS DE RENDERIZAÇÃO ============

  /// Desenha fundo sutil para melhor contraste
  static void _drawBackground(
      Canvas canvas, Size size, MusicRenderConfig config) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
  }

  /// Desenha pentagrama profissional com anti-aliasing
  static void _drawProfessionalStaff(
      Canvas canvas, double x, double y, MusicRenderConfig config) {
    final paint = Paint()
      ..color = config.staffColor
      ..strokeWidth = config.staffLineThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = config.enableAntiAliasing;

    // Desenhar 5 linhas do pentagrama com qualidade superior
    for (int i = 0; i < 5; i++) {
      final lineY = y + (i * config.staffLineSpacing);

      // Adicionar sombra sutil se habilitado
      if (config.enableShadows) {
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..strokeWidth = config.staffLineThickness + 0.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(x + 1, lineY + 0.5),
          Offset(x + config.staffWidth + 1, lineY + 0.5),
          shadowPaint,
        );
      }

      // Linha principal
      canvas.drawLine(
        Offset(x, lineY),
        Offset(x + config.staffWidth, lineY),
        paint,
      );
    }
  }

  /// Desenha clave de sol com design profissional do Verovio
  static void _drawProfessionalTrebleClef(
      Canvas canvas, double x, double y, MusicRenderConfig config) {
    final paint = Paint()
      ..color = config.noteColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = config.enableAntiAliasing;

    // Sombra da clave se habilitado
    if (config.enableShadows) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      _drawTrebleClefPath(canvas, x + 1, y + 1, shadowPaint, config);
    }

    // Clave principal
    _drawTrebleClefPath(canvas, x, y, paint, config);
  }

  static void _drawTrebleClefPath(Canvas canvas, double x, double y,
      Paint paint, MusicRenderConfig config) {
    final path = Path();

    // Desenhar clave de sol estilo Verovio (mais precisa)
    path.moveTo(x + 8, y + 72);

    // Curva principal ascendente
    path.cubicTo(x + 6, y + 58, x + 6, y + 45, x + 8, y + 35);
    path.cubicTo(x + 10, y + 25, x + 15, y + 18, x + 22, y + 18);

    // Cabeça superior da clave
    path.cubicTo(x + 28, y + 18, x + 32, y + 22, x + 32, y + 28);
    path.cubicTo(x + 32, y + 34, x + 28, y + 38, x + 22, y + 38);
    path.cubicTo(x + 18, y + 38, x + 15, y + 35, x + 15, y + 31);
    path.cubicTo(x + 15, y + 28, x + 17, y + 26, x + 20, y + 26);
    path.cubicTo(x + 22, y + 26, x + 24, y + 27, x + 24, y + 29);

    // Espiral central
    path.cubicTo(x + 24, y + 32, x + 22, y + 35, x + 18, y + 38);
    path.cubicTo(x + 15, y + 42, x + 12, y + 48, x + 12, y + 55);

    // Curva inferior
    path.cubicTo(x + 12, y + 65, x + 15, y + 72, x + 20, y + 76);
    path.cubicTo(x + 14, y + 78, x + 8, y + 75, x + 8, y + 72);

    path.close();
    canvas.drawPath(path, paint);

    // Ponto característico da clave
    canvas.drawCircle(Offset(x + 22, y + 30), 1.5, paint);
  }

  /// Desenha fórmula de compasso (4/4)
  static void _drawTimeSignature(
      Canvas canvas, double x, double y, MusicRenderConfig config) {
    final textStyle = TextStyle(
      color: config.noteColor,
      fontSize: config.fontSize * 1.8,
      fontWeight: FontWeight.bold,
      fontFamily: 'serif',
    );

    // Numerador (4)
    final numeratorPainter = TextPainter(
      text: TextSpan(text: '4', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    numeratorPainter.layout();
    numeratorPainter.paint(canvas, Offset(x, y + config.staffLineSpacing));

    // Denominador (4)
    final denominatorPainter = TextPainter(
      text: TextSpan(text: '4', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    denominatorPainter.layout();
    denominatorPainter.paint(
        canvas, Offset(x, y + config.staffLineSpacing * 2.5));
  }

  /// Desenha notas musicais com qualidade profissional
  static void _drawProfessionalNotes(Canvas canvas, List<MusicalNote> notes,
      double startX, double startY, MusicRenderConfig config) {
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final x = startX + (i * config.noteSpacing);

      _drawProfessionalSingleNote(canvas, note, x, startY, config);
      _drawProfessionalLyric(
          canvas, note.lyric, x, startY + config.staffHeight + 25, config);
    }
  }

  /// Desenha uma única nota com qualidade profissional
  static void _drawProfessionalSingleNote(Canvas canvas, MusicalNote note,
      double x, double startY, MusicRenderConfig config) {
    final notePosition = _pitchPositions[note.pitch] ?? 48.0;
    final noteY = startY + notePosition;

    // Cor da nota (destacada ou normal)
    final noteColor =
        note.isHighlighted ? config.highlightColor : config.noteColor;

    final notePaint = Paint()
      ..color = noteColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = config.enableAntiAliasing;

    final stemPaint = Paint()
      ..color = noteColor
      ..strokeWidth = config.stemThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = config.enableAntiAliasing;

    // Desenhar sombra da nota se habilitado
    if (config.enableShadows) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final shadowNoteHead = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + 1, noteY + 1),
          width: config.noteSize * 2.2,
          height: config.noteSize * 1.4,
        ),
        Radius.circular(config.noteSize * 0.8),
      );
      canvas.drawRRect(shadowNoteHead, shadowPaint);
    }

    // Desenhar linha suplementar se necessário
    _drawProfessionalSupplementaryLines(canvas, note.pitch, x, startY, config);

    // Desenhar cabeça da nota profissional (mais elegante)
    final noteHead = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, noteY),
        width: config.noteSize * 2.0,
        height: config.noteSize * 1.3,
      ),
      Radius.circular(config.noteSize * 0.7),
    );
    canvas.drawRRect(noteHead, notePaint);

    // Desenhar haste da nota com melhor posicionamento
    final stemHeight = config.staffLineSpacing * 3.5;
    final stemDirection =
        noteY > startY + (config.staffLineSpacing * 2) ? -1 : 1;

    final stemX = x +
        (stemDirection > 0 ? config.noteSize * 0.9 : -config.noteSize * 0.9);
    final stemStartY = noteY;
    final stemEndY = noteY + (stemHeight * stemDirection);

    canvas.drawLine(
      Offset(stemX, stemStartY),
      Offset(stemX, stemEndY),
      stemPaint,
    );

    // Desenhar bandeira profissional se necessário
    if (note.duration <= 0.125) {
      _drawProfessionalNoteFlag(
          canvas, stemX, stemEndY, stemDirection, config, noteColor);
    }

    // Adicionar brilho sutil se nota estiver destacada
    if (note.isHighlighted) {
      _drawNoteHighlight(canvas, x, noteY, config);
    }
  }

  /// Desenha linhas suplementares profissionais
  static void _drawProfessionalSupplementaryLines(Canvas canvas, String pitch,
      double x, double startY, MusicRenderConfig config) {
    final paint = Paint()
      ..color = config.staffColor
      ..strokeWidth = config.staffLineThickness * 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = config.enableAntiAliasing;

    // Linha suplementar inferior para C4
    if (pitch == 'C4') {
      final lineY = startY + (5 * config.staffLineSpacing);
      canvas.drawLine(
        Offset(x - config.noteSize * 1.5, lineY),
        Offset(x + config.noteSize * 1.5, lineY),
        paint,
      );
    }

    // Linha suplementar superior para F5 e acima
    if (pitch == 'F5' || pitch == 'G5' || pitch == 'A5') {
      final lineY = startY - config.staffLineSpacing;
      canvas.drawLine(
        Offset(x - config.noteSize * 1.5, lineY),
        Offset(x + config.noteSize * 1.5, lineY),
        paint,
      );
    }
  }

  /// Desenha bandeira profissional da nota
  static void _drawProfessionalNoteFlag(Canvas canvas, double x, double y,
      int direction, MusicRenderConfig config, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = config.enableAntiAliasing;

    final path = Path();

    if (direction > 0) {
      // Bandeira elegante para baixo
      path.moveTo(x, y);
      path.cubicTo(x + 18, y - 8, x + 16, y + 2, x + 14, y + 12);
      path.cubicTo(x + 12, y + 8, x + 8, y + 4, x, y + 6);
    } else {
      // Bandeira elegante para cima
      path.moveTo(x, y);
      path.cubicTo(x - 18, y + 8, x - 16, y - 2, x - 14, y - 12);
      path.cubicTo(x - 12, y - 8, x - 8, y - 4, x, y - 6);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  /// Desenha efeito de destaque para nota selecionada
  static void _drawNoteHighlight(
      Canvas canvas, double x, double y, MusicRenderConfig config) {
    final highlightPaint = Paint()
      ..color = config.highlightColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(x, y),
      config.noteSize * 2.5,
      highlightPaint,
    );

    // Adicionar pulso luminoso
    final glowPaint = Paint()
      ..color = config.highlightColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(x, y),
      config.noteSize * 3.0,
      glowPaint,
    );
  }

  /// Desenha letra do solfejo com tipografia profissional
  static void _drawProfessionalLyric(Canvas canvas, String lyric, double x,
      double y, MusicRenderConfig config) {
    // Sombra do texto se habilitado
    if (config.enableShadows) {
      final shadowTextPainter = TextPainter(
        text: TextSpan(
          text: lyric,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.25),
            fontSize: config.fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      shadowTextPainter.layout();
      shadowTextPainter.paint(
        canvas,
        Offset(x - shadowTextPainter.width / 2 + 0.5, y + 0.5),
      );
    }

    // Texto principal
    final textPainter = TextPainter(
      text: TextSpan(
        text: lyric,
        style: TextStyle(
          color: config.lyricColor,
          fontSize: config.fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: 'Arial',
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y),
    );
  }

  /// Desenha barras de compasso profissionais
  static void _drawProfessionalMeasureLines(
      Canvas canvas, double x, double y, MusicRenderConfig config) {
    final thinPaint = Paint()
      ..color = config.staffColor
      ..strokeWidth = config.staffLineThickness * 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = config.enableAntiAliasing;

    final thickPaint = Paint()
      ..color = config.staffColor
      ..strokeWidth = config.staffLineThickness * 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = config.enableAntiAliasing;

    final staffTop = y - 8;
    final staffBottom = y + (4 * config.staffLineSpacing) + 8;

    // Barra inicial (simples)
    canvas.drawLine(
      Offset(x + 120, staffTop),
      Offset(x + 120, staffBottom),
      thinPaint,
    );

    // Barra final dupla (estilo profissional)
    final endX = x + config.staffWidth - 30;

    // Primeira linha (fina)
    canvas.drawLine(
      Offset(endX - 8, staffTop),
      Offset(endX - 8, staffBottom),
      thinPaint,
    );

    // Segunda linha (grossa)
    canvas.drawLine(
      Offset(endX, staffTop),
      Offset(endX, staffBottom),
      thickPaint,
    );

    // Adicionar sombras sutis se habilitado
    if (config.enableShadows) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..strokeWidth = config.staffLineThickness * 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Sombra da barra inicial
      canvas.drawLine(
        Offset(x + 121, staffTop + 1),
        Offset(x + 121, staffBottom + 1),
        shadowPaint,
      );

      // Sombras das barras finais
      canvas.drawLine(
        Offset(endX - 7, staffTop + 1),
        Offset(endX - 7, staffBottom + 1),
        shadowPaint,
      );
      canvas.drawLine(
        Offset(endX + 1, staffTop + 1),
        Offset(endX + 1, staffBottom + 1),
        shadowPaint,
      );
    }
  }

  /// Desenha bordas elegantes ao redor da partitura
  static void _drawScoreBorders(
      Canvas canvas, double x, double y, MusicRenderConfig config) {
    final borderPaint = Paint()
      ..color = config.staffColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = config.enableAntiAliasing;

    const cornerRadius = 8.0;
    const padding = 15.0;

    // Calcular dimensões da borda
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x - padding,
        y - padding - 10,
        config.staffWidth + (padding * 2),
        config.staffHeight + (padding * 2) + 60,
      ),
      const Radius.circular(cornerRadius),
    );

    // Desenhar sombra da borda se habilitado
    if (config.enableShadows) {
      final shadowBorderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final shadowBorderRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - padding + 2,
          y - padding - 8,
          config.staffWidth + (padding * 2),
          config.staffHeight + (padding * 2) + 60,
        ),
        const Radius.circular(cornerRadius),
      );

      canvas.drawRRect(shadowBorderRect, shadowBorderPaint);
    }

    // Desenhar borda principal
    canvas.drawRRect(borderRect, borderPaint);

    // Adicionar detalhes decorativos nos cantos
    _drawCornerDecorations(canvas, borderRect, config);
  }

  /// Desenha decorações elegantes nos cantos da partitura
  static void _drawCornerDecorations(
      Canvas canvas, RRect borderRect, MusicRenderConfig config) {
    final decorationPaint = Paint()
      ..color = config.staffColor.withValues(alpha: 0.2)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = config.enableAntiAliasing;

    final rect = borderRect.outerRect;
    const cornerSize = 6.0;

    // Decoração canto superior esquerdo
    canvas.drawLine(
      Offset(rect.left + 8, rect.top + 8),
      Offset(rect.left + 8 + cornerSize, rect.top + 8),
      decorationPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 8, rect.top + 8),
      Offset(rect.left + 8, rect.top + 8 + cornerSize),
      decorationPaint,
    );

    // Decoração canto superior direito
    canvas.drawLine(
      Offset(rect.right - 8, rect.top + 8),
      Offset(rect.right - 8 - cornerSize, rect.top + 8),
      decorationPaint,
    );
    canvas.drawLine(
      Offset(rect.right - 8, rect.top + 8),
      Offset(rect.right - 8, rect.top + 8 + cornerSize),
      decorationPaint,
    );

    // Decoração canto inferior esquerdo
    canvas.drawLine(
      Offset(rect.left + 8, rect.bottom - 8),
      Offset(rect.left + 8 + cornerSize, rect.bottom - 8),
      decorationPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 8, rect.bottom - 8),
      Offset(rect.left + 8, rect.bottom - 8 - cornerSize),
      decorationPaint,
    );

    // Decoração canto inferior direito
    canvas.drawLine(
      Offset(rect.right - 8, rect.bottom - 8),
      Offset(rect.right - 8 - cornerSize, rect.bottom - 8),
      decorationPaint,
    );
    canvas.drawLine(
      Offset(rect.right - 8, rect.bottom - 8),
      Offset(rect.right - 8, rect.bottom - 8 - cornerSize),
      decorationPaint,
    );
  }

  /// Detecta qual nota foi tocada baseada na posição
  static String? detectNoteAt(Offset position, List<MusicalNote> notes,
      Size canvasSize, MusicRenderConfig config, double zoom) {
    final scaledConfig = _scaleConfig(config, zoom);
    final startX = (canvasSize.width - scaledConfig.staffWidth) / 2 + 140;
    final tolerance = scaledConfig.noteSpacing / 2;

    for (int i = 0; i < notes.length; i++) {
      final noteX = startX + (i * scaledConfig.noteSpacing);

      if ((position.dx - noteX).abs() < tolerance) {
        return notes[i].noteId;
      }
    }

    return null;
  }
}
