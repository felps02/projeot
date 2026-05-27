import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../repository/lancamento_repository.dart';

class SaldoCard extends StatelessWidget {
  final SaldoResumo resumo;

  const SaldoCard({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final saldo = resumo.saldo;
    final corSaldo = saldo >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Saldo Total',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              formato.format(saldo),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: corSaldo,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _resumoItem(
                  context,
                  'Receitas',
                  formato.format(resumo.totalReceitas),
                  Colors.green.shade700,
                  Icons.arrow_upward,
                ),
                _resumoItem(
                  context,
                  'Despesas',
                  formato.format(resumo.totalDespesas),
                  Colors.red.shade700,
                  Icons.arrow_downward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumoItem(
    BuildContext context,
    String titulo,
    String valor,
    Color cor,
    IconData icone,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: cor, size: 18),
            const SizedBox(width: 4),
            Text(titulo, style: const TextStyle(color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(fontWeight: FontWeight.w600, color: cor),
        ),
      ],
    );
  }
}
