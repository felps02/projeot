import 'package:flutter/material.dart';

class AppConstants {
  // App
  static const String appName = 'Psicossocial';
  static const String appVersion = '1.0.0';

  // Risk levels
  static const String riskLow = 'baixo';
  static const String riskModerate = 'moderado';
  static const String riskHigh = 'alto';
  static const String riskCritical = 'critico';

  // Risk colors
  static const Color colorRiskLow = Color(0xFF4CAF50);
  static const Color colorRiskModerate = Color(0xFFFFC107);
  static const Color colorRiskHigh = Color(0xFFFF9800);
  static const Color colorRiskCritical = Color(0xFFF44336);

  // Profile types
  static const String profileEmployee = 'funcionario';
  static const String profileLeader = 'lider';

  // Assessment types
  static const String typeEmoji = 'emoji';
  static const String typeLikert = 'likert';
  static const String typeYesNo = 'sim_nao';

  // Categories
  static const String catEmotional = 'emocional';
  static const String catStress = 'estresse';
  static const String catEnvironment = 'ambiente';
  static const String catRelationship = 'relacionamento';
  static const String catGeneral = 'geral';

  // Emoji labels
  static const List<String> emojiOptions = [
    '\u{1F622}', // Crying
    '\u{1F615}', // Confused
    '\u{1F610}', // Neutral
    '\u{1F642}', // Slightly smiling
    '\u{1F604}', // Grinning
  ];

  static const List<String> emojiLabels = [
    'Muito mal',
    'Mal',
    'Neutro',
    'Bem',
    'Muito bem',
  ];

  // Likert labels
  static const List<String> likertLabels = [
    'Muito baixo',
    'Baixo',
    'Moderado',
    'Alto',
    'Muito alto',
  ];

  // Alert types
  static const Map<String, IconData> alertIcons = {
    'risco_alto': Icons.warning_amber_rounded,
    'emergencia': Icons.emergency,
    'ausencia': Icons.person_off,
    'tendencia': Icons.trending_up,
  };

  static const Map<String, String> alertTypeLabels = {
    'risco_alto': 'Risco Alto',
    'emergencia': 'Emergencia',
    'ausencia': 'Ausencia',
    'tendencia': 'Tendencia',
  };

  static const Map<String, Color> alertLevelColors = {
    'info': Color(0xFF2196F3),
    'atencao': Color(0xFFFFC107),
    'urgente': Color(0xFFFF9800),
    'critico': Color(0xFFF44336),
  };

  // Emergency motivos
  static const List<String> emergencyMotivos = [
    'Crise emocional',
    'Assedio',
    'Colapso psicologico',
    'Situacao urgente',
  ];

  // Strings
  static const String greeting = 'Ola';
  static const String dailyCheckinTitle = 'Check-in Diario';
  static const String dailyCheckinSubtitle =
      'Como voce esta se sentindo hoje?';
  static const String dailyCheckinDone =
      'Voce ja realizou sua avaliacao de hoje!';
  static const String assessmentComplete = 'Avaliacao concluida!';
  static const String assessmentThankYou =
      'Obrigado por compartilhar como voce esta.';
  static const String emergencyTitle = 'Emergencia';
  static const String emergencyConfirm =
      'Tem certeza que deseja enviar um alerta de emergencia?';
  static const String emergencySuccess =
      'Seu alerta foi enviado. Alguem da equipe de apoio entrara em contato em breve.';
  static const String emergencySupportMessage =
      'Voce nao esta sozinho. Ligue 188 (CVV) para apoio imediato.';
  static const String loginTitle = 'Entrar';
  static const String registerTitle = 'Criar Conta';
  static const String logoutConfirm = 'Deseja realmente sair?';
  static const String errorGeneric =
      'Ocorreu um erro. Tente novamente mais tarde.';
  static const String noData = 'Nenhum dado disponivel';
  static const String retry = 'Tentar novamente';
  static const String loading = 'Carregando...';

  // Dashboard strings
  static const String dashboardTitle = 'Painel de Gestao';
  static const String teamTitle = 'Equipe';
  static const String reportsTitle = 'Relatorios';
  static const String alertsTitle = 'Alertas';
  static const String heatmapTitle = 'Mapa de Calor';
  static const String settingsTitle = 'Configuracoes';
}
