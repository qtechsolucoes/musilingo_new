// lib/features/practice_solfege/presentation/view/solfege_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/app/services/sfx_service.dart';
import 'package:musilingo/app/services/orientation_service.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/features/practice_solfege/providers/solfege_exercise_provider.dart';
import 'package:musilingo/widgets/verovio_score_widget.dart';
import 'package:musilingo/services/verovio_service.dart';
import 'package:provider/provider.dart' as provider;
import 'package:confetti/confetti.dart';

class SolfegeExerciseScreen extends ConsumerStatefulWidget {
  final SolfegeExercise exercise;

  const SolfegeExerciseScreen({super.key, required this.exercise});

  @override
  ConsumerState<SolfegeExerciseScreen> createState() =>
      _SolfegeExerciseScreenState();
}

class _SolfegeExerciseScreenState extends ConsumerState<SolfegeExerciseScreen> {
  bool _isLoading = true;
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();
  List<NoteResult> _detectedResults = [];

  @override
  void initState() {
    super.initState();
    OrientationService.instance.setMusicExerciseMode('solfege_exercise');

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(solfegeExerciseProvider.notifier)
            .initializeExercise(widget.exercise);
      }
    });

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    OrientationService.instance.removeOrientation('solfege_exercise');
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    // FASE 4.5: XML loading now handled by VerovioScoreWidget automatically

    ref.listen<SolfegeState>(solfegeExerciseProvider.select((s) => s.state),
        (prev, next) {
      if (prev != SolfegeState.finished && next == SolfegeState.finished) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final currentState = ref.read(solfegeExerciseProvider);
            // Acessar os resultados detalhados do provider (será implementado)
            _detectedResults = ref.read(solfegeExerciseProvider.notifier).getDetectedResults();
            _showExerciseResultModal(currentState);
          }
        });
      }
    });

    // FASE 4.5: Note highlighting now handled by VerovioService directly
    ref.listen<int>(solfegeExerciseProvider.select((s) => s.currentNoteIndex),
        (prev, next) async {
      if (ref.read(solfegeExerciseProvider).state == SolfegeState.listening &&
          next >= 0) {
        // Highlight current note using Verovio
        try {
          await VerovioService.instance.colorNote('note-$next', '#FFDD00');
        } catch (e) {
          debugPrint('❌ FASE 4.5: Erro ao destacar nota: $e');
        }
      }
    });

    if (_isLoading) {
      return const GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
      );
    }

    final exerciseState = ref.watch(solfegeExerciseProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(exerciseState),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(10),
                            minScale: 0.8,
                            maxScale: 2.5,
                            child: SizedBox(
                              // MIGRADO PARA VEROVIO - FASE 4.5
                              width: 2000,
                              height: 400,
                              child: exerciseState.musicXml.isNotEmpty
                                  ? VerovioScoreWidget(
                                      musicXML: exerciseState.musicXml,
                                      cacheKey: 'solfege_${exerciseState.exercise.id}',
                                      zoom: exerciseState.zoomLevel,
                                      onScoreLoaded: () => debugPrint('✅ FASE 4.5: Solfejo carregado com Verovio'),
                                      enableInteraction: true,
                                      onNotePressed: (noteId) => debugPrint('🎵 Nota pressionada: $noteId'),
                                      padding: const EdgeInsets.all(8),
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator()),
                            ),
                          ),
                        ),
                      ),
                      _buildStatusDisplay(exerciseState),
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          shouldLoop: false,
                          colors: const [
                            Colors.green,
                            Colors.blue,
                            Colors.pink,
                            Colors.orange,
                            Colors.purple
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 120, maxHeight: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: OptimizedExerciseControlsSimple(
                        state: exerciseState,
                        notifier: ref.read(solfegeExerciseProvider.notifier)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(SolfegeExerciseState exerciseState) {
    final userSession = context.read<UserSession>();
    return AppBar(
      title: Text(exerciseState.exercise.title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Row(children: [
          const Icon(Icons.favorite, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '${userSession.currentUser?.lives ?? 0}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 16),
        ]),
        Row(children: [
          const Icon(Icons.music_note, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            '${userSession.currentUser?.points ?? 0}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 16),
        ]),
      ],
    );
  }

  Widget _buildStatusDisplay(SolfegeExerciseState exerciseState) {
    // Código original mantido, com correção de estilo
    switch (exerciseState.state) {
      case SolfegeState.countdown:
        return Center(
          child: Text(
            '${exerciseState.countdownValue}',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        );
      case SolfegeState.analyzing:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card.withAlpha(240),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 12),
              Text(
                'Analisando...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _showExerciseResultModal(
      SolfegeExerciseState exerciseState) async {
    // Código original mantido, com correção de estilo
    final userSession =
        provider.Provider.of<UserSession>(context, listen: false);
    final score = exerciseState.pitchScore;
    final isPassed = score >= 90;

    if (isPassed) {
      _confettiController.play();
      SfxService.instance.playLessonComplete();
      userSession.answerCorrectly();
    } else {
      SfxService.instance.playError();
      userSession.answerWrongly();
    }
    userSession.recordPractice();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.card,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone de resultado
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPassed
                        ? [
                            AppColors.completed.withAlpha(100),
                            AppColors.completed.withAlpha(200)
                          ]
                        : [
                            AppColors.error.withAlpha(100),
                            AppColors.error.withAlpha(200)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  isPassed ? Icons.celebration : Icons.refresh,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Título principal
              FittedBox(
                child: Text(
                  isPassed ? '🎉 Excelente!' : '💪 Quase lá!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? AppColors.completed : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Flexible(
                child: Text(
                  isPassed
                      ? 'Você dominou esta sequência!'
                      : 'Continue praticando para melhorar!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),

              // Score com design melhorado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(50),
                      AppColors.accent.withAlpha(50)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(100)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_note,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Pontuação Final',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Análise detalhada de erros
              if (!isPassed && _detectedResults.isNotEmpty)
                ..._buildDetailedErrorAnalysis(),

              const SizedBox(height: 20),

              // Botões melhorados
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('Sair'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(solfegeExerciseProvider.notifier).reset();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailedErrorAnalysis() {
    final incorrectNotes = _detectedResults
        .asMap()
        .entries
        .where((entry) => !entry.value.pitchCorrect)
        .take(3) // Mostrar apenas os 3 primeiros erros para não sobrecarregar
        .toList();

    if (incorrectNotes.isEmpty) return [];

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withAlpha(100)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.error, size: 18),
                SizedBox(width: 8),
                Text(
                  'Análise dos Erros',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...incorrectNotes.map((entry) {
              final noteIndex = entry.key + 1; // 1-indexed para usuário
              final result = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withAlpha(150),
                      ),
                      child: Center(
                        child: Text(
                          '$noteIndex',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${result.expectedNote.lyric} (${result.expectedNote.note})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result.errorDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getErrorColor(result.pitchErrorDirection),
                            ),
                          ),
                          if (result.centsDifference.abs() > 10)
                            Text(
                              '${result.centsDifference.abs().round()} cents de diferença',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (incorrectNotes.length < _detectedResults.where((r) => !r.pitchCorrect).length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... e mais ${_detectedResults.where((r) => !r.pitchCorrect).length - incorrectNotes.length} erro(s)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Color _getErrorColor(PitchErrorDirection direction) {
    switch (direction) {
      case PitchErrorDirection.tooHigh:
        return Colors.red.shade400;
      case PitchErrorDirection.tooLow:
        return Colors.blue.shade400;
      case PitchErrorDirection.notSung:
        return Colors.grey.shade500;
      case PitchErrorDirection.correct:
        return AppColors.completed;
    }
  }
}

class OptimizedExerciseControlsSimple extends StatelessWidget {
  final SolfegeExerciseState state;
  final SolfegeExerciseNotifier notifier;
  const OptimizedExerciseControlsSimple(
      {super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final bool isIdle = state.state == SolfegeState.idle;
    final bool isBusy = state.state == SolfegeState.countdown ||
        state.state == SolfegeState.listening ||
        state.state == SolfegeState.analyzing;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Controles principais
          Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card.withAlpha(180),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withAlpha(100)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botão Preview com design melhorado
              _buildControlButton(
                icon: state.isPlayingPreview
                    ? Icons.stop_circle
                    : Icons.play_circle_filled,
                label: state.isPlayingPreview ? 'Parar' : 'Ouvir',
                isEnabled: isIdle,
                onPressed: () {
                  state.isPlayingPreview
                      ? notifier.stopPreview()
                      : notifier.playPreview();
                },
              ),

              // Botão principal (Microfone/Reset)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isBusy
                        ? [Colors.grey.shade400, Colors.grey.shade600]
                        : (state.state == SolfegeState.finished
                            ? [AppColors.primary, AppColors.primary.withAlpha(200)]
                            : [
                                AppColors.completed,
                                AppColors.completed.withAlpha(200)
                              ]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: !isBusy
                      ? [
                          BoxShadow(
                            color: (state.state == SolfegeState.finished
                                    ? AppColors.primary
                                    : AppColors.completed)
                                .withAlpha(100),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: FloatingActionButton(
                  onPressed: isBusy
                      ? null
                      : () {
                          if (state.state == SolfegeState.finished) {
                            notifier.reset();
                          } else {
                            notifier.startCountdown();
                          }
                        },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Icon(
                    state.state == SolfegeState.finished
                        ? Icons.refresh
                        : Icons.mic,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),

              // Botão Toggle Nomes
              _buildControlButton(
                icon: state.showNoteNames ? Icons.music_note : Icons.music_off,
                label: 'Nomes',
                isEnabled: isIdle,
                isActive: state.showNoteNames,
                onPressed: () => notifier.toggleNoteNames(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Controles avançados da partitura
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card.withAlpha(120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withAlpha(80)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primeira linha: Zoom e Layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Controles de Zoom
                  _buildZoomControls(),

                  // Divisor visual
                  Container(
                    height: 30,
                    width: 1,
                    color: AppColors.textSecondary.withAlpha(100),
                  ),

                  // Toggle Layout (Horizontal/Quebras)
                  _buildControlButton(
                    icon: state.displayMode == ScoreDisplayMode.horizontal
                        ? Icons.view_stream
                        : Icons.view_agenda,
                    label: state.displayMode == ScoreDisplayMode.horizontal
                        ? 'Linear'
                        : 'Quebras',
                    isEnabled: isIdle,
                    onPressed: () => notifier.toggleDisplayMode(),
                  ),

                  // Divisor visual
                  Container(
                    height: 30,
                    width: 1,
                    color: AppColors.textSecondary.withAlpha(100),
                  ),

                  // Toggle Oitava (Agudo/Grave)
                  _buildControlButton(
                    icon: state.exercise.isOctaveDown
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    label: state.exercise.isOctaveDown ? 'Grave' : 'Agudo',
                    isEnabled: isIdle,
                    isActive: state.exercise.isOctaveDown,
                    onPressed: () => notifier.toggleOctaveMode(),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Segunda linha: Configurações de Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Toggle Metrônomo no Preview
                  _buildControlButton(
                    icon: state.showMetronomeInPreview
                        ? Icons.timer
                        : Icons.timer_off,
                    label: 'Metrônomo',
                    isEnabled: isIdle,
                    isActive: state.showMetronomeInPreview,
                    onPressed: () => notifier.toggleMetronomeInPreview(),
                  ),
                ],
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    bool isActive = false,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.accent.withAlpha(200)
                : (isEnabled
                    ? Colors.white.withAlpha(50)
                    : Colors.grey.withAlpha(100)),
            border: Border.all(
              color: isActive ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(icon),
            iconSize: 24,
            color: isEnabled
                ? (isActive ? Colors.white : AppColors.textSecondary)
                : Colors.grey,
            onPressed: isEnabled ? onPressed : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isEnabled
                ? (isActive ? AppColors.accent : AppColors.textSecondary)
                : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Zoom Out
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.state == SolfegeState.idle
                    ? Colors.white.withAlpha(50)
                    : Colors.grey.withAlpha(100),
              ),
              child: IconButton(
                icon: const Icon(Icons.zoom_out),
                iconSize: 20,
                color: state.state == SolfegeState.idle
                    ? AppColors.textSecondary
                    : Colors.grey,
                onPressed: state.state == SolfegeState.idle && state.zoomLevel > 0.5
                    ? () => notifier.setZoomLevel((state.zoomLevel - 0.25).clamp(0.5, 2.0))
                    : null,
              ),
            ),

            // Indicador de zoom atual
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(state.zoomLevel * 100).round()}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Botão Zoom In
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.state == SolfegeState.idle
                    ? Colors.white.withAlpha(50)
                    : Colors.grey.withAlpha(100),
              ),
              child: IconButton(
                icon: const Icon(Icons.zoom_in),
                iconSize: 20,
                color: state.state == SolfegeState.idle
                    ? AppColors.textSecondary
                    : Colors.grey,
                onPressed: state.state == SolfegeState.idle && state.zoomLevel < 2.0
                    ? () => notifier.setZoomLevel((state.zoomLevel + 0.25).clamp(0.5, 2.0))
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Zoom',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
