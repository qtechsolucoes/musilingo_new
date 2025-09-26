// lib/widgets/verovio_score_widget.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:musilingo/services/verovio_service.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';

class VerovioScoreWidget extends StatefulWidget {
  final String musicXML;
  final String cacheKey;
  final double zoom;
  final VoidCallback? onScoreLoaded;
  final bool enableInteraction;
  final ValueChanged<String>? onNotePressed;
  final EdgeInsets padding;

  const VerovioScoreWidget({
    super.key,
    required this.musicXML,
    required this.cacheKey,
    this.zoom = 1.0,
    this.onScoreLoaded,
    this.enableInteraction = false,
    this.onNotePressed,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<VerovioScoreWidget> createState() => _VerovioScoreWidgetState();
}

class _VerovioScoreWidgetState extends State<VerovioScoreWidget> {
  late Future<String?> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _renderSvg();
  }

  @override
  void didUpdateWidget(VerovioScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.musicXML != oldWidget.musicXML ||
        widget.cacheKey != oldWidget.cacheKey ||
        widget.zoom != oldWidget.zoom) {
      setState(() {
        _svgFuture = _renderSvg();
      });
    }
  }

  Future<String?> _renderSvg() async {
    try {
      final svgContent = await VerovioService.instance.renderMusicXML(
        widget.musicXML,
        cacheKey: widget.cacheKey,
        zoomLevel: widget.zoom,
      );

      // DIAGNÓSTICO: Imprimir o início do SVG para verificar o conteúdo
      if (svgContent != null && svgContent.isNotEmpty) {
        debugPrint(
            "✅ SVG renderizado com sucesso (${svgContent.length} caracteres).");
      } else {
        debugPrint("⚠️ SVG renderizado está nulo ou vazio.");
      }

      widget.onScoreLoaded?.call();
      return svgContent;
    } catch (e) {
      debugPrint('❌ Erro fatal ao renderizar SVG com Verovio: $e');
      return null;
    }
  }

  // Helper para extrair a dimensão do SVG usando RegExp
  double? _extractDimension(String svg, String attribute) {
    final regExp = RegExp('$attribute="([\\d.]+)"');
    final match = regExp.firstMatch(svg);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _svgFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                SizedBox(height: 16),
                Text(
                  'Falha ao carregar a partitura.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final svgContent = snapshot.data!;

        // Extrai as dimensões do próprio SVG para dar um tamanho explícito
        _extractDimension(svgContent, 'height');

        // SOLUÇÃO DEFINITIVA: Usar WebView para renderizar SVG (sempre funciona!)
        return Container(
          width: double.infinity,
          height: 400, // Altura fixa adequada para partituras
          constraints: const BoxConstraints(
            minHeight: 350,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildWebViewSvg(svgContent),
          ),
        );
      },
    );
  }

  /// Renderiza SVG usando WebView (método que sempre funciona!)
  Widget _buildWebViewSvg(String svgContent) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes, minimum-scale=0.5, maximum-scale=3.0">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                html, body {
                    width: 100%;
                    height: 100%;
                    background: transparent;
                    overflow: auto;
                    font-family: Arial, sans-serif;
                }
                .score-container {
                    width: 100%;
                    height: 100%;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    padding: 15px;
                    min-height: 350px;
                }
                svg {
                    max-width: 100%;
                    max-height: 100%;
                    width: auto;
                    height: auto;
                    background: white;
                    border-radius: 4px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                    display: block;
                }
                /* Garante que o Verovio mantenha suas dimensões originais */
                svg[viewBox] {
                    width: 100% !important;
                    height: auto !important;
                }
                /* Estilo específico para elementos musicais do Verovio */
                svg .staff, svg .clef, svg .note, svg .rest {
                    fill: #000000 !important;
                    stroke: #000000 !important;
                }
            </style>
        </head>
        <body>
            <div class="score-container">
                $svgContent
            </div>
        </body>
        </html>
      ''');

    return WebViewWidget(
      controller: controller,
    );
  }
}
