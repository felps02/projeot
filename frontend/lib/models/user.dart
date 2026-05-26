class User {
  final String id;
  final String nome;
  final String email;
  final String cargo;
  final String perfil; // 'funcionario' or 'lider'
  final String setor;
  final String? liderId;
  final String status;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.perfil,
    required this.setor,
    this.liderId,
    this.status = 'ativo',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cargo: json['cargo'] ?? '',
      perfil: json['perfil'] ?? 'funcionario',
      setor: json['setor'] ?? '',
      liderId: json['liderId']?.toString(),
      status: json['status'] ?? 'ativo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'cargo': cargo,
      'perfil': perfil,
      'setor': setor,
      'liderId': liderId,
      'status': status,
    };
  }

  bool get isLider => perfil == 'lider';

  User copyWith({
    String? id,
    String? nome,
    String? email,
    String? cargo,
    String? perfil,
    String? setor,
    String? liderId,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      cargo: cargo ?? this.cargo,
      perfil: perfil ?? this.perfil,
      setor: setor ?? this.setor,
      liderId: liderId ?? this.liderId,
      status: status ?? this.status,
    );
  }
}
