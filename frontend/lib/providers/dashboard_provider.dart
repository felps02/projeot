import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/dashboard_data.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  DashboardResumo _resumo = DashboardResumo();
  List<TendenciaData> _tendencias = [];
  List<HeatmapData> _heatmapData = [];
  List<KPIData> _kpis = [];
  List<AlertModel> _alerts = [];
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = false;
  String? _errorMessage;

  DashboardResumo get resumo => _resumo;
  List<TendenciaData> get tendencias => _tendencias;
  List<HeatmapData> get heatmapData => _heatmapData;
  List<KPIData> get kpis => _kpis;
  List<AlertModel> get alerts => _alerts;
  List<Map<String, dynamic>> get teamMembers => _teamMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadAlerts => _alerts.where((a) => !a.lido).length;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConfig.dashboardResumo);
      if (response.success && response.data != null) {
        _resumo = DashboardResumo.fromJson(response.data);
      } else {
        _resumo = DashboardResumo.sample();
      }

      await Future.wait([
        loadTrends(),
        loadAlerts(),
        loadKPIs(),
      ]);
    } catch (e) {
      _resumo = DashboardResumo.sample();
      _tendencias = TendenciaData.sampleData();
      _kpis = KPIData.sampleData();
      _errorMessage = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTrends() async {
    try {
      final response = await _api.get(ApiConfig.dashboardTrends);
      if (response.success && response.data != null) {
        final list = response.data as List;
        _tendencias = list.map((item) => TendenciaData.fromJson(item)).toList();
      } else {
        _tendencias = TendenciaData.sampleData();
      }
    } catch (_) {
      _tendencias = TendenciaData.sampleData();
    }
  }

  Future<void> loadHeatmap() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConfig.dashboardHeatmap);
      if (response.success && response.data != null) {
        final list = response.data as List;
        _heatmapData = list.map((item) => HeatmapData.fromJson(item)).toList();
      } else {
        _heatmapData = HeatmapData.sampleData();
      }
    } catch (_) {
      _heatmapData = HeatmapData.sampleData();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadKPIs() async {
    try {
      final response = await _api.get(ApiConfig.dashboardKpis);
      if (response.success && response.data != null) {
        final list = response.data as List;
        _kpis = list.map((item) => KPIData.fromJson(item)).toList();
      } else {
        _kpis = KPIData.sampleData();
      }
    } catch (_) {
      _kpis = KPIData.sampleData();
    }
  }

  Future<void> loadAlerts() async {
    try {
      final response = await _api.get(ApiConfig.alerts);
      if (response.success && response.data != null) {
        final list = response.data as List;
        _alerts = list.map((item) => AlertModel.fromJson(item)).toList();
      } else {
        _alerts = _generateSampleAlerts();
      }
    } catch (_) {
      _alerts = _generateSampleAlerts();
    }
  }

  Future<void> loadTeam() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConfig.team);
      if (response.success && response.data != null) {
        _teamMembers = List<Map<String, dynamic>>.from(response.data);
      } else {
        _teamMembers = _generateSampleTeam();
      }
    } catch (_) {
      _teamMembers = _generateSampleTeam();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _api.put('${ApiConfig.alertMarkRead}/$alertId');
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(lido: true);
        notifyListeners();
      }
    } catch (_) {
      // Silent fail
    }
  }

  List<AlertModel> _generateSampleAlerts() {
    final now = DateTime.now();
    return [
      AlertModel(
        id: '1',
        usuarioId: 'u1',
        tipo: 'risco_alto',
        nivel: 'urgente',
        descricao: 'Funcionario apresentou score de risco elevado por 3 dias consecutivos',
        data: now.subtract(const Duration(hours: 2)),
        nomeUsuario: 'Maria Silva',
      ),
      AlertModel(
        id: '2',
        usuarioId: 'u2',
        tipo: 'emergencia',
        nivel: 'critico',
        descricao: 'Alerta de emergencia acionado - Crise emocional',
        data: now.subtract(const Duration(hours: 5)),
        nomeUsuario: 'Joao Santos',
      ),
      AlertModel(
        id: '3',
        usuarioId: 'u3',
        tipo: 'ausencia',
        nivel: 'atencao',
        descricao: 'Funcionario nao realizou check-in por 5 dias',
        data: now.subtract(const Duration(days: 1)),
        nomeUsuario: 'Ana Costa',
      ),
      AlertModel(
        id: '4',
        usuarioId: 'u4',
        tipo: 'tendencia',
        nivel: 'info',
        descricao: 'Tendencia de aumento de estresse no setor Vendas',
        data: now.subtract(const Duration(days: 2)),
        nomeUsuario: 'Setor Vendas',
      ),
      AlertModel(
        id: '5',
        usuarioId: 'u5',
        tipo: 'risco_alto',
        nivel: 'urgente',
        descricao: 'Score de risco passou de moderado para alto',
        data: now.subtract(const Duration(days: 1)),
        nomeUsuario: 'Carlos Oliveira',
        lido: true,
      ),
    ];
  }

  List<Map<String, dynamic>> _generateSampleTeam() {
    return [
      {'nome': 'Maria Silva', 'setor': 'Vendas', 'ultimoCheckin': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(), 'scoreRisco': 45.0, 'nivelRisco': 'moderado', 'status': 'ativo'},
      {'nome': 'Joao Santos', 'setor': 'Caixa', 'ultimoCheckin': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(), 'scoreRisco': 72.0, 'nivelRisco': 'alto', 'status': 'ativo'},
      {'nome': 'Ana Costa', 'setor': 'Atendimento', 'ultimoCheckin': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(), 'scoreRisco': 30.0, 'nivelRisco': 'moderado', 'status': 'inativo'},
      {'nome': 'Carlos Oliveira', 'setor': 'Estoque', 'ultimoCheckin': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(), 'scoreRisco': 15.0, 'nivelRisco': 'baixo', 'status': 'ativo'},
      {'nome': 'Paula Ferreira', 'setor': 'Vendas', 'ultimoCheckin': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(), 'scoreRisco': 85.0, 'nivelRisco': 'critico', 'status': 'ativo'},
      {'nome': 'Roberto Lima', 'setor': 'Logistica', 'ultimoCheckin': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(), 'scoreRisco': 22.0, 'nivelRisco': 'baixo', 'status': 'ativo'},
      {'nome': 'Lucia Mendes', 'setor': 'Caixa', 'ultimoCheckin': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(), 'scoreRisco': 55.0, 'nivelRisco': 'alto', 'status': 'ativo'},
      {'nome': 'Fernando Alves', 'setor': 'Gerencia', 'ultimoCheckin': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(), 'scoreRisco': 10.0, 'nivelRisco': 'baixo', 'status': 'ativo'},
    ];
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
