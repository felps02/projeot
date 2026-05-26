import 'answer.dart';

class Assessment {
  final String? id;
  final String usuarioId;
  final DateTime data;
  final double scoreRisco;
  final String nivelRisco; // 'baixo', 'moderado', 'alto', 'critico'
  final bool completada;
  final List<Answer> respostas;

  Assessment({
    this.id,
    required this.usuarioId,
    required this.data,
    this.scoreRisco = 0.0,
    this.nivelRisco = 'baixo',
    this.completada = false,
    this.respostas = const [],
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id']?.toString(),
      usuarioId: json['usuarioId']?.toString() ?? '',
      data: json['data'] != null
          ? DateTime.parse(json['data'])
          : DateTime.now(),
      scoreRisco: (json['scoreRisco'] ?? 0).toDouble(),
      nivelRisco: json['nivelRisco'] ?? 'baixo',
      completada: json['completada'] ?? false,
      respostas: json['respostas'] != null
          ? (json['respostas'] as List)
              .map((r) => Answer.fromJson(r))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'usuarioId': usuarioId,
      'data': data.toIso8601String(),
      'scoreRisco': scoreRisco,
      'nivelRisco': nivelRisco,
      'completada': completada,
      'respostas': respostas.map((r) => r.toJson()).toList(),
    };
  }

  Assessment copyWith({
    String? id,
    String? usuarioId,
    DateTime? data,
    double? scoreRisco,
    String? nivelRisco,
    bool? completada,
    List<Answer>? respostas,
  }) {
    return Assessment(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      data: data ?? this.data,
      scoreRisco: scoreRisco ?? this.scoreRisco,
      completada: completada ?? this.completada,
      nivelRisco: nivelRisco ?? this.nivelRisco,
      respostas: respostas ?? this.respostas,
    );
  }

  static double calculateRiskScore(List<Answer> answers) {
    if (answers.isEmpty) return 0;
    final total = answers.fold<int>(0, (sum, a) => sum + a.valor);
    return (total / (answers.length * 5)) * 100;
  }

  static String calculateRiskLevel(double score) {
    if (score <= 25) return 'baixo';
    if (score <= 50) return 'moderado';
    if (score <= 75) return 'alto';
    return 'critico';
  }
}
