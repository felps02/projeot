import 'package:floor/floor.dart' as floor;
import 'package:floor/floor.dart' show dao, Query;

import '../entities/categoria.dart';

@dao
abstract class CategoriaDao {
  @Query('SELECT * FROM Categoria ORDER BY nome ASC')
  Future<List<Categoria>> findAll();

  @Query('SELECT * FROM Categoria WHERE id = :id')
  Future<Categoria?> findById(int id);

  @floor.insert
  Future<int> insert(Categoria categoria);

  @floor.update
  Future<int> update(Categoria categoria);

  @floor.delete
  Future<int> delete(Categoria categoria);
}
