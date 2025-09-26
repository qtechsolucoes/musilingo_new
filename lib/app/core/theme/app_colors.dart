// lib/app/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Cores da nova paleta
  static const Color background = Color(0xFF0f0f2d);
  static const Color primary = Color(0xFF4a47a3);
  static const Color completed = Color(0xFF00a896);
  static const Color accent = Color(0xFFf0c419);

  // --- CORES ANTIGAS ADICIONADAS DE VOLTA ---
  static const Color text = Colors.white;
  static const Color textSecondary = Color(0xFFaeb2b7);
  static const Color card = Color(0xFF1c1c3c);

  // --- CORES NOVAS PARA FEEDBACK ---
  static const Color error = Color(0xFFD32F2F); // Vermelho para erros e modais

  // Cores em formato String (Hex) para usar no JavaScript do WebView
  static const String completedHex = '#4CAF50'; // Verde para notas corretas
  static const String errorHex = '#F44336'; // Vermelho para notas incorretas
}
