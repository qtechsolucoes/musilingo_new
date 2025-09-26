import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/features/home/presentation/widgets/lesson_node_widget.dart';
import 'package:flutter/foundation.dart';

class WorldWidget extends StatefulWidget {
  final Module module;
  final List<Lesson> allLessons;
  final Set<int> completedLessonIds;
  final bool isFirstModule;
  final bool isLastModule;
  final PageController pageController;
  final VoidCallback onLessonCompleted;

  const WorldWidget({
    super.key,
    required this.module,
    required this.allLessons,
    required this.completedLessonIds,
    required this.isFirstModule,
    required this.isLastModule,
    required this.pageController,
    required this.onLessonCompleted,
  });

  @override
  State<WorldWidget> createState() => _WorldWidgetState();
}

class _WorldWidgetState extends State<WorldWidget> {
  late Map<int, GlobalKey> _lessonKeys;
  List<Offset> _nodePositions = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _lessonKeys = {
      for (var lesson in widget.module.lessons) lesson.id: GlobalKey()
    };
    _scrollController.addListener(_calculateNodePositions);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _calculateNodePositions());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_calculateNodePositions);
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateNodePositions() {
    final positions = <Offset>[];
    final scrollableBox = context.findRenderObject() as RenderBox?;
    if (scrollableBox == null) return;

    for (var lesson in widget.module.lessons) {
      final key = _lessonKeys[lesson.id];
      if (key?.currentContext != null) {
        final renderBox = key!.currentContext!.findRenderObject() as RenderBox;
        final position =
            renderBox.localToGlobal(Offset.zero, ancestor: scrollableBox);
        positions.add(renderBox.size.center(position));
      }
    }
    if (mounted && !listEquals(_nodePositions, positions)) {
      setState(() {
        _nodePositions = positions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.background, Color(0xFF1E2A3E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PathPainter(
                nodePositions: _nodePositions,
              ),
            ),
          ),
          _buildModuleContent(),
          if (!widget.isFirstModule) _buildNavigationArrow(isLeft: true),
          if (!widget.isLastModule) _buildNavigationArrow(isLeft: false),
        ],
      ),
    );
  }

  Widget _buildModuleContent() {
    return NotificationListener<LayoutChangedNotification>(
      onNotification: (notification) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _calculateNodePositions());
        return true;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 20.0),
          child: Column(
            children: [
              Text(
                widget.module.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10.0, color: AppColors.accent)],
                ),
              ),
              const SizedBox(height: 30),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.module.lessons.length,
                itemBuilder: (context, index) {
                  final lesson = widget.module.lessons[index];
                  final isCompleted =
                      widget.completedLessonIds.contains(lesson.id);
                  bool isLocked = true;
                  final globalLessonIndex =
                      widget.allLessons.indexWhere((l) => l.id == lesson.id);

                  if (globalLessonIndex == 0) {
                    isLocked = false;
                  } else if (globalLessonIndex > 0) {
                    final previousLesson =
                        widget.allLessons[globalLessonIndex - 1];
                    if (widget.completedLessonIds.contains(previousLesson.id)) {
                      isLocked = false;
                    }
                  }

                  return IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (index % 2 == 0) const Spacer(flex: 2),
                        LessonNodeWidget(
                          key: _lessonKeys[lesson.id],
                          lesson: lesson,
                          isCompleted: isCompleted,
                          isLocked: isLocked,
                          onLessonCompleted: widget.onLessonCompleted,
                        ),
                        if (index % 2 != 0) const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrow({required bool isLeft}) {
    return Positioned(
      left: isLeft ? 16 : null,
      right: isLeft ? null : 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: IconButton(
          icon: Icon(isLeft ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
              color: Colors.white, size: 30),
          onPressed: () {
            if (isLeft) {
              widget.pageController.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut);
            } else {
              widget.pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut);
            }
          },
        ),
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final double nodeRadius = 35.0;
  final double cornerRadius = 30.0;
  final double strokeWidth = 8.0;
  final double verticalOffset = -20.0;

  PathPainter({required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) {
      return;
    }

    // AJUSTE REALIZADO AQUI
    // A cor foi alterada de AppColors.primary para um branco semitransparente
    // para uma melhor integração visual com o fundo gradiente.
    final paint = Paint()
      // ignore: deprecated_member_use
      ..color = Colors.white.withOpacity(0.4) // Cor da linha alterada
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // FIM DO AJUSTE

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final startOffset = nodePositions[i];
      final endOffset = nodePositions[i + 1];
      final bool isMovingRight = endOffset.dx > startOffset.dx;
      final path = Path();
      final startPoint = Offset(
          startOffset.dx + (isMovingRight ? nodeRadius : -nodeRadius),
          startOffset.dy + verticalOffset);
      final endPoint = Offset(endOffset.dx, endOffset.dy - nodeRadius);
      path.moveTo(startPoint.dx, startPoint.dy);
      final horizontalLineEndX =
          endPoint.dx + (isMovingRight ? -cornerRadius : cornerRadius);
      path.lineTo(horizontalLineEndX, startPoint.dy);
      final arcEndPoint = Offset(endPoint.dx, startPoint.dy + cornerRadius);
      path.arcToPoint(
        arcEndPoint,
        radius: Radius.circular(cornerRadius),
        clockwise: isMovingRight,
      );
      path.lineTo(endPoint.dx, endPoint.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
