// lib/features/practice/presentation/view/harmonic_progression_list_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/harmonic_progression_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/features/practice/presentation/view/harmonic_progression_exercise_screen.dart';
import 'package:musilingo/features/practice/presentation/widgets/exercise_node_widget.dart';

class HarmonicProgressionListScreen extends StatefulWidget {
  const HarmonicProgressionListScreen({super.key});

  @override
  State<HarmonicProgressionListScreen> createState() =>
      _HarmonicProgressionListScreenState();
}

class _HarmonicProgressionListScreenState
    extends State<HarmonicProgressionListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<Result<List<HarmonicProgression>>> _progressionsFuture;

  @override
  void initState() {
    super.initState();
    _progressionsFuture = _databaseService.getHarmonicProgressions();
  }

  String _getDifficultyName(int level) {
    switch (level) {
      case 1:
        return 'Iniciante';
      case 2:
        return 'Intermediário';
      case 3:
        return 'Avançado';
      case 4:
        return 'Mestre';
      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Progressões Harmônicas'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<Result<List<HarmonicProgression>>>(
          future: _progressionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Nenhum exercício encontrado.'));
            }

            final result = snapshot.data!;
            if (result.isFailure) {
              return Center(child: Text('Erro: ${result.errorMessage}'));
            }

            final progressions = result.data;
            if (progressions.isEmpty) {
              return const Center(child: Text('Nenhum exercício encontrado.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: progressions.length,
              itemBuilder: (context, index) {
                final progression = progressions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ExerciseNodeWidget(
                    title: progression.title,
                    description: _getDifficultyName(progression.difficulty),
                    icon: Icons.double_arrow_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HarmonicProgressionExerciseScreen(
                              exercise: progression),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
