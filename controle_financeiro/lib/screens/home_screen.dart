import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../entities/categoria.dart';
import '../entities/lancamento.dart';
import '../main.dart';
import '../repository/lancamento_repository.dart';
import '../widgets/saldo_card.dart';
import 'lancamento_form_screen.dart';

enum FiltroTipo { todos, receita, despesa }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FiltroTipo _filtro = FiltroTipo.todos;
  SaldoResumo _resumo = const SaldoResumo(totalReceitas: 0, totalDespesas: 0);
  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    _atualizarSaldo();
  }

  Future<void> _carregarCategorias() async {
    final cats = await categoriaRepository.getAll();
    if (mounted) setState(() => _categorias = cats);
  }

  Future<void> _atualizarSaldo() async {
    final resumo = await lancamentoRepository.calcularSaldo();
    if (mounted) setState(() => _resumo = resumo);
  }

  Stream<List<Lancamento>> _streamLancamentos() {
    switch (_filtro) {
      case FiltroTipo.todos:
        return lancamentoRepository.watchAll();
      case FiltroTipo.receita:
        return lancamentoRepository.watchByTipo('receita');
      case FiltroTipo.despesa:
        return lancamentoRepository.watchByTipo('despesa');
    }
  }

  Categoria? _categoriaPorId(int id) {
    for (final c in _categorias) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _abrirFormulario({Lancamento? lancamento}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LancamentoFormScreen(
          categorias: _categorias,
          lancamento: lancamento,
        ),
      ),
    );
    if (resultado == true) {
      await _atualizarSaldo();
      await _carregarCategorias();
    }
  }

  Future<void> _confirmarExclusao(Lancamento l) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir lançamento'),
        content: Text('Deseja realmente excluir "${l.descricao}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await lancamentoRepository.remove(l);
      await _atualizarSaldo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatoData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          SaldoCard(resumo: _resumo),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Filtro: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<FiltroTipo>(
                    value: _filtro,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: FiltroTipo.todos,
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem(
                        value: FiltroTipo.receita,
                        child: Text('Receitas'),
                      ),
                      DropdownMenuItem(
                        value: FiltroTipo.despesa,
                        child: Text('Despesas'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) setState(() => _filtro = valor);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Lancamento>>(
              stream: _streamLancamentos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final itens = snapshot.data ?? [];
                if (itens.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum lançamento ainda.\nToque em + para adicionar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: itens.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final l = itens[index];
                    final categoria = _categoriaPorId(l.categoriaId);
                    final isReceita = l.tipo == 'receita';
                    final cor = isReceita
                        ? Colors.green.shade700
                        : Colors.red.shade700;
                    DateTime? dataParsed;
                    try {
                      dataParsed = DateTime.parse(l.data);
                    } catch (_) {}

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _parseHexColor(categoria?.cor),
                        child: Icon(
                          isReceita ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(l.descricao),
                      subtitle: Text(
                        '${categoria?.nome ?? "Sem categoria"} • ${dataParsed != null ? formatoData.format(dataParsed) : l.data}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isReceita ? '+' : '-'} ${formatoMoeda.format(l.valor)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cor,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                            onPressed: () => _confirmarExclusao(l),
                          ),
                        ],
                      ),
                      onTap: () => _abrirFormulario(lancamento: l),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo lançamento',
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final clean = hex.replaceAll('#', '');
    final value = int.tryParse('FF$clean', radix: 16);
    return value != null ? Color(value) : Colors.grey;
  }
}
