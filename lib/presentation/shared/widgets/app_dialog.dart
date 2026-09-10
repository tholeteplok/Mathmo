import 'package:flutter/material.dart';
import 'chunky_card.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.child, this.maxWidth = 360});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ChunkyCard(variant: ChunkyCardVariant.woodBoard, padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), child: child),
      ),
    );
  }
}