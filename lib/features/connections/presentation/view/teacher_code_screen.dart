// lib/features/connections/presentation/view/teacher_code_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/teacher_service.dart'; // Vamos precisar de o atualizar
import 'package:musilingo/app/services/user_session.dart';
import 'package:provider/provider.dart' as provider;
import 'package:qr_flutter/qr_flutter.dart';

class TeacherCodeScreen extends StatefulWidget {
  const TeacherCodeScreen({super.key});

  @override
  State<TeacherCodeScreen> createState() => _TeacherCodeScreenState();
}

class _TeacherCodeScreenState extends State<TeacherCodeScreen> {
  final _teacherService = TeacherService();
  String? _teacherCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrGenerateTeacherCode();
  }

  Future<void> _fetchOrGenerateTeacherCode() async {
    final userProfile = context.read<UserSession>().currentUser;
    if (userProfile == null) return;

    // A lógica para obter/gerar o código estará no TeacherService
    final code = await _teacherService.getOrGenerateTeacherCode(userProfile.id);

    if (mounted) {
      setState(() {
        _teacherCode = code;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Adicionar Alunos'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: AppColors.accent)
              : _teacherCode == null
                  ? const Text(
                      'Não foi possível gerar o seu código de professor.')
                  : _buildCodeDisplay(),
        ),
      ),
    );
  }

  Widget _buildCodeDisplay() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Partilhe este QR Code ou o código abaixo com os seus alunos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: _teacherCode!,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'O SEU CÓDIGO DE PROFESSOR',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _teacherCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Código copiado para a área de transferência!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: AppColors.card.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _teacherCode!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.copy,
                      color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
