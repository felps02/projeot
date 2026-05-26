import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../utils/helpers.dart';
import '../../widgets/web/sidebar_menu.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;
  String _reportType = 'equipe';
  String _filterSetor = 'Todos';
  String _filterRisco = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            selectedIndex: 2,
            onItemSelected: (index) {
              final routes = [
                AppRoutes.webDashboard,
                AppRoutes.webTeam,
                AppRoutes.webReports,
                AppRoutes.webAlerts,
                AppRoutes.webHeatmap,
                AppRoutes.webSettings,
              ];
              if (index != 2) {
                Navigator.pushReplacementNamed(context, routes[index]);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Range
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Periodo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final range =
                                              await showDateRangePicker(
                                            context: context,
                                            firstDate: DateTime(2024),
                                            lastDate: DateTime.now(),
                                            locale:
                                                const Locale('pt', 'BR'),
                                          );
                                          if (range != null) {
                                            setState(
                                                () => _dateRange = range);
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.calendar_today),
                                        label: Text(
                                          _dateRange != null
                                              ? '${Helpers.formatDate(_dateRange!.start)} - ${Helpers.formatDate(_dateRange!.end)}'
                                              : 'Selecionar periodo',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding:
                                              const EdgeInsets.all(16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildQuickDateButton(
                                        '7 dias', 7),
                                    const SizedBox(width: 8),
                                    _buildQuickDateButton(
                                        '15 dias', 15),
                                    const SizedBox(width: 8),
                                    _buildQuickDateButton(
                                        '30 dias', 30),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filters row
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tipo de Relatorio',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SegmentedButton<String>(
                                        segments: const [
                                          ButtonSegment(
                                            value: 'individual',
                                            label:
                                                Text('Individual'),
                                            icon: Icon(Icons.person),
                                          ),
                                          ButtonSegment(
                                            value: 'equipe',
                                            label: Text('Equipe'),
                                            icon: Icon(Icons.group),
                                          ),
                                          ButtonSegment(
                                            value: 'setor',
                                            label: Text('Setor'),
                                            icon:
                                                Icon(Icons.business),
                                          ),
                                        ],
                                        selected: {_reportType},
                                        onSelectionChanged:
                                            (selected) {
                                          setState(() => _reportType =
                                              selected.first);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Filtros',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<
                                                    String>(
                                              initialValue: _filterSetor,
                                              decoration:
                                                  InputDecoration(
                                                labelText: 'Setor',
                                                border:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              10),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal:
                                                            12),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'Todos',
                                                    child: Text(
                                                        'Todos')),
                                                DropdownMenuItem(
                                                    value: 'Vendas',
                                                    child: Text(
                                                        'Vendas')),
                                                DropdownMenuItem(
                                                    value: 'Caixa',
                                                    child: Text(
                                                        'Caixa')),
                                                DropdownMenuItem(
                                                    value:
                                                        'Atendimento',
                                                    child: Text(
                                                        'Atendimento')),
                                              ],
                                              onChanged: (v) =>
                                                  setState(() =>
                                                      _filterSetor =
                                                          v!),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<
                                                    String>(
                                              initialValue: _filterRisco,
                                              decoration:
                                                  InputDecoration(
                                                labelText:
                                                    'Nivel de Risco',
                                                border:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              10),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal:
                                                            12),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'Todos',
                                                    child: Text(
                                                        'Todos')),
                                                DropdownMenuItem(
                                                    value: 'baixo',
                                                    child: Text(
                                                        'Baixo')),
                                                DropdownMenuItem(
                                                    value: 'moderado',
                                                    child: Text(
                                                        'Moderado')),
                                                DropdownMenuItem(
                                                    value: 'alto',
                                                    child: Text(
                                                        'Alto')),
                                                DropdownMenuItem(
                                                    value: 'critico',
                                                    child: Text(
                                                        'Critico')),
                                              ],
                                              onChanged: (v) =>
                                                  setState(() =>
                                                      _filterRisco =
                                                          v!),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Preview area
                        Card(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.preview_rounded,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Pre-visualizacao do Relatorio',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Selecione o periodo e os filtros acima para gerar o relatorio.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildSampleReport(context),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Export buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Exportacao PDF em desenvolvimento'),
                                    behavior:
                                        SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Exportar PDF'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Exportacao Excel em desenvolvimento'),
                                    behavior:
                                        SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.table_chart),
                              label: const Text('Exportar Excel'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(String label, int days) {
    return OutlinedButton(
      onPressed: () {
        final now = DateTime.now();
        setState(() {
          _dateRange = DateTimeRange(
            start: now.subtract(Duration(days: days)),
            end: now,
          );
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Text(label),
    );
  }

  Widget _buildSampleReport(BuildContext context) {
    final reportTitle = switch (_reportType) {
      'individual' => 'Relatorio Individual',
      'equipe' => 'Relatorio da Equipe',
      'setor' => 'Relatorio por Setor',
      _ => 'Relatorio',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reportTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dateRange != null
                ? 'Periodo: ${Helpers.formatDate(_dateRange!.start)} a ${Helpers.formatDate(_dateRange!.end)}'
                : 'Periodo: Ultimos 30 dias',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const Divider(height: 24),
          _buildReportRow('Total de avaliacoes', '342'),
          _buildReportRow('Taxa de participacao', '78.5%'),
          _buildReportRow('Score medio', '35.2 pts'),
          _buildReportRow('Funcionarios em risco alto', '18'),
          _buildReportRow('Funcionarios em risco critico', '7'),
          _buildReportRow('Emergencias registradas', '3'),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Relatorios',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
