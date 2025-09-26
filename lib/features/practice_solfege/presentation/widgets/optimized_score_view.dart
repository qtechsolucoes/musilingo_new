// lib/features/practice_solfege/presentation/widgets/optimized_score_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/features/practice_solfege/providers/solfege_exercise_provider.dart';
import 'package:musilingo/app/presentation/widgets/score_viewer_widget.dart';

/// Widget otimizado que previne recarregamentos desnecessários da partitura
class OptimizedScoreView extends StatefulWidget {
  final SolfegeExerciseState controller;
  final Function(SolfegeExerciseState) onScoreLoad;

  const OptimizedScoreView({
    super.key,
    required this.controller,
    required this.onScoreLoad,
  });

  @override
  State<OptimizedScoreView> createState() => _OptimizedScoreViewState();
}

class _OptimizedScoreViewState extends State<OptimizedScoreView> {
  String? _lastLoadedXml;
  final GlobalKey<ScoreViewerWidgetState> _scoreViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadScoreIfNeeded();
  }

  @override
  void didUpdateWidget(OptimizedScoreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadScoreIfNeeded();
  }

  /// Só recarrega se o XML realmente mudou
  void _loadScoreIfNeeded() {
    final currentXml = widget.controller.musicXml;
    if (currentXml != _lastLoadedXml) {
      widget.onScoreLoad(widget.controller);
      _lastLoadedXml = currentXml;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.transparent, // Fundo transparente
        borderRadius: BorderRadius.circular(12),
        // Removido BoxShadow para evitar fundo branco
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ScoreViewerWidget(
          key: _scoreViewerKey,
          musicXML: widget.controller.musicXml,
        ),
      ),
    );
  }
}

/// Widget otimizado para controles do exercício
class OptimizedExerciseControlsWidget extends ConsumerWidget {
  final SolfegeExerciseState controller;

  const OptimizedExerciseControlsWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildControls(ref);
  }

  Widget _buildControls(WidgetRef ref) {
    switch (controller.state) {
      case SolfegeState.idle:
        return _IdleControls(controller: controller, ref: ref);
      case SolfegeState.countdown:
        return _CountdownControls(controller: controller);
      case SolfegeState.listening:
        return _ListeningControls(controller: controller, ref: ref);
      case SolfegeState.analyzing:
        return const _AnalyzingControls();
      case SolfegeState.finished:
        return _FinishedControls(controller: controller, ref: ref);
    }
  }
}

/// Controles quando o exercício está idle
class _IdleControls extends StatelessWidget {
  final SolfegeExerciseState controller;
  final WidgetRef ref;

  const _IdleControls({required this.controller, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botões de configuração
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToggleButton(
              'Piano',
              controller.playWithPiano,
              () => ref
                  .read(solfegeExerciseProvider.notifier)
                  .togglePianoAccompaniment(),
            ),
            _buildToggleButton(
              'Nomes',
              controller.showNoteNames,
              () =>
                  ref.read(solfegeExerciseProvider.notifier).toggleNoteNames(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Botões de ação
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(solfegeExerciseProvider.notifier).playPreview(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Preview'),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(solfegeExerciseProvider.notifier).startCountdown(),
              icon: const Icon(Icons.mic),
              label: const Text('Iniciar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool value, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(value ? Icons.check_box : Icons.check_box_outline_blank),
      label: Text(label),
    );
  }
}

/// Controles durante countdown
class _CountdownControls extends StatelessWidget {
  final SolfegeExerciseState controller;

  const _CountdownControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Prepare-se!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.red,
          child: Text(
            '${controller.countdownValue}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Controles durante listening - limpo e minimalista
class _ListeningControls extends StatelessWidget {
  final SolfegeExerciseState controller;
  final WidgetRef ref;

  const _ListeningControls({required this.controller, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withAlpha(150), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone de gravação pulsante
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 800),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withAlpha(100),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
            onEnd: () {
              // Reinicia a animação
            },
          ),
          const SizedBox(height: 12),

          const Text(
            '🎵 Cantando... 🎵',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Progress indicator mais elegante
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.grey.shade600,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (controller.currentNoteIndex + 1) /
                  controller.exercise.noteSequence.length,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão de parar elegante
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(solfegeExerciseProvider.notifier).finishExercise(),
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('Finalizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Controles durante análise
class _AnalyzingControls extends StatelessWidget {
  const _AnalyzingControls();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Analisando performance...'),
      ],
    );
  }
}

/// Controles quando finalizado
class _FinishedControls extends StatelessWidget {
  final SolfegeExerciseState controller;
  final WidgetRef ref;

  const _FinishedControls({required this.controller, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Score display
        Text(
          'Pontuação: ${controller.pitchScore}%',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color:
                    controller.pitchScore >= 70 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        // Detailed scores
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildScoreCard('Pitch', controller.pitchScore),
            _buildScoreCard('Duração', controller.durationScore),
          ],
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(solfegeExerciseProvider.notifier).reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Voltar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard(String label, int score) {
    return Column(
      children: [
        Text(
          '$score%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: score >= 70 ? Colors.green : Colors.orange,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
