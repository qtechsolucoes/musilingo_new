// lib/features/practice/presentation/view/harmonic_perception_list_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/harmonic_exercise_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/features/practice/presentation/view/harmonic_perception_exercise_screen.dart';
import 'package:musilingo/features/practice/presentation/widgets/exercise_node_widget.dart';

class HarmonicPerceptionListScreen extends StatefulWidget {
  const HarmonicPerceptionListScreen({super.key});

  @override
  State<HarmonicPerceptionListScreen> createState() =>
      _HarmonicPerceptionListScreenState();
}

class _HarmonicPerceptionListScreenState
    extends State<HarmonicPerceptionListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<Result<List<HarmonicExercise>>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _databaseService.getHarmonicExercises();
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
          title: const Text('Percepção Harmônica'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<Result<List<HarmonicExercise>>>(
          future: _exercisesFuture,
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

            final exercises = result.data;
            if (exercises.isEmpty) {
              return const Center(child: Text('Nenhum exercício encontrado.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ExerciseNodeWidget(
                    title: exercise.title,
                    description: _getDifficultyName(exercise.difficulty),
                    icon: Icons.hearing,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HarmonicPerceptionExerciseScreen(
                                  exercise: exercise)));
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
