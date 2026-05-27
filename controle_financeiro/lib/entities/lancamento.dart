import 'package:floor/floor.dart';

import 'categoria.dart';

@Entity(
  tableName: 'Lancamento',
  foreignKeys: [
    ForeignKey(
      childColumns: ['categoria_id'],
      parentColumns: ['id'],
      entity: Categoria,
      onDelete: ForeignKeyAction.cascade,
    ),
  ],
)
class Lancamento {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String descricao;

  final double valor;

  final String tipo;

  final String data;

  @ColumnInfo(name: 'categoria_id')
  final int categoriaId;

  Lancamento({
    this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.data,
    required this.categoriaId,
  });

  Lancamento copyWith({
    int? id,
    String? descricao,
    double? valor,
    String? tipo,
    String? data,
    int? categoriaId,
  }) {
    return Lancamento(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      data: data ?? this.data,
      categoriaId: categoriaId ?? this.categoriaId,
    );
  }
}
