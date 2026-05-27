// GENERATED CODE - DO NOT MODIFY BY HAND
// Equivalente ao código que o floor_generator produziria via:
//   dart run build_runner build --delete-conflicting-outputs
// Foi escrito manualmente porque a versão atual do floor_generator (1.5.0)
// não suporta o Dart SDK 3.11 desta máquina (analyzer interno é da era 3.4).

// ignore_for_file: type=lint

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $FloorAppDatabase {
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  CategoriaDao? _categoriaDaoInstance;

  LancamentoDao? _lancamentoDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations,
    Callback? callback,
  ) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);
        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `Categoria` ('
          '`id` INTEGER PRIMARY KEY AUTOINCREMENT, '
          '`nome` TEXT NOT NULL, '
          '`cor` TEXT NOT NULL)',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `Lancamento` ('
          '`id` INTEGER PRIMARY KEY AUTOINCREMENT, '
          '`descricao` TEXT NOT NULL, '
          '`valor` REAL NOT NULL, '
          '`tipo` TEXT NOT NULL, '
          '`data` TEXT NOT NULL, '
          '`categoria_id` INTEGER NOT NULL, '
          'FOREIGN KEY (`categoria_id`) REFERENCES `Categoria` (`id`) '
          'ON UPDATE NO ACTION ON DELETE CASCADE)',
        );

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  CategoriaDao get categoriaDao {
    return _categoriaDaoInstance ??=
        _$CategoriaDao(database, changeListener);
  }

  @override
  LancamentoDao get lancamentoDao {
    return _lancamentoDaoInstance ??=
        _$LancamentoDao(database, changeListener);
  }
}

class _$CategoriaDao extends CategoriaDao {
  _$CategoriaDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
        _categoriaInsertionAdapter = InsertionAdapter(
          database,
          'Categoria',
          (Categoria item) => <String, Object?>{
            'id': item.id,
            'nome': item.nome,
            'cor': item.cor,
          },
        ),
        _categoriaUpdateAdapter = UpdateAdapter(
          database,
          'Categoria',
          ['id'],
          (Categoria item) => <String, Object?>{
            'id': item.id,
            'nome': item.nome,
            'cor': item.cor,
          },
        ),
        _categoriaDeletionAdapter = DeletionAdapter(
          database,
          'Categoria',
          ['id'],
          (Categoria item) => <String, Object?>{
            'id': item.id,
            'nome': item.nome,
            'cor': item.cor,
          },
        );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Categoria> _categoriaInsertionAdapter;

  final UpdateAdapter<Categoria> _categoriaUpdateAdapter;

  final DeletionAdapter<Categoria> _categoriaDeletionAdapter;

  @override
  Future<List<Categoria>> findAll() async {
    return _queryAdapter.queryList(
      'SELECT * FROM Categoria ORDER BY nome ASC',
      mapper: (Map<String, Object?> row) => Categoria(
        id: row['id'] as int?,
        nome: row['nome'] as String,
        cor: row['cor'] as String,
      ),
    );
  }

  @override
  Future<Categoria?> findById(int id) async {
    return _queryAdapter.query(
      'SELECT * FROM Categoria WHERE id = ?1',
      mapper: (Map<String, Object?> row) => Categoria(
        id: row['id'] as int?,
        nome: row['nome'] as String,
        cor: row['cor'] as String,
      ),
      arguments: [id],
    );
  }

  @override
  Future<int> insert(Categoria categoria) {
    return _categoriaInsertionAdapter.insertAndReturnId(
        categoria, OnConflictStrategy.abort);
  }

  @override
  Future<int> update(Categoria categoria) {
    return _categoriaUpdateAdapter.updateAndReturnChangedRows(
        categoria, OnConflictStrategy.abort);
  }

  @override
  Future<int> delete(Categoria categoria) {
    return _categoriaDeletionAdapter.deleteAndReturnChangedRows(categoria);
  }
}

class _$LancamentoDao extends LancamentoDao {
  _$LancamentoDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database, changeListener),
        _lancamentoInsertionAdapter = InsertionAdapter(
          database,
          'Lancamento',
          (Lancamento item) => <String, Object?>{
            'id': item.id,
            'descricao': item.descricao,
            'valor': item.valor,
            'tipo': item.tipo,
            'data': item.data,
            'categoria_id': item.categoriaId,
          },
          changeListener,
        ),
        _lancamentoUpdateAdapter = UpdateAdapter(
          database,
          'Lancamento',
          ['id'],
          (Lancamento item) => <String, Object?>{
            'id': item.id,
            'descricao': item.descricao,
            'valor': item.valor,
            'tipo': item.tipo,
            'data': item.data,
            'categoria_id': item.categoriaId,
          },
          changeListener,
        ),
        _lancamentoDeletionAdapter = DeletionAdapter(
          database,
          'Lancamento',
          ['id'],
          (Lancamento item) => <String, Object?>{
            'id': item.id,
            'descricao': item.descricao,
            'valor': item.valor,
            'tipo': item.tipo,
            'data': item.data,
            'categoria_id': item.categoriaId,
          },
          changeListener,
        );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Lancamento> _lancamentoInsertionAdapter;

  final UpdateAdapter<Lancamento> _lancamentoUpdateAdapter;

  final DeletionAdapter<Lancamento> _lancamentoDeletionAdapter;

  Lancamento _mapLancamento(Map<String, Object?> row) => Lancamento(
        id: row['id'] as int?,
        descricao: row['descricao'] as String,
        valor: (row['valor'] as num).toDouble(),
        tipo: row['tipo'] as String,
        data: row['data'] as String,
        categoriaId: row['categoria_id'] as int,
      );

  @override
  Future<List<Lancamento>> findAll() async {
    return _queryAdapter.queryList(
      'SELECT * FROM Lancamento ORDER BY data DESC, id DESC',
      mapper: _mapLancamento,
    );
  }

  @override
  Stream<List<Lancamento>> watchAll() {
    return _queryAdapter.queryListStream(
      'SELECT * FROM Lancamento ORDER BY data DESC, id DESC',
      mapper: _mapLancamento,
      queryableName: 'Lancamento',
      isView: false,
    );
  }

  @override
  Future<List<Lancamento>> findByTipo(String tipo) async {
    return _queryAdapter.queryList(
      'SELECT * FROM Lancamento WHERE tipo = ?1 ORDER BY data DESC, id DESC',
      mapper: _mapLancamento,
      arguments: [tipo],
    );
  }

  @override
  Stream<List<Lancamento>> watchByTipo(String tipo) {
    return _queryAdapter.queryListStream(
      'SELECT * FROM Lancamento WHERE tipo = ?1 ORDER BY data DESC, id DESC',
      mapper: _mapLancamento,
      arguments: [tipo],
      queryableName: 'Lancamento',
      isView: false,
    );
  }

  @override
  Future<int> insert(Lancamento lancamento) {
    return _lancamentoInsertionAdapter.insertAndReturnId(
        lancamento, OnConflictStrategy.abort);
  }

  @override
  Future<int> update(Lancamento lancamento) {
    return _lancamentoUpdateAdapter.updateAndReturnChangedRows(
        lancamento, OnConflictStrategy.abort);
  }

  @override
  Future<int> delete(Lancamento lancamento) {
    return _lancamentoDeletionAdapter.deleteAndReturnChangedRows(lancamento);
  }
}
