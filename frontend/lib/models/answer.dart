class Answer {
  final String? id;
  final String? avaliacaoId;
  final String perguntaId;
  final int valor;

  Answer({
    this.id,
    this.avaliacaoId,
    required this.perguntaId,
    required this.valor,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id']?.toString(),
      avaliacaoId: json['avaliacaoId']?.toString(),
      perguntaId: json['perguntaId']?.toString() ?? '',
      valor: json['valor'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (avaliacaoId != null) 'avaliacaoId': avaliacaoId,
      'perguntaId': perguntaId,
      'valor': valor,
    };
  }

  Answer copyWith({
    String? id,
    String? avaliacaoId,
    String? perguntaId,
    int? valor,
  }) {
    return Answer(
      id: id ?? this.id,
      avaliacaoId: avaliacaoId ?? this.avaliacaoId,
      perguntaId: perguntaId ?? this.perguntaId,
      valor: valor ?? this.valor,
    );
  }
}
