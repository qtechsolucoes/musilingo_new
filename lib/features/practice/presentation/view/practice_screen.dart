// lib/features/practice/presentation/view/practice_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/practice/presentation/view/harmonic_perception_list_screen.dart';
import 'package:musilingo/features/practice/presentation/view/harmonic_progression_list_screen.dart';
import 'package:musilingo/features/practice/presentation/view/melodic_perception_list_screen.dart';
import 'package:musilingo/features/practice/presentation/widgets/exercise_node_widget.dart';

// 1. IMPORTAR A TELA DE ENTRADA DO SOLFEJO
import 'package:musilingo/features/practice_solfege/presentation/view/solfege_difficulty_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Prática',
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
                'Aprimore suas habilidades com exercícios focados.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // 2. ADICIONADO O NOVO EXERCÍCIO DE SOLFEJO
              ExerciseNodeWidget(
                title: 'Solfejo',
                description: 'Treine sua afinação e leitura à primeira vista.',
                icon: Icons.mic,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SolfegeDifficultyScreen()));
                },
              ),
              const SizedBox(height: 16),

              ExerciseNodeWidget(
                title: 'Percepção Melódica',
                description: 'Transcreva melodias de ouvido.',
                icon: Icons.music_note,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MelodicPerceptionListScreen()));
                },
              ),
              const SizedBox(height: 16),
              ExerciseNodeWidget(
                title: 'Percepção Harmônica',
                description: 'Identifique acordes e suas qualidades.',
                icon: Icons.hearing,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const HarmonicPerceptionListScreen()));
                },
              ),
              const SizedBox(height: 16),
              ExerciseNodeWidget(
                title: 'Progressões Harmônicas',
                description: 'Identifique sequências de acordes.',
                icon: Icons.double_arrow_rounded,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const HarmonicProgressionListScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
