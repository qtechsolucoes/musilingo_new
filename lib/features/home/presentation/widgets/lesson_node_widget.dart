// lib/features/home/presentation/widgets/lesson_node_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/services/sfx_service.dart';
import 'package:musilingo/features/lesson/presentation/view/lesson_screen.dart';

enum NodePosition { start, middle, end }

class LessonNodeWidget extends StatelessWidget {
  final Lesson lesson;
  final bool isCompleted;
  final bool isLocked;
  final NodePosition position;
  final VoidCallback? onLessonCompleted;

  // --- ADIÇÃO ---
  // A key nos permitirá identificar este widget na árvore de widgets.
  const LessonNodeWidget({
    super.key, // O super.key já faz o trabalho de uma GlobalKey quando fornecida.
    required this.lesson,
    required this.isCompleted,
    required this.isLocked,
    this.position = NodePosition.middle,
    this.onLessonCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Color nodeColor;
    IconData nodeIcon;

    if (isLocked) {
      nodeColor = AppColors.card;
      nodeIcon = Icons.lock;
    } else if (isCompleted) {
      nodeColor = AppColors.completed;
      nodeIcon = Icons.check;
    } else {
      nodeColor = AppColors.accent;
      nodeIcon = Icons.play_arrow;
    }

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              SfxService.instance.playClick();
              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonScreen(lesson: lesson),
                ),
              ).then((completed) {
                if (completed == true && onLessonCompleted != null) {
                  onLessonCompleted!();
                }
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: nodeColor,
                border: Border.all(
                  color: isLocked ? Colors.grey.shade700 : nodeColor,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: nodeColor.withAlpha(128),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(nodeIcon,
                  color: isLocked ? Colors.grey.shade400 : Colors.white,
                  size: 35),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 90,
              child: Text(
                lesson.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isLocked ? Colors.grey.shade500 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
