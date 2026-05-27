import 'package:floor/floor.dart' as floor;
import 'package:floor/floor.dart' show dao, Query;

import '../entities/lancamento.dart';

@dao
abstract class LancamentoDao {
  @Query('SELECT * FROM Lancamento ORDER BY data DESC, id DESC')
  Future<List<Lancamento>> findAll();

  @Query('SELECT * FROM Lancamento ORDER BY data DESC, id DESC')
  Stream<List<Lancamento>> watchAll();

  @Query('SELECT * FROM Lancamento WHERE tipo = :tipo ORDER BY data DESC, id DESC')
  Future<List<Lancamento>> findByTipo(String tipo);

  @Query('SELECT * FROM Lancamento WHERE tipo = :tipo ORDER BY data DESC, id DESC')
  Stream<List<Lancamento>> watchByTipo(String tipo);

  @floor.insert
  Future<int> insert(Lancamento lancamento);

  @floor.update
  Future<int> update(Lancamento lancamento);

  @floor.delete
  Future<int> delete(Lancamento lancamento);
}
