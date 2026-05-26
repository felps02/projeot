class Question {
  final String id;
  final String texto;
  final String categoria; // 'emocional', 'estresse', 'ambiente', 'relacionamento', 'geral'
  final String tipo; // 'likert', 'emoji', 'sim_nao'
  final bool ativa;
  final int ordem;

  Question({
    required this.id,
    required this.texto,
    required this.categoria,
    required this.tipo,
    this.ativa = true,
    required this.ordem,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id']?.toString() ?? '',
      texto: json['texto'] ?? '',
      categoria: json['categoria'] ?? 'geral',
      tipo: json['tipo'] ?? 'likert',
      ativa: json['ativa'] ?? true,
      ordem: json['ordem'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': texto,
      'categoria': categoria,
      'tipo': tipo,
      'ativa': ativa,
      'ordem': ordem,
    };
  }

  static List<Question> defaultQuestions() {
    return [
      Question(
        id: '1',
        texto: 'Como voce esta se sentindo emocionalmente hoje?',
        categoria: 'emocional',
        tipo: 'emoji',
        ordem: 1,
      ),
      Question(
        id: '2',
        texto: 'Qual seu nivel de estresse no trabalho hoje?',
        categoria: 'estresse',
        tipo: 'likert',
        ordem: 2,
      ),
      Question(
        id: '3',
        texto: 'Voce se sente apoiado pela sua equipe?',
        categoria: 'relacionamento',
        tipo: 'likert',
        ordem: 3,
      ),
      Question(
        id: '4',
        texto: 'Voce conseguiu dormir bem na ultima noite?',
        categoria: 'geral',
        tipo: 'sim_nao',
        ordem: 4,
      ),
      Question(
        id: '5',
        texto: 'Como voce avalia o ambiente de trabalho hoje?',
        categoria: 'ambiente',
        tipo: 'likert',
        ordem: 5,
      ),
    ];
  }
}
