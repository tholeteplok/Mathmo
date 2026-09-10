import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import 'chunky_button.dart';

class SegmentedPill extends StatelessWidget {
  const SegmentedPill({super.key, required this.labels, required this.selectedIndex, required this.onSelected});
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.colorVanillaCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        border: Border.all(color: AppTheme.darkBorder, width: AppTokens.borderWidthDefault),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: ChunkyButton(
              onPressed: () => onSelected(i),
              backgroundColor: selected ? AppTheme.colorWoodMedium : Colors.transparent,
              borderColor: selected ? AppTheme.colorWoodDark : Colors.transparent,
              shadowColor: selected ? AppTheme.colorWoodDark : Colors.transparent,
              borderWidth: selected ? AppTokens.borderWidthDefault : 0,
              borderRadius: AppTokens.radiusPill,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppTheme.colorTaupe)),
            ),
          );
        }),
      ),
    );
  }
}