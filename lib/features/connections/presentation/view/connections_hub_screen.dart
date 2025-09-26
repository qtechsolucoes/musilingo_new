// lib/features/connections/presentation/view/connections_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/teacher_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/connections/presentation/view/add_teacher_by_code_screen.dart';
import 'package:musilingo/features/connections/presentation/view/teacher_code_screen.dart';
import 'package:musilingo/features/connections/presentation/view/teacher_dashboard_screen.dart';
import 'package:musilingo/features/friends/presentation/view/add_friend_screen.dart';
import 'package:provider/provider.dart' as provider;

class ConnectionsHubScreen extends StatelessWidget {
  const ConnectionsHubScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userSession = context.watch<UserSession>();
    final userProfile = userSession.currentUser;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Conexões'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: userProfile == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : _buildContent(context, userProfile, userSession),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, UserProfile userProfile, UserSession userSession) {
    if (userProfile.roleId == 2) {
      return _buildTeacherHub(context);
    } else {
      return _buildStudentHub(context, userSession);
    }
  }

  Widget _buildTeacherHub(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHubCard(
            context,
            icon: Icons.group,
            title: 'Acompanhar Alunos',
            subtitle: 'Veja o progresso e as estatísticas dos seus alunos.',
            onTap: () => _navigateTo(context, const TeacherDashboardScreen()),
          ),
          const SizedBox(height: 16),
          _buildHubCard(
            context,
            icon: Icons.person_add_alt_1,
            title: 'Adicionar Alunos',
            subtitle: 'Partilhe o seu código para que os alunos se conectem.',
            onTap: () => _navigateTo(context, const TeacherCodeScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHub(BuildContext context, UserSession userSession) {
    final hasTeacher = userSession.currentTeacher != null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (!hasTeacher)
            _buildHubCard(
              context,
              icon: Icons.school,
              title: 'Adicionar Professor',
              subtitle: 'Conecte-se a um professor usando o código dele.',
              onTap: () => _navigateTo(context, const AddTeacherByCodeScreen()),
            ),
          if (hasTeacher)
            _buildCurrentTeacherCard(context, userSession.currentTeacher!),
          const SizedBox(height: 16),
          _buildHubCard(
            context,
            icon: Icons.people_outline,
            title: 'Adicionar Amigos',
            subtitle: 'Encontre e adicione amigos para praticarem juntos.',
            onTap: () {
              _navigateTo(context, const AddFriendScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTeacherCard(BuildContext context, UserProfile teacher) {
    final teacherService = TeacherService();
    final userSession = context.read<UserSession>();

    // ✅ CORREÇÃO: Guardamos a referência ao ScaffoldMessenger ANTES do 'await'.
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Card(
      color: AppColors.card.withAlpha(204),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'O SEU PROFESSOR',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'disconnect') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Desconectar Professor'),
                          content: Text(
                              'Tem a certeza de que se quer desconectar de ${teacher.fullName}?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: const Text('Desconectar'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await teacherService.disconnectFromTeacher();
                          await userSession.initializeSession();
                        } catch (e) {
                          // ✅ CORREÇÃO: Usamos a referência guardada.
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'disconnect',
                      child: ListTile(
                        leading: Icon(Icons.link_off, color: Colors.redAccent),
                        title: Text('Desconectar'),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: teacher.avatarUrl != null
                      ? NetworkImage(teacher.avatarUrl!)
                      : null,
                  child: teacher.avatarUrl == null
                      ? const Icon(Icons.person, size: 24)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    teacher.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      color: AppColors.card.withAlpha(204),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
