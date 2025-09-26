// lib/app/data/models/lesson_model.dart
import 'package:flutter/material.dart';

class Lesson {
  final int id;
  final String title;
  final IconData icon;
  final int order; // CORREÇÃO: A propriedade 'order' foi adicionada de volta.

  Lesson({
    required this.id,
    required this.title,
    required this.icon,
    required this.order, // CORREÇÃO: Adicionada ao construtor.
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      title: map['title'],
      icon: _getIconData(map['icon']),
      order: map['order'], // CORREÇÃO: O 'order' agora é lido do mapa de dados.
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': _getIconName(icon),
      'order': order,
    };
  }
}

String _getIconName(IconData icon) {
  if (icon == Icons.graphic_eq) return 'graphic_eq';
  if (icon == Icons.music_note) return 'music_note';
  if (icon == Icons.show_chart) return 'show_chart';
  if (icon == Icons.hearing) return 'hearing';
  if (icon == Icons.grid_on) return 'grid_on';
  if (icon == Icons.timer) return 'timer';
  if (icon == Icons.vpn_key) return 'vpn_key';
  return 'school';
}

IconData _getIconData(String iconName) {
  switch (iconName) {
    case 'graphic_eq':
      return Icons.graphic_eq;
    case 'music_note':
      return Icons.music_note;
    case 'show_chart':
      return Icons.show_chart;
    case 'hearing':
      return Icons.hearing;
    case 'grid_on':
      return Icons.grid_on;
    case 'timer':
      return Icons.timer;
    case 'vpn_key': // Adicionado para a nova lição
      return Icons.vpn_key;
    default:
      return Icons.school;
  }
}