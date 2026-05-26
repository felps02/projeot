class AlertModel {
  final String id;
  final String usuarioId;
  final String tipo; // 'risco_alto', 'emergencia', 'ausencia', 'tendencia'
  final String nivel; // 'info', 'atencao', 'urgente', 'critico'
  final String descricao;
  final bool lido;
  final DateTime data;
  final String? nomeUsuario;

  AlertModel({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.nivel,
    required this.descricao,
    this.lido = false,
    required this.data,
    this.nomeUsuario,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuarioId']?.toString() ?? '',
      tipo: json['tipo'] ?? 'info',
      nivel: json['nivel'] ?? 'info',
      descricao: json['descricao'] ?? '',
      lido: json['lido'] ?? false,
      data: json['data'] != null
          ? DateTime.parse(json['data'])
          : DateTime.now(),
      nomeUsuario: json['nomeUsuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'tipo': tipo,
      'nivel': nivel,
      'descricao': descricao,
      'lido': lido,
      'data': data.toIso8601String(),
      if (nomeUsuario != null) 'nomeUsuario': nomeUsuario,
    };
  }

  AlertModel copyWith({
    String? id,
    String? usuarioId,
    String? tipo,
    String? nivel,
    String? descricao,
    bool? lido,
    DateTime? data,
    String? nomeUsuario,
  }) {
    return AlertModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      tipo: tipo ?? this.tipo,
      nivel: nivel ?? this.nivel,
      descricao: descricao ?? this.descricao,
      lido: lido ?? this.lido,
      data: data ?? this.data,
      nomeUsuario: nomeUsuario ?? this.nomeUsuario,
    );
  }
}
