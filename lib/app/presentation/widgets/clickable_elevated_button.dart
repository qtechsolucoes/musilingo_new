// lib/app/presentation/widgets/clickable_elevated_button.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/services/sfx_service.dart';

class ClickableElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const ClickableElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              // *** A MÁGICA ACONTECE AQUI: O SOM É TOCADO AUTOMATICAMENTE ***
              SfxService.instance.playClick();
              onPressed!();
            },
      style: style,
      child: child,
    );
  }
}
