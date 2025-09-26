// lib/app/presentation/view/ai_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/view/chat_screen.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';

class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('CecilIA'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ferramentas da IA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // --- MODIFICAÇÃO AQUI ---
              _FeatureCard(
                icon: Icons.mic_none_outlined,
                title: 'Transcrever Melodia',
                subtitle:
                    'Grave um áudio com a sua voz ou instrumento e veja a mágica acontecer.',
                // 1. Desativamos a navegação e mostramos uma mensagem.
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Esta funcionalidade estará disponível em breve!'),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                },
                // 2. Passamos o novo parâmetro para alterar a aparência visualmente.
                isAvailable: false,
              ),
              // --- FIM DA MODIFICAÇÃO ---
              const SizedBox(height: 16),
              _FeatureCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat com a CecilIA',
                subtitle:
                    'Tire as suas dúvidas sobre teoria, harmonia, ritmo e muito mais.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  // Novo parâmetro para controlar a aparência de "Em Breve"
  final bool isAvailable;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isAvailable =
        true, // Por defeito, as funcionalidades estão disponíveis
  });

  @override
  Widget build(BuildContext context) {
    // Define a opacidade para dar um ar de "desativado"
    final double opacity = isAvailable ? 1.0 : 0.6;

    return Card(
      // ignore: deprecated_member_use
      color: AppColors.card.withOpacity(0.8),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // Usamos InkWell para o efeito visual de toque
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          // O Opacity envolve o conteúdo para o efeito visual
          opacity: opacity,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            leading: Icon(icon, size: 40, color: AppColors.accent),
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            // Se não estiver disponível, mostra "Em breve...", senão, mostra o subtítulo normal
            subtitle: Text(isAvailable ? subtitle : 'Em breve...',
                style: const TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
