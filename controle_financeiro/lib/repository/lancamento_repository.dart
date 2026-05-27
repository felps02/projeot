import '../database/app_database.dart';
import '../entities/lancamento.dart';

class SaldoResumo {
  final double totalReceitas;
  final double totalDespesas;

  const SaldoResumo({required this.totalReceitas, required this.totalDespesas});

  double get saldo => totalReceitas - totalDespesas;
}

class LancamentoRepository {
  final AppDatabase _db;

  LancamentoRepository(this._db);

  Future<List<Lancamento>> getAll() => _db.lancamentoDao.findAll();

  Stream<List<Lancamento>> watchAll() => _db.lancamentoDao.watchAll();

  Future<List<Lancamento>> getByTipo(String tipo) =>
      _db.lancamentoDao.findByTipo(tipo);

  Stream<List<Lancamento>> watchByTipo(String tipo) =>
      _db.lancamentoDao.watchByTipo(tipo);

  Future<void> save(Lancamento l) async {
    if (l.id == null) {
      await _db.lancamentoDao.insert(l);
    } else {
      await _db.lancamentoDao.update(l);
    }
  }

  Future<void> remove(Lancamento l) => _db.lancamentoDao.delete(l);

  Future<SaldoResumo> calcularSaldo() async {
    final result = await _db.database.rawQuery('''
      SELECT
        SUM(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END) AS total_receitas,
        SUM(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END) AS total_despesas
      FROM Lancamento
    ''');

    final row = result.first;
    final receitas = (row['total_receitas'] as num?)?.toDouble() ?? 0.0;
    final despesas = (row['total_despesas'] as num?)?.toDouble() ?? 0.0;

    return SaldoResumo(totalReceitas: receitas, totalDespesas: despesas);
  }
}
