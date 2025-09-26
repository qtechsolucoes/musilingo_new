// lib/features/practice/presentation/view/melodic_perception_exercise_screen.dart

import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/presentation/widgets/score_viewer_widget.dart';
import 'package:musilingo/app/services/sfx_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/practice/presentation/viewmodel/melodic_exercise_viewmodel.dart';
import 'package:musilingo/features/practice/presentation/widgets/melodic_input_panel.dart';
import 'package:provider/provider.dart' as provider;
import 'package:musilingo/app/services/orientation_service.dart';

class MusicUtils {
  static const Map<String, int> _noteValues = {
    'C': 0,
    'C#': 1,
    'Db': 1,
    'D': 2,
    'D#': 3,
    'Eb': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'Gb': 6,
    'G': 7,
    'G#': 8,
    'Ab': 8,
    'A': 9,
    'A#': 10,
    'Bb': 10,
    'B': 11
  };
  static int noteNameToMidi(String noteName) {
    if (noteName.contains("rest")) {
      return 0;
    }
    final notePart = noteName.replaceAll(RegExp(r'[0-9]'), '');
    final octavePart = noteName.replaceAll(RegExp(r'[^0-9]'), '');
    if (octavePart.isEmpty || !_noteValues.containsKey(notePart)) {
      return 60;
    }
    final octave = int.parse(octavePart);
    return _noteValues[notePart]! + (octave + 1) * 12;
  }

  static const Map<String, double> figureDurations = {
    'whole': 4.0,
    'half': 2.0,
    'quarter': 1.0,
    'eighth': 0.5,
    '16th': 0.25,
    '32nd': 0.125,
    '64th': 0.0625,
  };
}

class MelodicPerceptionExerciseScreen extends StatelessWidget {
  final MelodicExercise exercise;
  const MelodicPerceptionExerciseScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider(
      create: (_) => MelodicExerciseViewModel(exercise: exercise),
      child: const _MelodicExerciseView(),
    );
  }
}

class _MelodicExerciseView extends StatefulWidget {
  const _MelodicExerciseView();

  @override
  State<_MelodicExerciseView> createState() => _MelodicExerciseViewState();
}

class _MelodicExerciseViewState extends State<_MelodicExerciseView> {
  final _midiPro = MidiPro();
  int? _instrumentSoundfontId;
  int? _percussionSoundfontId;
  late ConfettiController _confettiController;
  bool _isSoundfontReady = false;
  bool _isMetronomeEnabled = true;
  final ValueNotifier<int> _beatCountNotifier = ValueNotifier(0);

  static final Map<String, String> _figureSymbols = {
    'whole': '𝅝',
    'half': '𝅗𝅥',
    'quarter': '𝅘𝅥',
    'eighth': '𝅘𝅥𝅮',
    '16th': '𝅘𝅥𝅯',
    '32nd': '𝅘𝅥𝅰',
    '64th': '𝅘𝅥𝅱',
  };
  static final Map<String, String> _restSymbols = {
    'whole': '𝄻',
    'half': '𝄼',
    'quarter': '𝄽',
    'eighth': '𝄾',
    '16th': '𝄿',
    '32nd': '𝅀',
    '64th': '𝅁',
  };

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _initializeScreen();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _beatCountNotifier.dispose();
    OrientationService.instance.removeOrientation('melodic_exercise');
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await OrientationService.instance.setMusicExerciseMode('melodic_exercise');
    await _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      const sfPath = 'assets/sf2/GeneralUserGS.sf2';
      final sfInstrument =
          await _midiPro.loadSoundfont(path: sfPath, bank: 0, program: 0);
      final sfPercussion =
          await _midiPro.loadSoundfont(path: sfPath, bank: 128, program: 0);
      if (mounted) {
        setState(() {
          _instrumentSoundfontId = sfInstrument;
          _percussionSoundfontId = sfPercussion;
          _isSoundfontReady = true;
        });
      }
    } catch (e) {
      debugPrint("Erro ao inicializar o áudio com MidiPro: $e");
    }
  }

  // FASE 4.4: _loadScore removido - ScoreViewerWidget cuida da renderização via Verovio

  void _verifyAnswer() {
    final viewModel = context.read<MelodicExerciseViewModel>();
    final userSession = context.read<UserSession>();
    final isCorrect = viewModel.verifyAnswer();

    setState(() {});

    if (isCorrect) {
      userSession.answerCorrectly();
      userSession.recordPractice();
      _showSuccessDialog();
    } else {
      userSession.answerWrongly();
      _showErrorDialog();
    }
  }

  Future<void> _playSequence(List<String> sequence) async {
    if (!_isSoundfontReady ||
        _instrumentSoundfontId == null ||
        _percussionSoundfontId == null) {
      return;
    }
    final exercise = context.read<MelodicExerciseViewModel>().exercise;
    final int bpm = exercise.tempo;
    final double beatDurationMs = 60000.0 / bpm;
    final timeSignatureParts = exercise.timeSignature.split('/');
    final beatsPerMeasure = int.parse(timeSignatureParts[0]);

    for (int i = 0; i < beatsPerMeasure; i++) {
      if (!mounted) break;
      _beatCountNotifier.value = i + 1;
      _midiPro.playNote(
          sfId: _percussionSoundfontId!,
          channel: 9,
          key: (i == 0) ? 76 : 77,
          velocity: (i == 0) ? 127 : 100);
      await Future.delayed(Duration(milliseconds: beatDurationMs.round()));
    }

    int currentBeat = 0;
    for (String noteData in sequence) {
      if (!mounted) break;
      final parts = noteData.split('_');
      final noteName = parts[0];
      final durationName = parts[1];
      final midiNote = MusicUtils.noteNameToMidi(noteName);
      final beatDurationMultiplier =
          MusicUtils.figureDurations[durationName] ?? 1.0;

      if (_isMetronomeEnabled) {
        for (int i = 0; i < beatDurationMultiplier; i++) {
          if (!mounted) break;
          _beatCountNotifier.value = ((currentBeat + i) % beatsPerMeasure) + 1;
          _midiPro.playNote(
              sfId: _percussionSoundfontId!,
              channel: 9,
              key: ((currentBeat + i) % beatsPerMeasure == 0) ? 76 : 77,
              velocity: 100);
          if (i == 0 && !noteName.contains("rest")) {
            _midiPro.playNote(
                sfId: _instrumentSoundfontId!,
                channel: 0,
                key: midiNote,
                velocity: 127);
          }
          await Future.delayed(Duration(milliseconds: beatDurationMs.round()));
        }
      } else {
        if (!noteName.contains("rest")) {
          _midiPro.playNote(
              sfId: _instrumentSoundfontId!,
              channel: 0,
              key: midiNote,
              velocity: 127);
        }
        await Future.delayed(Duration(
            milliseconds: (beatDurationMs * beatDurationMultiplier).round()));
      }

      if (!noteName.contains("rest")) {
        _midiPro.stopNote(
            sfId: _instrumentSoundfontId!, channel: 0, key: midiNote);
      }
      currentBeat += beatDurationMultiplier.round();
    }
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    _beatCountNotifier.value = 0;
  }

  void _playExerciseMelody() {
    SfxService.instance.playClick();
    final exercise = context.read<MelodicExerciseViewModel>().exercise;
    _playSequence(exercise.correctSequence);
  }

  void _playUserSequence() {
    SfxService.instance.playClick();
    final userSequence = context.read<MelodicExerciseViewModel>().userSequence;
    _playSequence(userSequence);
  }

  Future<void> _showSuccessDialog() {
    _confettiController.play();
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
                backgroundColor: AppColors.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Excelente!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.bold)),
                content:
                    const Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star, color: AppColors.accent, size: 50),
                  SizedBox(height: 12),
                  Text('Você transcreveu a melodia perfeitamente!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('+10 pontos!',
                      style: TextStyle(color: AppColors.textSecondary))
                ]),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        SfxService.instance.playClick();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.completed),
                      child: const Text('Continuar'))
                ]));
  }

  Future<void> _showErrorDialog() {
    final livesLeft = context.read<UserSession>().currentUser?.lives ?? 0;
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
                backgroundColor: AppColors.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied,
                          color: AppColors.error, size: 24),
                      SizedBox(width: 8),
                      Text('Quase lá!', style: TextStyle(color: Colors.white))
                    ]),
                content: Text(
                    'A sequência não está correta.\nVidas restantes: $livesLeft',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                      onPressed: () {
                        SfxService.instance.playClick();
                        Navigator.of(context).pop();
                        context.read<MelodicExerciseViewModel>().reset();
                      },
                      child: const Text('Tentar Novamente'))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSoundfontReady) {
      final exercise = context.read<MelodicExerciseViewModel>().exercise;
      return GradientBackground(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
                title: Text(exercise.title),
                backgroundColor: Colors.transparent,
                elevation: 0),
            body: const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 16),
                  Text("A carregar o exercício...")
                ]))),
      );
    }

    final viewModel = context.watch<MelodicExerciseViewModel>();
    // FASE 4.4: _loadScore removido - ScoreViewerWidget cuida da renderização automaticamente

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(viewModel.exercise.title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
                icon: const Icon(Icons.undo),
                tooltip: "Desfazer última nota",
                onPressed: viewModel.isVerified
                    ? null
                    : () {
                        SfxService.instance.playClick();
                        context
                            .read<MelodicExerciseViewModel>()
                            .removeLastNote();
                      }),
            IconButton(
              icon: SvgPicture.asset('assets/images/metronome.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                      _isMetronomeEnabled ? AppColors.accent : Colors.white54,
                      BlendMode.srcIn)),
              tooltip: "Metrônomo",
              onPressed: () {
                SfxService.instance.playClick();
                setState(() => _isMetronomeEnabled = !_isMetronomeEnabled);
              },
            ),
            IconButton(
                icon: const Icon(Icons.hearing),
                tooltip: "Ouvir o desafio",
                onPressed: viewModel.isVerified ? null : _playExerciseMelody),
            IconButton(
                icon: const Icon(Icons.play_circle_outline),
                tooltip: "Ouvir sua resposta",
                onPressed: viewModel.isVerified ? null : _playUserSequence),
            if (viewModel.isVerified)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: "Tentar Novamente",
                onPressed: () {
                  SfxService.instance.playClick();
                  context.read<MelodicExerciseViewModel>().reset();
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ScoreViewerWidget(
                      musicXML: viewModel.musicXml,
                    ),
                    Positioned(
                      top: 24,
                      left: 24,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _beatCountNotifier,
                        builder: (context, beat, child) {
                          return AnimatedOpacity(
                            opacity: beat == 0 ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(200),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withAlpha(180),
                                    blurRadius: 15.0,
                                    spreadRadius: 2.0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(beat.toString(),
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
              MelodicInputPanel(
                notePalette: viewModel.octaveAdjustedNotePalette,
                figurePalette: _figureSymbols,
                restPalette: _restSymbols,
                selectedNote: viewModel.selectedNote,
                selectedFigure: viewModel.selectedFigure,
                isVerified: viewModel.isVerified,
                onNoteSelected:
                    context.read<MelodicExerciseViewModel>().onNoteSelected,
                onFigureSelected:
                    context.read<MelodicExerciseViewModel>().onFigureSelected,
                onAddNote: () {
                  context.read<MelodicExerciseViewModel>().addNoteToSequence();
                },
                onAddRest: () {
                  context.read<MelodicExerciseViewModel>().addRest();
                },
                onVerify: _verifyAnswer,
                displayOctave: viewModel.displayOctave,
                onOctaveUp: context.read<MelodicExerciseViewModel>().onOctaveUp,
                onOctaveDown:
                    context.read<MelodicExerciseViewModel>().onOctaveDown,
                currentAccidental: viewModel.currentAccidental,
                onAccidentalSelected: context
                    .read<MelodicExerciseViewModel>()
                    .onAccidentalSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
