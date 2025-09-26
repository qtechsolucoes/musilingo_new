// lib/features/practice_solfege/presentation/view/solfege_exercises_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/features/practice_solfege/data/models/solfege_progress.dart';
import 'package:musilingo/features/practice_solfege/providers/solfege_exercises_list_provider.dart';
import 'package:musilingo/features/practice_solfege/providers/solfege_exercise_provider.dart';
import 'package:musilingo/features/practice_solfege/presentation/view/solfege_exercise_screen.dart';

class SolfegeExercisesListScreen extends ConsumerStatefulWidget {
  const SolfegeExercisesListScreen({super.key});

  @override
  ConsumerState<SolfegeExercisesListScreen> createState() => _SolfegeExercisesListScreenState();
}

class _SolfegeExercisesListScreenState extends ConsumerState<SolfegeExercisesListScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar exercícios ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(solfegeExercisesListProvider.notifier).loadExercisesAndProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(solfegeExercisesListProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Exercícios de Solfejo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => _showLevelSelector(),
              icon: const Icon(Icons.tune, color: AppColors.text),
              tooltip: 'Alterar nível',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(solfegeExercisesListProvider.notifier).refresh(),
          child: _buildBody(listState),
        ),
      ),
    );
  }

  Widget _buildBody(SolfegeExercisesListState listState) {
    if (listState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text(
              'Carregando exercícios...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (listState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar exercícios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              listState.error!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(solfegeExercisesListProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (listState.exercises.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum exercício encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Exercícios serão adicionados em breve!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com informações do nível
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withAlpha(100)),
          ),
          child: Column(
            children: [
              Text(
                'Nível ${listState.selectedLevel.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${listState.unlockedExerciseIds.length} de ${listState.exercises.length} exercícios desbloqueados',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              // Barra de progresso
              LinearProgressIndicator(
                value: listState.exercises.isEmpty ? 0 : listState.unlockedExerciseIds.length / listState.exercises.length,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.completed),
              ),
            ],
          ),
        ),

        // Lista de exercícios
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: listState.exercises.length,
            itemBuilder: (context, index) {
              final exercise = listState.exercises[index];
              final exerciseId = int.parse(exercise.id);
              final isUnlocked = listState.isExerciseUnlocked(exerciseId);
              final isCompleted = listState.isExerciseCompleted(exerciseId);
              final bestScore = listState.getExerciseBestScore(exerciseId);
              final progress = listState.getProgressForExercise(exerciseId);

              return _buildExerciseCard(
                exercise,
                isUnlocked,
                isCompleted,
                bestScore,
                progress,
                index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(
    SolfegeExercise exercise,
    bool isUnlocked,
    bool isCompleted,
    int bestScore,
    SolfegeProgress? progress,
    int exerciseNumber,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked ? () => _navigateToExercise(exercise) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.card : AppColors.card.withAlpha(100),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? AppColors.completed
                    : (isUnlocked ? AppColors.primary.withAlpha(100) : Colors.grey.withAlpha(100)),
                width: isCompleted ? 2 : 1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Ícone do status
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.completed
                        : (isUnlocked ? AppColors.primary : Colors.grey),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : (isUnlocked
                            ? Text(
                                '$exerciseNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Icon(Icons.lock, color: Colors.white, size: 24)),
                  ),
                ),

                const SizedBox(width: 16),

                // Informações do exercício
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? AppColors.text : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dificuldade ${exercise.difficultyValue}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.music_note,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exercise.noteSequence.length} notas',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (progress != null && progress.attempts > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: bestScore >= 90
                                    ? AppColors.completed.withAlpha(200)
                                    : (bestScore >= 50 ? Colors.orange.withAlpha(200) : AppColors.error.withAlpha(200)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Melhor: $bestScore%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${progress.attempts} tentativa${progress.attempts != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Indicador visual
                if (isUnlocked)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToExercise(SolfegeExercise exercise) async {
    try {
      // Carregar exercício no provider
      await ref.read(solfegeExerciseProvider.notifier).loadExerciseById(int.parse(exercise.id));

      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => SolfegeExerciseScreen(exercise: exercise),
          ),
        );

        // Se completou o exercício, atualizar a lista
        if (result == true) {
          ref.read(solfegeExercisesListProvider.notifier).refresh();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar exercício: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLevelSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecionar Nível',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),

              // Por enquanto só temos 'iniciante'
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.accent),
                title: const Text('Iniciante'),
                subtitle: const Text('Exercícios básicos de solfejo'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(solfegeExercisesListProvider.notifier).changeLevel('iniciante');
                },
              ),

              // Placeholder para futuros níveis
              ListTile(
                leading: Icon(Icons.star_half, color: Colors.grey.shade400),
                title: Text('Intermediário', style: TextStyle(color: Colors.grey.shade600)),
                subtitle: Text('Em breve...', style: TextStyle(color: Colors.grey.shade500)),
                enabled: false,
              ),

              ListTile(
                leading: Icon(Icons.star_border, color: Colors.grey.shade400),
                title: Text('Avançado', style: TextStyle(color: Colors.grey.shade600)),
                subtitle: Text('Em breve...', style: TextStyle(color: Colors.grey.shade500)),
                enabled: false,
              ),
            ],
          ),
        );
      },
    );
  }
}