import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart'; // Import necessário
import 'package:musilingo/app/services/sfx_service.dart';
import 'package:musilingo/features/duel/presentation/view/duel_lobby_screen.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AJUSTE 1: O Scaffold agora está dentro do nosso GradientBackground
    // e com o fundo transparente para que o gradiente apareça.
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Desafios'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    SfxService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DuelLobbyScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    // AJUSTE 2: A decoração foi alterada para usar a cor sólida
                    // AppColors.card, padronizando com a tela de Prática.
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    // FIM DO AJUSTE
                    child: Column(
                      children: [
                        Text(
                          'Duelo dos Mestres',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'desafie outro musico em um quiz em tempo real!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              // ignore: deprecated_member_use
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
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
