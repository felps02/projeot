class Emergency {
  final String? id;
  final String usuarioId;
  final String motivo;
  final String? descricao;
  final String status; // 'aberta', 'em_atendimento', 'resolvida'
  final String prioridade; // 'alta', 'critica'
  final DateTime data;

  Emergency({
    this.id,
    required this.usuarioId,
    required this.motivo,
    this.descricao,
    this.status = 'aberta',
    this.prioridade = 'critica',
    DateTime? data,
  }) : data = data ?? DateTime.now();

  factory Emergency.fromJson(Map<String, dynamic> json) {
    return Emergency(
      id: json['id']?.toString(),
      usuarioId: json['usuarioId']?.toString() ?? '',
      motivo: json['motivo'] ?? '',
      descricao: json['descricao'],
      status: json['status'] ?? 'aberta',
      prioridade: json['prioridade'] ?? 'critica',
      data: json['data'] != null
          ? DateTime.parse(json['data'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'usuarioId': usuarioId,
      'motivo': motivo,
      if (descricao != null) 'descricao': descricao,
      'status': status,
      'prioridade': prioridade,
      'data': data.toIso8601String(),
    };
  }

  static const List<String> motivos = [
    'Crise emocional',
    'Assedio',
    'Colapso psicologico',
    'Situacao urgente',
  ];
}
