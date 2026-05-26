import 'package:flutter/material.dart';
import '../../config/theme.dart';

class QuickSelect extends StatelessWidget {
  final int? selectedValue;
  final ValueChanged<int> onSelected;
  final List<QuickSelectOption>? options;

  const QuickSelect({
    super.key,
    this.selectedValue,
    required this.onSelected,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final items = options ??
        [
          const QuickSelectOption(value: 1, label: 'Sim', icon: Icons.check_circle),
          const QuickSelectOption(value: 5, label: 'Nao', icon: Icons.cancel),
        ];

    return Row(
      children: items.map((option) {
        final isSelected = selectedValue == option.value;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => onSelected(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getOptionColor(option.value).withValues(alpha: 0.15)
                      : Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _getOptionColor(option.value)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _getOptionColor(option.value)
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        option.icon,
                        size: 40,
                        color: isSelected
                            ? _getOptionColor(option.value)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? _getOptionColor(option.value)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getOptionColor(int value) {
    if (value <= 2) return AppTheme.riskLow;
    if (value <= 3) return AppTheme.riskModerate;
    return AppTheme.riskCritical;
  }
}

class QuickSelectOption {
  final int value;
  final String label;
  final IconData icon;

  const QuickSelectOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
