// lib/app/presentation/widgets/cecilia_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musilingo/app/controllers/agent_controller.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';

class CeciliaWidget extends StatelessWidget {
  final String svgUrl;
  final AgentState state;

  const CeciliaWidget({
    super.key,
    required this.svgUrl,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Definindo um tamanho fixo e pequeno para o widget.
    return SizedBox(
      width: 40, // Largura fixa
      height: 40, // Altura fixa
      child: SvgPicture.network(
        svgUrl,
        placeholderBuilder: (BuildContext context) =>
            const CircularProgressIndicator(
          strokeWidth: 2.0,
          color: AppColors.accent,
        ),
        // Builder de erro para não quebrar o app se a imagem não carregar.
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.error_outline, color: AppColors.error, size: 30),
      ),
    );
  }
}
