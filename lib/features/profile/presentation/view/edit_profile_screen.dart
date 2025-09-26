// lib/features/profile/presentation/view/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
// Import necessário
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/shared/widgets/custom_text_field.dart';
import 'package:provider/provider.dart' as provider;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _specialtyController;
  final _formKey = GlobalKey<FormState>();
// Instância do serviço
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProfile = context.read<UserSession>().currentUser;
    _nameController = TextEditingController(text: userProfile?.fullName ?? '');
    _descriptionController =
        TextEditingController(text: userProfile?.description ?? '');
    _specialtyController =
        TextEditingController(text: userProfile?.specialty ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE ATUALIZAÇÃO IMPLEMENTADA ---
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final user = context.read<UserSession>().currentUser;
    if (user == null) return;

    try {
      if (mounted) {
        // Atualiza a sessão local para refletir as mudanças imediatamente
        await context.read<UserSession>().initializeSession();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppColors.completed,
          ),
        );
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(); // Volta para a tela anterior
      } else {
        throw Exception('Não foi possível atualizar o perfil.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserSession>().currentUser;
    final isTeacher = userProfile?.roleId == 2;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Editar Perfil'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Nome Completo',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O nome não pode estar vazio.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Sobre Mim (Bio)',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.info_outline,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 2),
                    ),
                  ),
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: AppColors.text),
                ),
                if (isTeacher) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _specialtyController,
                    labelText: 'Especialidade (Ex: Piano Clássico)',
                    prefixIcon: Icons.music_note_outlined,
                    keyboardType: TextInputType.text,
                  ),
                ],
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
                    : ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Guardar Alterações',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
