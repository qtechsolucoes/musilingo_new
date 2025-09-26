// lib/features/practice/presentation/widgets/melodic_input_panel.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/services/sfx_service.dart';

enum AccidentalType { none, sharp, flat }

class MelodicInputPanel extends StatelessWidget {
  final List<String> notePalette;
  final Map<String, String> figurePalette;
  final Map<String, String> restPalette;
  final String selectedNote;
  final String selectedFigure;
  final bool isVerified;
  final Function(String) onNoteSelected;
  final Function(String) onFigureSelected;
  final VoidCallback onAddNote;
  final VoidCallback onAddRest;
  final VoidCallback onVerify;
  final int displayOctave;
  final VoidCallback onOctaveUp;
  final VoidCallback onOctaveDown;
  final AccidentalType currentAccidental;
  final Function(AccidentalType) onAccidentalSelected;

  const MelodicInputPanel({
    super.key,
    required this.notePalette,
    required this.figurePalette,
    required this.restPalette,
    required this.selectedNote,
    required this.selectedFigure,
    required this.isVerified,
    required this.onNoteSelected,
    required this.onFigureSelected,
    required this.onAddNote,
    required this.onAddRest,
    required this.onVerify,
    required this.displayOctave,
    required this.onOctaveUp,
    required this.onOctaveDown,
    required this.currentAccidental,
    required this.onAccidentalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.card, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fileira 1: Notas e Ações Principais
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Teclado de Notas
              Expanded(
                flex: 5,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children:
                      notePalette.map((note) => _buildNoteChip(note)).toList(),
                ),
              ),
              const SizedBox(width: 16),
              // Ações
              ElevatedButton(
                  onPressed: isVerified ? null : onAddNote,
                  child: const Text("Adicionar Nota")),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: isVerified ? null : onAddRest,
                  child: const Text("Adicionar Pausa")),
            ],
          ),
          const SizedBox(height: 8),
          // Fileira 2: Figuras, Oitava, Acidentes e Verificação
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Figuras e Pausas
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...figurePalette.entries.map(
                          (entry) => _buildFigureChip(entry.key, entry.value)),
                      const VerticalDivider(
                        width: 16,
                        indent: 8,
                        endIndent: 8,
                        color: Colors.white24,
                      ),
                      ...restPalette.entries.map(
                          (entry) => _buildFigureChip(entry.key, entry.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Controles
              _buildCompactControls(),
              const SizedBox(width: 16),
              // Botão Verificar
              ElevatedButton(
                onPressed: isVerified ? null : onVerify,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.completed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
                child: const Text('Verificar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteChip(String note) {
    final noteName = note.replaceAll(RegExp(r'[0-9]'), '');
    final isSelected = selectedNote == noteName;
    return ActionChip(
      label: Text(noteName),
      backgroundColor: isSelected ? AppColors.accent : AppColors.primary,
      onPressed: isVerified
          ? null
          : () {
              SfxService.instance.playClick();
              onNoteSelected(note);
            },
    );
  }

  Widget _buildFigureChip(String key, String symbol) {
    final isSelected = selectedFigure == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        label: Text(symbol, style: const TextStyle(fontSize: 24)),
        backgroundColor: isSelected ? AppColors.accent : AppColors.card,
        // --- MUDANÇA AQUI: Aumentado o padding horizontal de 8 para 12 ---
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onPressed: isVerified
            ? null
            : () {
                SfxService.instance.playClick();
                onFigureSelected(key);
              },
      ),
    );
  }

  Widget _buildCompactControls() {
    return Row(
      children: [
        // Controle de Oitava
        Column(
          children: [
            const Text('Oitava',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 20),
                    onPressed: isVerified ? null : onOctaveDown,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
                Text(displayOctave.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    onPressed: isVerified ? null : onOctaveUp,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ],
            ),
          ],
        ),
        const SizedBox(width: 8),
        // Acidentes
        Column(
          children: [
            const Text('Acidente',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Row(
              children: [
                _buildAccidentalButton(AccidentalType.flat, '♭'),
                _buildAccidentalButton(AccidentalType.sharp, '♯'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccidentalButton(AccidentalType type, String symbol) {
    final isSelected = currentAccidental == type;
    return InkWell(
      onTap: isVerified
          ? null
          : () {
              SfxService.instance.playClick();
              onAccidentalSelected(type);
            },
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              // ignore: deprecated_member_use
              ? AppColors.accent.withOpacity(0.5)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(symbol,
            style: TextStyle(
                fontSize: 24,
                color: isSelected ? AppColors.accent : Colors.white)),
      ),
    );
  }
}
