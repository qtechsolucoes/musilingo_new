// ==========================================
// lib/features/practice_solfege/presentation/view/solfege_exercise_list_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/practice/presentation/widgets/exercise_node_widget.dart';
import 'package:musilingo/features/practice_solfege/data/services/solfege_service.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_progress_model.dart';
import 'package:musilingo/features/practice_solfege/presentation/view/solfege_exercise_screen.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:provider/provider.dart' as provider;

class SolfegeExerciseListScreen extends StatefulWidget {
  final String difficulty;

  const SolfegeExerciseListScreen({super.key, required this.difficulty});

  @override
  State<SolfegeExerciseListScreen> createState() =>
      _SolfegeExerciseListScreenState();
}

class _SolfegeExerciseListScreenState extends State<SolfegeExerciseListScreen> {
  final SolfegeService _solfegeService = SolfegeService();
  late Future<List<SolfegeExercise>> _exercisesFuture;
  late Future<List<SolfegeProgress>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _solfegeService.getExercisesByDifficulty(widget.difficulty);
    _progressFuture = _loadUserProgress();
  }

  Future<List<SolfegeProgress>> _loadUserProgress() async {
    final userSession = context.read<UserSession>();
    final userId = userSession.currentUser?.id;

    if (userId != null) {
      // Inicializar progresso se necessário
      await _solfegeService.initializeUserProgress(userId, widget.difficulty);
      return await _solfegeService.getUserProgressByDifficulty(userId, widget.difficulty);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // 1. Usando o GradientBackground como base
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          // 2. AppBar transparente e estilizada
          title: Text(widget.difficulty,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<List<dynamic>>(
          future: Future.wait([_exercisesFuture, _progressFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Erro: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.text)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text('Nenhum exercício encontrado.',
                      style: TextStyle(color: AppColors.text)));
            }

            final exercises = snapshot.data![0] as List<SolfegeExercise>;
            final progressList = snapshot.data![1] as List<SolfegeProgress>;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final progress = _findProgressForExercise(progressList, int.parse(exercise.id));
                final isUnlocked = _isExerciseUnlocked(exercises, progressList, index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildExerciseCard(exercise, progress, isUnlocked),
                );
              },
            );
          },
        ),
      ),
    );
  }

  SolfegeProgress? _findProgressForExercise(List<SolfegeProgress> progressList, int exerciseId) {
    try {
      return progressList.firstWhere((p) => p.exerciseId == BigInt.from(exerciseId));
    } catch (e) {
      return null;
    }
  }

  bool _isExerciseUnlocked(List<SolfegeExercise> exercises, List<SolfegeProgress> progressList, int index) {
    // Primeiro exercício sempre desbloqueado
    if (index == 0) return true;

    // Verificar se o exercício atual está marcado como desbloqueado no banco
    final currentExercise = exercises[index];
    final currentProgress = _findProgressForExercise(progressList, int.parse(currentExercise.id));

    debugPrint('VERIFICANDO DESBLOQUEIO: Exercise[$index] ID=${currentExercise.id}');
    debugPrint('  - CurrentProgress: isUnlocked=${currentProgress?.isUnlocked}, bestScore=${currentProgress?.bestScore}');

    // Se existe progresso e está marcado como desbloqueado, liberar
    if (currentProgress?.isUnlocked == true) {
      debugPrint('  - DESBLOQUEADO: Campo isUnlocked=true');
      return true;
    }

    // Fallback: verificar se o exercício anterior foi completado com 90%+
    final previousExercise = exercises[index - 1];
    final previousProgress = _findProgressForExercise(progressList, int.parse(previousExercise.id));

    debugPrint('  - PreviousProgress: isCompleted=${previousProgress?.isCompleted}, bestScore=${previousProgress?.bestScore}');

    final result = previousProgress?.isCompleted ?? false;
    debugPrint('  - RESULTADO FINAL: ${result ? "DESBLOQUEADO" : "BLOQUEADO"}');

    return result;
  }

  Widget _buildExerciseCard(SolfegeExercise exercise, SolfegeProgress? progress, bool isUnlocked) {
    // Cores e opacidade baseadas no estado
    final cardColor = isUnlocked ? AppColors.card : AppColors.card.withAlpha(100);
    final textColor = isUnlocked ? AppColors.text : AppColors.textSecondary;
    final iconColor = isUnlocked ? AppColors.accent : AppColors.textSecondary;

    // Se for clave de sol, mostrar opções de oitava
    if (exercise.clef.toLowerCase() == 'treble') {
      return Card(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isUnlocked ? 4 : 1,
        child: Stack(
          children: [
            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isUnlocked ? Icons.mic : Icons.lock,
                        size: 24,
                        color: iconColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.keySignature} | ${exercise.timeSignature} | ${exercise.tempo} BPM',
                              style: TextStyle(
                                fontSize: 14,
                                color: isUnlocked ? AppColors.textSecondary : AppColors.textSecondary.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge de progresso
                      if (progress != null) _buildProgressBadge(progress),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (!isUnlocked) ...[
                    // Mensagem de bloqueio
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.error, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Complete o exercício anterior com 90% para desbloquear',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Opções de oitava para clave de sol
                    Text(
                      'Escolha a região vocal:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Opção normal (agudo)
                        Expanded(
                          child: _buildOctaveOption(
                            exercise: exercise,
                            isOctaveDown: false,
                            title: 'Agudo',
                            subtitle: 'Clave de Sol',
                            icon: Icons.keyboard_arrow_up,
                            color: AppColors.completed,
                            enabled: isUnlocked,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Opção oitava abaixo (grave)
                        Expanded(
                          child: _buildOctaveOption(
                            exercise: exercise,
                            isOctaveDown: true,
                            title: 'Grave',
                            subtitle: 'Sol 8va ↓',
                            icon: Icons.keyboard_arrow_down,
                            color: AppColors.primary,
                            enabled: isUnlocked,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Para outras claves, usar o widget adaptado
      return ExerciseNodeWidget(
        title: exercise.title,
        description:
            '${exercise.keySignature} | ${exercise.timeSignature} | ${exercise.tempo} BPM',
        icon: isUnlocked ? Icons.mic : Icons.lock,
        onTap: isUnlocked ? () => _navigateToExercise(exercise, false, progress) : () {},
      );
    }
  }

  Widget _buildProgressBadge(SolfegeProgress progress) {
    Color badgeColor = AppColors.textSecondary;
    String badgeText = '${progress.attempts}x';
    IconData badgeIcon = Icons.play_circle_outline;

    if (progress.bestScore >= 90) {
      badgeColor = AppColors.completed;
      badgeText = '${progress.bestScore}%';
      badgeIcon = Icons.star;
    } else if (progress.bestScore >= 50) {
      badgeColor = AppColors.primary;
      badgeText = '${progress.bestScore}%';
      badgeIcon = Icons.check_circle_outline;
    } else if (progress.attempts > 0) {
      badgeColor = AppColors.error;
      badgeText = '${progress.bestScore}%';
      badgeIcon = Icons.refresh;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOctaveOption({
    required SolfegeExercise exercise,
    required bool isOctaveDown,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
  }) {
    final finalColor = enabled ? color : AppColors.textSecondary;

    return Card(
      color: finalColor.withAlpha(enabled ? 40 : 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: enabled ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? () => _navigateToExercise(exercise, isOctaveDown, null) : null,
        splashColor: enabled ? finalColor.withAlpha(80) : null,
        highlightColor: enabled ? finalColor.withAlpha(50) : null,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: finalColor.withAlpha(enabled ? 80 : 40),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: finalColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: finalColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withAlpha(120),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToExercise(SolfegeExercise exercise, bool isOctaveDown, SolfegeProgress? progress) {
    // Criar uma cópia do exercício com a configuração de oitava
    final modifiedExercise = SolfegeExercise(
      id: exercise.id,
      title: exercise.title,
      difficultyLevel: exercise.difficultyLevel,
      difficultyValue: exercise.difficultyValue,
      keySignature: exercise.keySignature,
      timeSignature: exercise.timeSignature,
      tempo: exercise.tempo,
      noteSequence: exercise.noteSequence,
      createdAt: exercise.createdAt,
      clef: exercise.clef,
      isOctaveDown: isOctaveDown,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolfegeExerciseScreen(exercise: modifiedExercise),
      ),
    ).then((_) {
      // Recarregar progresso após voltar do exercício
      setState(() {
        _progressFuture = _loadUserProgress();
      });
    });
  }
}
