import 'package:flutter/material.dart';
import '../../models/alert_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = Helpers.getAlertColor(alert.nivel);
    final typeIcon = AppConstants.alertIcons[alert.tipo] ?? Icons.info;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: alert.lido ? 1 : 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: levelColor,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: levelColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (alert.nomeUsuario != null)
                          Text(
                            alert.nomeUsuario!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: alert.lido
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5)
                                  : null,
                            ),
                          ),
                        const SizedBox(width: 8),
                        _buildLevelBadge(context, levelColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.descricao,
                      style: TextStyle(
                        fontSize: 13,
                        color: alert.lido
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Helpers.timeAgo(alert.data),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (!alert.lido && onMarkRead != null)
                IconButton(
                  onPressed: onMarkRead,
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  tooltip: 'Marcar como lido',
                ),
              if (!alert.lido)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: levelColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context, Color color) {
    final label = switch (alert.nivel) {
      'info' => 'Info',
      'atencao' => 'Atencao',
      'urgente' => 'Urgente',
      'critico' => 'Critico',
      _ => alert.nivel,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
