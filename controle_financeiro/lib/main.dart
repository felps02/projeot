import 'package:flutter/material.dart';
import 'package:floor/floor.dart';

import 'database/app_database.dart';
import 'repository/categoria_repository.dart';
import 'repository/lancamento_repository.dart';
import 'screens/home_screen.dart';

late final AppDatabase database;
late final LancamentoRepository lancamentoRepository;
late final CategoriaRepository categoriaRepository;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('[boot] iniciando database...');
    database = await $FloorAppDatabase
        .databaseBuilder('controle_financeiro.db')
        .addCallback(Callback(
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
        ))
        .build();
    debugPrint('[boot] database aberto');

    lancamentoRepository = LancamentoRepository(database);
    categoriaRepository = CategoriaRepository(database);

    await categoriaRepository.seedIfEmpty();
    debugPrint('[boot] categorias seedadas');

    runApp(const ControleFinanceiroApp());
  } catch (e, st) {
    debugPrint('[boot][ERRO] $e');
    debugPrint('$st');
    runApp(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Erro ao inicializar:',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SelectableText('$e'),
                const SizedBox(height: 16),
                SelectableText('$st',
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class ControleFinanceiroApp extends StatelessWidget {
  const ControleFinanceiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
