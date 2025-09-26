import 'package:flutter/material.dart';
import 'dart:math' as math;

class MetronomeWidget extends StatefulWidget {
  final bool isActive;
  final int tempo;
  final int currentBeat;
  final int beatsPerMeasure;

  const MetronomeWidget({
    super.key,
    required this.isActive,
    required this.tempo,
    required this.currentBeat,
    this.beatsPerMeasure = 4,
  });

  @override
  State<MetronomeWidget> createState() => _MetronomeWidgetState();
}

class _MetronomeWidgetState extends State<MetronomeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    final duration = Duration(milliseconds: (60000 / widget.tempo).round());

    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -math.pi / 6,
      end: math.pi / 6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MetronomeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tempo != oldWidget.tempo) {
      final duration = Duration(milliseconds: (60000 / widget.tempo).round());
      _controller.duration = duration;
    }

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A2A3E),
            Color(0xFF1E1E2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Marcadores de batida
          ...List.generate(widget.beatsPerMeasure, (index) {
            final angle =
                (index * 2 * math.pi / widget.beatsPerMeasure) - math.pi / 2;
            final isCurrentBeat = widget.currentBeat == index + 1;

            return Transform(
              transform: Matrix4.identity()
                ..translate(
                  80 * math.cos(angle),
                  80 * math.sin(angle),
                ),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrentBeat
                      ? const Color(0xFFFFD700)
                      : Colors.white.withValues(alpha: 0.3),
                  boxShadow: isCurrentBeat
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),

          // Pêndulo
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 4,
                  height: 100,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),

          // Centro
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),

          // Tempo display
          Positioned(
            bottom: 30,
            child: Text(
              '${widget.tempo} BPM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
