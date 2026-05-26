import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/constants.dart';

class LikertScale extends StatelessWidget {
  final int? selectedValue;
  final ValueChanged<int> onSelected;

  const LikertScale({
    super.key,
    this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final value = index + 1;
            final isSelected = selectedValue == value;
            final color = _getScaleColor(value);

            return GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isSelected ? 60 : 52,
                height: isSelected ? 60 : 52,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: isSelected ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: AppConstants.likertLabels.map((label) {
            return SizedBox(
              width: 60,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedValue != null) ...[
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getScaleColor(selectedValue!),
              inactiveTrackColor:
                  _getScaleColor(selectedValue!).withValues(alpha: 0.2),
              thumbColor: _getScaleColor(selectedValue!),
              overlayColor:
                  _getScaleColor(selectedValue!).withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: selectedValue!.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => onSelected(v.round()),
            ),
          ),
        ],
      ],
    );
  }

  Color _getScaleColor(int value) {
    switch (value) {
      case 1:
        return AppTheme.riskLow;
      case 2:
        return const Color(0xFF8BC34A);
      case 3:
        return AppTheme.riskModerate;
      case 4:
        return AppTheme.riskHigh;
      case 5:
        return AppTheme.riskCritical;
      default:
        return Colors.grey;
    }
  }
}
