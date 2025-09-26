// lib/app/presentation/widgets/time_signature_widget.dart

import 'package:flutter/material.dart';

class TimeSignatureWidget extends StatelessWidget {
  final int top;
  final int bottom;
  final TextStyle style;

  const TimeSignatureWidget({
    super.key,
    required this.top,
    required this.bottom,
    this.style = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(top.toString(), style: style),
        const SizedBox(height: 4),
        Text(bottom.toString(), style: style),
      ],
    );
  }
}
