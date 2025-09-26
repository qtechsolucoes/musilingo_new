// lib/features/connections/presentation/view/teacher_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/teacher_service.dart';
import 'package:musilingo/features/connections/presentation/view/student_progress_screen.dart'; // 1. Importar a tela de detalhes

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final _teacherService = TeacherService();
  late Future<List<UserProfile>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _teacherService.getStudents();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Meus Alunos'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<List<UserProfile>>(
          future: _studentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Não foi possível carregar os seus alunos.'));
            }
            final students = snapshot.data ?? [];
            if (students.isEmpty) {
              return const Center(
                child: Text(
                  'Ainda nenhum aluno o adicionou.',
                  style:
                      TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
              );
            }
            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  // ignore: deprecated_member_use
                  color: AppColors.card.withOpacity(0.8),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: student.avatarUrl != null
                          ? NetworkImage(student.avatarUrl!)
                          : null,
                      child: student.avatarUrl == null
                          ? const Icon(Icons.person, size: 25)
                          : null,
                    ),
                    title: Text(
                      student.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      '${student.points} Pontos | ${student.currentStreak} Dias de Ofensiva',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: AppColors.textSecondary),
                    onTap: () {
                      // --- MODIFICAÇÃO AQUI ---
                      // 2. Navega para a tela de progresso do aluno, passando o perfil do aluno selecionado.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentProgressScreen(student: student),
                        ),
                      );
                      // --- FIM DA MODIFICAÇÃO ---
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
