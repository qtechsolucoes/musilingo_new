// lib/features/connections/presentation/view/add_teacher_by_code_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/teacher_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/connections/presentation/view/qr_scanner_screen.dart'; // Import da tela do scanner
import 'package:musilingo/shared/widgets/custom_text_field.dart';
import 'package:provider/provider.dart' as provider;

class AddTeacherByCodeScreen extends StatefulWidget {
  const AddTeacherByCodeScreen({super.key});

  @override
  State<AddTeacherByCodeScreen> createState() => _AddTeacherByCodeScreenState();
}

class _AddTeacherByCodeScreenState extends State<AddTeacherByCodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _teacherService = TeacherService();
  bool _isLoading = false;

  Future<void> _connectToTeacher({String? code}) async {
    // Se um código for passado (do QR), usa-o. Senão, usa o do controller.
    final codeToConnect = code ?? _codeController.text;

    if (codeToConnect.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('O código não pode estar vazio.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Valida o formulário apenas se não estivermos a usar um código do QR scanner
    if (code == null && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teacher =
          await _teacherService.connectToTeacherByCode(codeToConnect);

      if (mounted && teacher != null) {
        await context.read<UserSession>().initializeSession();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conectado com sucesso a ${teacher.fullName}!'),
            backgroundColor: AppColors.completed,
          ),
        );
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
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

  // --- NOVA FUNÇÃO PARA LER O QR CODE ---
  Future<void> _scanQRCode() async {
    // Navega para a tela do scanner e aguarda um resultado
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    // Se um código for lido e retornado
    if (result != null && result.isNotEmpty) {
      // Preenche o campo de texto com o código lido
      _codeController.text = result;
      // Tenta conectar-se imediatamente
      await _connectToTeacher(code: result);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Adicionar Professor'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Insira o Código do Professor',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Peça o código ao seu professor para se conectar.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _codeController,
                    labelText: 'Código',
                    prefixIcon: Icons.qr_code_2,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira um código.';
                      }
                      if (value.trim().length != 6) {
                        return 'O código deve ter 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent))
                      : ElevatedButton(
                          onPressed: () =>
                              _connectToTeacher(), // Chamada modificada
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Conectar',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    // --- LIGAÇÃO À NOVA FUNÇÃO ---
                    onPressed: _scanQRCode,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Ler QR Code'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
