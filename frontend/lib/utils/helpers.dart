import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class Helpers {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  static String formatDateFull(DateTime date) {
    return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM', 'pt_BR').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'pt_BR').format(date);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static String getFirstName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  static Color getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return AppConstants.colorRiskLow;
      case 'moderado':
        return AppConstants.colorRiskModerate;
      case 'alto':
        return AppConstants.colorRiskHigh;
      case 'critico':
        return AppConstants.colorRiskCritical;
      default:
        return Colors.grey;
    }
  }

  static String getRiskLabel(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return 'Baixo';
      case 'moderado':
        return 'Moderado';
      case 'alto':
        return 'Alto';
      case 'critico':
        return 'Critico';
      default:
        return 'Desconhecido';
    }
  }

  static IconData getRiskIcon(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return Icons.check_circle;
      case 'moderado':
        return Icons.info;
      case 'alto':
        return Icons.warning;
      case 'critico':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return 'Ha ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Ha ${diff.inHours}h';
    if (diff.inDays < 7) return 'Ha ${diff.inDays}d';
    return formatDate(date);
  }

  static Color getAlertColor(String nivel) {
    return AppConstants.alertLevelColors[nivel] ?? Colors.grey;
  }

  static String formatPercent(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String formatScore(double value) {
    return value.toStringAsFixed(1);
  }

  static double scoreFromAnswers(List<int> values) {
    if (values.isEmpty) return 0;
    final total = values.fold<int>(0, (sum, v) => sum + v);
    return (total / (values.length * 5)) * 100;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String getDayOfWeekShort(int weekday) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    return days[(weekday - 1) % 7];
  }

  static String getMonthName(int month) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[(month - 1) % 12];
  }
}
