class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';
  static const String apiVersion = '/api/v1';
  static const String apiBase = '$baseUrl$apiVersion';

  // Auth
  static const String login = '$apiBase/auth/login';
  static const String register = '$apiBase/auth/register';
  static const String me = '$apiBase/auth/me';

  // Assessments
  static const String assessments = '$apiBase/avaliacoes';
  static const String todayStatus = '$apiBase/avaliacoes/hoje';
  static const String assessmentHistory = '$apiBase/avaliacoes/historico';
  static const String activeQuestions = '$apiBase/perguntas/ativas';

  // Dashboard
  static const String dashboardResumo = '$apiBase/dashboard/resumo';
  static const String dashboardTrends = '$apiBase/dashboard/tendencias';
  static const String dashboardHeatmap = '$apiBase/dashboard/mapa-calor';
  static const String dashboardKpis = '$apiBase/dashboard/kpis';

  // Team
  static const String team = '$apiBase/equipe';
  static const String teamMember = '$apiBase/equipe/membro';

  // Alerts
  static const String alerts = '$apiBase/alertas';
  static const String alertMarkRead = '$apiBase/alertas/lido';

  // Emergency
  static const String emergency = '$apiBase/emergencias';

  // Reports
  static const String reports = '$apiBase/relatorios';
  static const String reportExport = '$apiBase/relatorios/exportar';

  // Settings
  static const String settings = '$apiBase/configuracoes';

  static const Duration timeout = Duration(seconds: 30);
}
