class DashboardResumo {
  final int totalFuncionarios;
  final double taxaParticipacao;
  final Map<String, int> distribuicaoRisco;
  final int alertasAtivos;
  final double scoreMedio;

  DashboardResumo({
    this.totalFuncionarios = 0,
    this.taxaParticipacao = 0.0,
    this.distribuicaoRisco = const {},
    this.alertasAtivos = 0,
    this.scoreMedio = 0.0,
  });

  factory DashboardResumo.fromJson(Map<String, dynamic> json) {
    final dist = json['distribuicaoRisco'];
    Map<String, int> distribuicao = {};
    if (dist is Map) {
      dist.forEach((key, value) {
        distribuicao[key.toString()] = (value as num).toInt();
      });
    }
    return DashboardResumo(
      totalFuncionarios: json['totalFuncionarios'] ?? 0,
      taxaParticipacao: (json['taxaParticipacao'] ?? 0).toDouble(),
      distribuicaoRisco: distribuicao,
      alertasAtivos: json['alertasAtivos'] ?? 0,
      scoreMedio: (json['scoreMedio'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFuncionarios': totalFuncionarios,
      'taxaParticipacao': taxaParticipacao,
      'distribuicaoRisco': distribuicaoRisco,
      'alertasAtivos': alertasAtivos,
      'scoreMedio': scoreMedio,
    };
  }

  static DashboardResumo sample() {
    return DashboardResumo(
      totalFuncionarios: 150,
      taxaParticipacao: 78.5,
      distribuicaoRisco: {
        'baixo': 85,
        'moderado': 40,
        'alto': 18,
        'critico': 7,
      },
      alertasAtivos: 12,
      scoreMedio: 35.2,
    );
  }
}

class TendenciaData {
  final DateTime data;
  final double score;
  final int participantes;

  TendenciaData({
    required this.data,
    required this.score,
    this.participantes = 0,
  });

  factory TendenciaData.fromJson(Map<String, dynamic> json) {
    return TendenciaData(
      data: DateTime.parse(json['data']),
      score: (json['score'] ?? 0).toDouble(),
      participantes: json['participantes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toIso8601String(),
      'score': score,
      'participantes': participantes,
    };
  }

  static List<TendenciaData> sampleData() {
    final now = DateTime.now();
    return List.generate(30, (i) {
      return TendenciaData(
        data: now.subtract(Duration(days: 29 - i)),
        score: 25.0 + (i % 7) * 5.0 + (i * 0.3),
        participantes: 100 + (i % 10) * 5,
      );
    });
  }
}

class HeatmapData {
  final String setor;
  final double score;
  final int funcionarios;
  final String nivel;

  HeatmapData({
    required this.setor,
    required this.score,
    required this.funcionarios,
    required this.nivel,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      setor: json['setor'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      funcionarios: json['funcionarios'] ?? 0,
      nivel: json['nivel'] ?? 'baixo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setor': setor,
      'score': score,
      'funcionarios': funcionarios,
      'nivel': nivel,
    };
  }

  static List<HeatmapData> sampleData() {
    return [
      HeatmapData(setor: 'Vendas', score: 32.0, funcionarios: 25, nivel: 'moderado'),
      HeatmapData(setor: 'Caixa', score: 55.0, funcionarios: 18, nivel: 'alto'),
      HeatmapData(setor: 'Estoque', score: 20.0, funcionarios: 12, nivel: 'baixo'),
      HeatmapData(setor: 'Atendimento', score: 68.0, funcionarios: 30, nivel: 'alto'),
      HeatmapData(setor: 'Gerencia', score: 15.0, funcionarios: 8, nivel: 'baixo'),
      HeatmapData(setor: 'Logistica', score: 45.0, funcionarios: 15, nivel: 'moderado'),
      HeatmapData(setor: 'Marketing', score: 28.0, funcionarios: 10, nivel: 'moderado'),
      HeatmapData(setor: 'RH', score: 12.0, funcionarios: 6, nivel: 'baixo'),
      HeatmapData(setor: 'Financeiro', score: 38.0, funcionarios: 8, nivel: 'moderado'),
      HeatmapData(setor: 'TI', score: 42.0, funcionarios: 10, nivel: 'moderado'),
      HeatmapData(setor: 'Limpeza', score: 72.0, funcionarios: 14, nivel: 'critico'),
      HeatmapData(setor: 'Seguranca', score: 50.0, funcionarios: 12, nivel: 'alto'),
    ];
  }
}

class KPIData {
  final String titulo;
  final double valor;
  final double variacao;
  final String unidade;
  final bool positivo;

  KPIData({
    required this.titulo,
    required this.valor,
    this.variacao = 0.0,
    this.unidade = '',
    this.positivo = true,
  });

  factory KPIData.fromJson(Map<String, dynamic> json) {
    return KPIData(
      titulo: json['titulo'] ?? '',
      valor: (json['valor'] ?? 0).toDouble(),
      variacao: (json['variacao'] ?? 0).toDouble(),
      unidade: json['unidade'] ?? '',
      positivo: json['positivo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'valor': valor,
      'variacao': variacao,
      'unidade': unidade,
      'positivo': positivo,
    };
  }

  static List<KPIData> sampleData() {
    return [
      KPIData(titulo: 'Total Funcionarios', valor: 150, variacao: 3.2, unidade: '', positivo: true),
      KPIData(titulo: 'Taxa de Participacao', valor: 78.5, variacao: 5.1, unidade: '%', positivo: true),
      KPIData(titulo: 'Score Medio', valor: 35.2, variacao: -2.3, unidade: 'pts', positivo: false),
      KPIData(titulo: 'Alertas Ativos', valor: 12, variacao: -15.0, unidade: '', positivo: true),
    ];
  }
}
