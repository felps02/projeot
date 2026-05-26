import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';

class KPICard extends StatelessWidget {
  final KPIData kpi;
  final IconData icon;
  final Color color;

  const KPICard({
    super.key,
    required this.kpi,
    this.icon = Icons.analytics,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final trendPositive = kpi.variacao >= 0 && kpi.positivo ||
        kpi.variacao < 0 && !kpi.positivo;
    final trendColor = trendPositive ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                if (kpi.variacao != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          kpi.variacao >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: trendColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${kpi.variacao.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              kpi.unidade == '%'
                  ? '${kpi.valor.toStringAsFixed(1)}%'
                  : kpi.valor % 1 == 0
                      ? kpi.valor.toInt().toString()
                      : kpi.valor.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kpi.titulo,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            if (kpi.unidade.isNotEmpty && kpi.unidade != '%') ...[
              const SizedBox(height: 2),
              Text(
                kpi.unidade,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
