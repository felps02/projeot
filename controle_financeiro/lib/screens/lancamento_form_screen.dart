import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../entities/categoria.dart';
import '../entities/lancamento.dart';
import '../main.dart';

class LancamentoFormScreen extends StatefulWidget {
  final List<Categoria> categorias;
  final Lancamento? lancamento;

  const LancamentoFormScreen({
    super.key,
    required this.categorias,
    this.lancamento,
  });

  @override
  State<LancamentoFormScreen> createState() => _LancamentoFormScreenState();
}

class _LancamentoFormScreenState extends State<LancamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  String _tipo = 'despesa';
  DateTime _data = DateTime.now();
  int? _categoriaId;

  bool get _editando => widget.lancamento != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lancamento;
    if (l != null) {
      _descricaoCtrl.text = l.descricao;
      _valorCtrl.text = l.valor.toStringAsFixed(2).replaceAll('.', ',');
      _tipo = l.tipo;
      _categoriaId = l.categoriaId;
      try {
        _data = DateTime.parse(l.data);
      } catch (_) {}
    }
    if (_categoriaId == null && widget.categorias.isNotEmpty) {
      _categoriaId = widget.categorias.first.id;
    }
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) {
      setState(() => _data = escolhida);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    final valor = double.parse(_valorCtrl.text.replaceAll(',', '.'));
    final dataIso = DateFormat('yyyy-MM-dd').format(_data);

    final novo = Lancamento(
      id: widget.lancamento?.id,
      descricao: _descricaoCtrl.text.trim(),
      valor: valor,
      tipo: _tipo,
      data: dataIso,
      categoriaId: _categoriaId!,
    );

    await lancamentoRepository.save(novo);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final formatoData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar lançamento' : 'Novo lançamento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe uma descrição';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o valor';
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'receita', child: Text('Receita')),
                DropdownMenuItem(value: 'despesa', child: Text('Despesa')),
              ],
              onChanged: (valor) {
                if (valor != null) setState(() => _tipo = valor);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _categoriaId,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: widget.categorias.map((c) {
                return DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.nome),
                );
              }).toList(),
              onChanged: (valor) => setState(() => _categoriaId = valor),
              validator: (v) => v == null ? 'Selecione uma categoria' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selecionarData,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatoData.format(_data)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.save),
              label: Text(_editando ? 'Salvar alterações' : 'Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
