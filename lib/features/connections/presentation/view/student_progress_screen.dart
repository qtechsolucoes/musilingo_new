// lib/features/connections/presentation/view/student_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/teacher_service.dart';
import 'package:intl/intl.dart';

class StudentProgressScreen extends StatefulWidget {
  final UserProfile student;
  const StudentProgressScreen({super.key, required this.student});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final _teacherService = TeacherService();
  late Future<List<Map<String, dynamic>>> _completedLessonsFuture;

  @override
  void initState() {
    super.initState();
    _completedLessonsFuture =
        _teacherService.getStudentCompletedLessons(widget.student.id);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.student.fullName),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildCompletedLessonsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: widget.student.avatarUrl != null
                ? NetworkImage(widget.student.avatarUrl!)
                : null,
            child: widget.student.avatarUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            widget.student.fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Liga: ${widget.student.league}',
            style:
                const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      // ✅ CORREÇÃO: Diminuído o childAspectRatio para dar mais altura aos cartões
      childAspectRatio: 1.8, // Era 2.5, agora é 1.8 (mais altura)
      children: [
        _buildStatCard(
            'Pontos', widget.student.points.toString(), Icons.star_border),
        _buildStatCard(
            'Vidas', widget.student.lives.toString(), Icons.favorite_border),
        _buildStatCard('Acertos', widget.student.correctAnswers.toString(),
            Icons.check_circle_outline),
        _buildStatCard('Erros', widget.student.wrongAnswers.toString(),
            Icons.highlight_off),
        _buildStatCard('Ofensiva', '${widget.student.currentStreak} dias',
            Icons.local_fire_department_outlined),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: AppColors.card.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ CORREÇÃO: Usando Flexible para evitar overflow
          Flexible(
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ✅ CORREÇÃO: Usando Flexible também para o valor
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 18, // Diminuído de 20 para 18
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedLessonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lições Concluídas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _completedLessonsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text(
                  'Não foi possível carregar o histórico de lições.');
            }
            final lessons = snapshot.data!;
            if (lessons.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Este aluno ainda não completou nenhuma lição.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lessonData = lessons[index];
                final title =
                    lessonData['lessons']?['title'] ?? 'Lição desconhecida';
                final completedAt = DateTime.parse(lessonData['completed_at']);
                final formattedDate =
                    DateFormat('dd/MM/yyyy').format(completedAt);

                return Card(
                  // ignore: deprecated_member_use
                  color: AppColors.card.withOpacity(0.5),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle,
                        color: AppColors.completed),
                    title: Text(title),
                    subtitle: Text('Concluída em: $formattedDate'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
