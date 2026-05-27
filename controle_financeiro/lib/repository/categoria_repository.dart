import '../database/app_database.dart';
import '../entities/categoria.dart';

class CategoriaRepository {
  final AppDatabase _db;

  CategoriaRepository(this._db);

  Future<List<Categoria>> getAll() => _db.categoriaDao.findAll();

  Future<Categoria?> getById(int id) => _db.categoriaDao.findById(id);

  Future<void> save(Categoria c) async {
    if (c.id == null) {
      await _db.categoriaDao.insert(c);
    } else {
      await _db.categoriaDao.update(c);
    }
  }

  Future<void> remove(Categoria c) => _db.categoriaDao.delete(c);

  Future<void> seedIfEmpty() async {
    final atuais = await getAll();
    if (atuais.isNotEmpty) return;
    final padroes = [
      Categoria(nome: 'Alimentação', cor: '#E53935'),
      Categoria(nome: 'Transporte', cor: '#1E88E5'),
      Categoria(nome: 'Salário', cor: '#43A047'),
      Categoria(nome: 'Lazer', cor: '#FB8C00'),
      Categoria(nome: 'Moradia', cor: '#8E24AA'),
    ];
    for (final c in padroes) {
      await _db.categoriaDao.insert(c);
    }
  }
}
