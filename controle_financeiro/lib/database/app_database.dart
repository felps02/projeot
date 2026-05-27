import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../dao/categoria_dao.dart';
import '../dao/lancamento_dao.dart';
import '../entities/categoria.dart';
import '../entities/lancamento.dart';

part 'app_database.g.dart';

@Database(version: 1, entities: [Categoria, Lancamento])
abstract class AppDatabase extends FloorDatabase {
  CategoriaDao get categoriaDao;
  LancamentoDao get lancamentoDao;
}
