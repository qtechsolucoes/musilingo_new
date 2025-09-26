// lib/app/presentation/widgets/score_fullscreen_modal.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/presentation/widgets/score_viewer_widget.dart';
import 'package:musilingo/app/services/unified_midi_service.dart';
import 'package:musilingo/app/services/orientation_service.dart';

class ScoreFullscreenModal extends StatefulWidget {
  final String musicXml;
  final List<Map<String, dynamic>> scoreNotes;

  // O serviço de MIDI agora é passado como parâmetro para garantir que usamos a mesma instância
  final UnifiedMidiService midiService;

  const ScoreFullscreenModal({
    super.key,
    required this.musicXml,
    required this.scoreNotes,
    required this.midiService,
  });

  @override
  State<ScoreFullscreenModal> createState() => _ScoreFullscreenModalState();
}

class _ScoreFullscreenModalState extends State<ScoreFullscreenModal> {
  // Chave para acessar o ScoreViewerWidget e chamar suas funções
  final GlobalKey<ScoreViewerWidgetState> _scoreViewerKey = GlobalKey();

  bool _isPlaying = false;
  int _currentNoteIndex = -1;

  @override
  void initState() {
    super.initState();
    // Usa o serviço centralizado para orientação de visualização de partitura
    OrientationService.instance.setScoreViewMode('score_fullscreen');
  }

  @override
  void dispose() {
    // Restaura orientação através do serviço centralizado
    OrientationService.instance.removeOrientation('score_fullscreen');
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      // Futuramente, podemos adicionar uma lógica para parar o MIDI aqui.
      // Por enquanto, apenas resetamos o estado visual.
      setState(() {
        _isPlaying = false;
        _currentNoteIndex = -1;
        _scoreViewerKey.currentState?.clearAllNoteColors();
      });
    } else {
      setState(() {
        _isPlaying = true;
      });

      widget.midiService.playNoteSequence(
        notes: widget.scoreNotes,
        tempo: 120, // Tempo padrão
        onNotePlayed: (noteIndex) {
          if (mounted) {
            // Limpa a cor da nota anterior e colore a atual
            if (_currentNoteIndex != -1) {
              _scoreViewerKey.currentState
                  ?.colorNote(_currentNoteIndex, '#FFFFFF'); // Cor padrão
            }
            _scoreViewerKey.currentState
                ?.colorNote(noteIndex, '#FFDD00'); // Cor amarela
            setState(() {
              _currentNoteIndex = noteIndex;
            });
          }
        },
        onPlaybackComplete: () {
          if (mounted) {
            // Limpa todas as cores e reseta o estado quando a música termina
            _scoreViewerKey.currentState?.clearAllNoteColors();
            setState(() {
              _isPlaying = false;
              _currentNoteIndex = -1;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Área da Partitura
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ScoreViewerWidget(
                    key: _scoreViewerKey, // Atribui a chave ao widget
                    musicXML: widget.musicXml,
                  ),
                ),
              ),

              // Barra de Controles Inferior
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botão Sair
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Sair'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Botão Play/Pause
                    ElevatedButton.icon(
                      onPressed: _togglePlayback,
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(_isPlaying ? 'A Tocar...' : 'Tocar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
