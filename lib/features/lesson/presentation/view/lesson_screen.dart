// lib/features/lesson/presentation/view/lesson_screen.dart

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/sfx_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart' as provider;

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Future<List<LessonStep>> _stepsFuture;
  int _currentStepIndex = 0;
  bool? _isCorrect;
  bool _showFeedback = false;
  final DatabaseService _databaseService = DatabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  List<String> _dragSourceItems = [];
  final Map<int, String?> _dropTargetMatches = {};

  @override
  void initState() {
    super.initState();
    _stepsFuture = _fetchSteps();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  Future<List<LessonStep>> _fetchSteps() async {
    final result = await _databaseService.getStepsForLesson(widget.lesson.id);
    return switch (result) {
      Success<List<LessonStep>>(data: final data) => data,
      Failure<List<LessonStep>>(message: final error) => throw Exception(error),
    };
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _setupDragAndDropState(DragAndDropStep step) {
    if (_dragSourceItems.isEmpty && _dropTargetMatches.isEmpty) {
      _dragSourceItems = List<String>.from(step.draggableItems)..shuffle();
      for (int i = 0; i < step.correctOrder.length; i++) {
        _dropTargetMatches[i] = null;
      }
    }
  }

  // --- CORREÇÃO NA LÓGICA DE SUBMISSÃO DE RESPOSTA ---
  void _onAnswerSubmitted(bool isCorrect) {
    final userSession =
        provider.Provider.of<UserSession>(context, listen: false);

    if (isCorrect) {
      SfxService.instance.playCorrectAnswer();
      userSession.answerCorrectly();
    } else {
      SfxService.instance.playError();
      userSession.answerWrongly();
      final livesLeft = userSession.currentUser?.lives ?? 0;
      if (mounted) {
        _showLifeLostDialog(livesLeft);
      }
    }

    setState(() {
      _isCorrect = isCorrect;
      _showFeedback = true; // Garante que o feedback sempre será exibido
    });
  }
  // --- FIM DA CORREÇÃO ---

  void _checkDragAndDropAnswer(DragAndDropStep step) {
    final correctMatches =
        Map.fromIterables(step.draggableItems, step.correctOrder);
    bool allCorrect = true;

    for (int i = 0; i < step.correctOrder.length; i++) {
      final userPlacedItem = _dropTargetMatches[i];
      final correctDefinition = step.correctOrder[i];

      final correctKey = correctMatches.entries
          .firstWhere((entry) => entry.value == correctDefinition)
          .key;

      if (userPlacedItem != correctKey) {
        allCorrect = false;
        break;
      }
    }
    _onAnswerSubmitted(allCorrect);
  }

  void _resetStep() {
    setState(() {
      _showFeedback = false;
      _isCorrect = null;
      _stepsFuture.then((steps) {
        if (steps.isNotEmpty && steps[_currentStepIndex] is DragAndDropStep) {
          final step = steps[_currentStepIndex] as DragAndDropStep;
          _dragSourceItems.clear();
          _dropTargetMatches.clear();
          _setupDragAndDropState(step);
        }
      });
    });
  }

  void _nextStep(int totalSteps) async {
    final navigator = Navigator.of(context);
    final userSession = context.read<UserSession>();
    final user = userSession.currentUser;

    if (_currentStepIndex < totalSteps - 1) {
      setState(() {
        _currentStepIndex++;
        _showFeedback = false;
        _isCorrect = null;
        _dragSourceItems = [];
        _dropTargetMatches.clear();
      });
    } else {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await _databaseService.markLessonAsCompleted(userId, widget.lesson.id);
        await userSession.recordPractice();
      }

      await _showLessonCompleteDialog(10, user?.lives ?? 0);
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLives = context.watch<UserSession>().currentUser?.lives ?? 0;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.lesson.title),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            FutureBuilder<List<LessonStep>>(
              future: _stepsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent));
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                      child: Text(
                          'Erro: ${snapshot.error ?? "Não foi possível carregar o conteúdo da lição."}'));
                }

                final steps = snapshot.data!;
                final currentStep = steps[_currentStepIndex];
                final progress = (_currentStepIndex + 1) / steps.length;

                if (currentStep is DragAndDropStep) {
                  _setupDragAndDropState(currentStep);
                }

                // --- CORREÇÃO NA CONDIÇÃO DE GAME OVER ---
                // A tela de "Game Over" agora é exibida se o usuário não tiver vidas
                // E a última resposta submetida foi incorreta.
                if (userLives <= 0 && _isCorrect == false && _showFeedback) {
                  return _buildGameOverWidget();
                }
                // --- FIM DA CORREÇÃO ---

                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.card,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.completed),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildStepWidget(currentStep),
                      ),
                    ),
                    if (currentStep is! DragAndDropStep && _showFeedback)
                      _buildFeedbackBar(steps.length)
                    else if (currentStep is DragAndDropStep && !_showFeedback)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _checkDragAndDropAnswer(currentStep);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.completed,
                              minimumSize: const Size(double.infinity, 50)),
                          child: const Text('Verificar',
                              style: TextStyle(fontSize: 18)),
                        ),
                      )
                    else if (currentStep is DragAndDropStep && _showFeedback)
                      _buildFeedbackBar(steps.length),
                  ],
                );
              },
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
    );
  }

  Widget _buildStepWidget(LessonStep step) {
    switch (step.type) {
      case LessonStepType.explanation:
        return _buildExplanationWidget(step as ExplanationStep);
      case LessonStepType.multipleChoice:
        return _buildMultipleChoiceWidget(step as MultipleChoiceQuestionStep);
      case LessonStepType.dragAndDrop:
        return _buildDragAndDropWidget(step as DragAndDropStep);
      case LessonStepType.earTraining:
        return _buildEarTrainingWidget(step as EarTrainingStep);
    }
  }

  Widget _buildExplanationWidget(ExplanationStep step) {
    final bool hasImage = step.imageUrl != null && step.imageUrl!.isNotEmpty;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment:
                  hasImage ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                if (hasImage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Image.network(step.imageUrl!),
                  ),
                Text(
                  step.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            SfxService.instance.playClick();
            final steps = await _stepsFuture;
            _nextStep(steps.length);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Continuar', style: TextStyle(fontSize: 18)),
        )
      ],
    );
  }

  Widget _buildMultipleChoiceWidget(MultipleChoiceQuestionStep step) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            step.questionText,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ...step.options.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: _showFeedback
                    ? null
                    : () {
                        _onAnswerSubmitted(option == step.correctAnswer);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(option, style: const TextStyle(fontSize: 18)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDragAndDropWidget(DragAndDropStep step) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            step.questionText,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Column(
            children: List.generate(step.correctOrder.length, (index) {
              return DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _dropTargetMatches[index] != null
                                ? AppColors.accent
                                : AppColors.primary,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(11),
                                bottomLeft: Radius.circular(11)),
                          ),
                          child: _dropTargetMatches[index] != null
                              ? Center(
                                  child: Text(
                                  _dropTargetMatches[index]!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.background),
                                  textAlign: TextAlign.center,
                                ))
                              : null,
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(step.correctOrder[index],
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onWillAcceptWithDetails: (details) =>
                    !_dropTargetMatches.containsValue(details.data),
                onAcceptWithDetails: (details) {
                  setState(() {
                    SfxService.instance.playClick();
                    _dropTargetMatches[index] = details.data;
                    _dragSourceItems.remove(details.data);
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.primary, thickness: 1),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: step.draggableItems.map((item) {
              bool isItemVisible = _dragSourceItems.contains(item);
              return Opacity(
                opacity: isItemVisible ? 1.0 : 0.0,
                child: Draggable<String>(
                  data: item,
                  feedback: Material(
                    type: MaterialType.transparency,
                    child: Chip(
                        label: Text(item),
                        backgroundColor: AppColors.accent,
                        labelStyle: const TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold)),
                  ),
                  childWhenDragging:
                      Chip(label: Text(item), backgroundColor: AppColors.card),
                  child: isItemVisible
                      ? Chip(
                          label: Text(item),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8))
                      : const SizedBox.shrink(),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEarTrainingWidget(EarTrainingStep step) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            step.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: AppColors.accent),
            iconSize: 80,
            onPressed: () async {
              SfxService.instance.playClick();
              if (step.audioUrl.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Áudio para este exercício não encontrado.')));
                }
                return;
              }
              try {
                await _audioPlayer.setUrl(step.audioUrl);
                _audioPlayer.play();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Não foi possível carregar o áudio.')));
                }
              }
            },
          ),
          const SizedBox(height: 40),
          ...step.options.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: _showFeedback
                    ? null
                    : () {
                        _onAnswerSubmitted(option == step.correctAnswer);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(option, style: const TextStyle(fontSize: 18)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedbackBar(int totalSteps) {
    final bool isCorrect = _isCorrect ?? false;
    final userLives = context.watch<UserSession>().currentUser?.lives ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isCorrect ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isCorrect ? 'Correto!' : 'Ops! Tente novamente.',
              style: TextStyle(
                color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (isCorrect)
            ElevatedButton(
              onPressed: () {
                SfxService.instance.playClick();
                _nextStep(totalSteps);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600),
              child: Text(_currentStepIndex < totalSteps - 1
                  ? 'Continuar'
                  : 'Finalizar Lição'),
            )
          else if (userLives > 0)
            ElevatedButton(
              onPressed: () {
                SfxService.instance.playClick();
                _resetStep();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600),
              child: const Text('Tentar Novamente'),
            )
          else
            ElevatedButton(
              onPressed: () {
                SfxService.instance.playClick();
                Navigator.of(context).pop();
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Sair da Lição'),
            ),
        ],
      ),
    );
  }

  Future<void> _showLifeLostDialog(int livesLeft) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.favorite_border, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Text('Vida Perdida!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Você errou. Tenha mais cuidado! Vidas restantes: $livesLeft',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SfxService.instance.playClick();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLessonCompleteDialog(int pointsGained, int totalLives) {
    _confettiController.play();
    SfxService.instance.playLessonComplete();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lição Concluída!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: AppColors.accent, size: 60),
            const SizedBox(height: 16),
            Text(
              'Você ganhou +$pointsGained pontos!',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Vidas restantes: $totalLives',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                SfxService.instance.playClick();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.completed),
              child: const Text('Continuar Jornada'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGameOverWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, color: AppColors.primary, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Você não tem mais vidas!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pratique mais para recuperar vidas e tentar novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              SfxService.instance.playClick();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sair da Lição'),
          ),
        ],
      ),
    );
  }
}
