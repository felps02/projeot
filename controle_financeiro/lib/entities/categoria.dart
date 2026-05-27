import 'package:floor/floor.dart';

@Entity(tableName: 'Categoria')
class Categoria {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String nome;

  final String cor;

  Categoria({this.id, required this.nome, required this.cor});

  Categoria copyWith({int? id, String? nome, String? cor}) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
    );
  }
}
