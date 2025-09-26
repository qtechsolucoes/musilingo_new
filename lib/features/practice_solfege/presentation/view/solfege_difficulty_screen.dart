// ==========================================
// lib/features/practice_solfege/presentation/view/solfege_difficulty_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/practice/presentation/widgets/exercise_node_widget.dart';
import 'package:musilingo/features/practice_solfege/presentation/view/solfege_exercise_list_screen.dart';

class SolfegeDifficultyScreen extends StatelessWidget {
  const SolfegeDifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Usando o GradientBackground como base
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          // 2. AppBar transparente e com o estilo de texto correto
          title: const Text('Solfejo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecione o nível para treinar sua afinação.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // 3. Substituindo o Card antigo pelo seu ExerciseNodeWidget
              ExerciseNodeWidget(
                title: 'Iniciante',
                description: 'Intervalos simples e notas fundamentais.',
                icon: Icons.looks_one,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SolfegeExerciseListScreen(
                          difficulty: 'Iniciante'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              ExerciseNodeWidget(
                title: 'Intermediário',
                description: 'Escalas, arpejos e saltos maiores.',
                icon: Icons.looks_two,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SolfegeExerciseListScreen(
                          difficulty: 'Intermediário'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              ExerciseNodeWidget(
                title: 'Avançado',
                description: 'Escalas cromáticas e intervalos complexos.',
                icon: Icons.looks_3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SolfegeExerciseListScreen(
                          difficulty: 'Avançado'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
