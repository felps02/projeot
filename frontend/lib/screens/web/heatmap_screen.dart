import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/web/sidebar_menu.dart';
import '../../widgets/web/heatmap_widget.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  String _timePeriod = '30';

  @override
  void initState() {
    super.initState();
    context.read<DashboardProvider>().loadHeatmap();
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = context.watch<DashboardProvider>();

    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            selectedIndex: 4,
            onItemSelected: (index) {
              final routes = [
                AppRoutes.webDashboard,
                AppRoutes.webTeam,
                AppRoutes.webReports,
                AppRoutes.webAlerts,
                AppRoutes.webHeatmap,
                AppRoutes.webSettings,
              ];
              if (index != 4) {
                Navigator.pushReplacementNamed(context, routes[index]);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: dashProvider.isLoading
                      ? const Center(child: LoadingWidget(itemCount: 4))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Time period selector
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Periodo:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SegmentedButton<String>(
                                        segments: const [
                                          ButtonSegment(
                                            value: '7',
                                            label: Text('7 dias'),
                                          ),
                                          ButtonSegment(
                                            value: '15',
                                            label: Text('15 dias'),
                                          ),
                                          ButtonSegment(
                                            value: '30',
                                            label: Text('30 dias'),
                                          ),
                                          ButtonSegment(
                                            value: '90',
                                            label: Text('90 dias'),
                                          ),
                                        ],
                                        selected: {_timePeriod},
                                        onSelectionChanged:
                                            (selected) {
                                          setState(() => _timePeriod =
                                              selected.first);
                                          dashProvider.loadHeatmap();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Mapa de Calor por Setor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Visualizacao do nivel de risco psicossocial por setor. Cores indicam o nivel de risco geral do setor.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 20),
                              HeatmapWidget(
                                data: dashProvider.heatmapData,
                              ),
                              const SizedBox(height: 24),

                              // Summary table
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Resumo por Setor',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(
                                                label: Text('Setor',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600))),
                                            DataColumn(
                                                label: Text('Score',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600)),
                                                numeric: true),
                                            DataColumn(
                                                label: Text(
                                                    'Funcionarios',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600)),
                                                numeric: true),
                                            DataColumn(
                                                label: Text('Nivel',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600))),
                                          ],
                                          rows: dashProvider.heatmapData
                                              .map((item) {
                                            final color =
                                                _getNivelColor(
                                                    item.nivel);
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                    Text(item.setor)),
                                                DataCell(Text(item.score
                                                    .toStringAsFixed(
                                                        0))),
                                                DataCell(Text(
                                                    '${item.funcionarios}')),
                                                DataCell(
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: color
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  8),
                                                    ),
                                                    child: Text(
                                                      _getNivelLabel(
                                                          item.nivel),
                                                      style:
                                                          TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                        color: color,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

  Color _getNivelColor(String nivel) {
    switch (nivel) {
      case 'baixo':
        return Colors.green;
      case 'moderado':
        return Colors.amber;
      case 'alto':
        return Colors.orange;
      case 'critico':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNivelLabel(String nivel) {
    switch (nivel) {
      case 'baixo':
        return 'Baixo';
      case 'moderado':
        return 'Moderado';
      case 'alto':
        return 'Alto';
      case 'critico':
        return 'Critico';
      default:
        return nivel;
    }
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
            'Mapa de Calor',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () =>
                context.read<DashboardProvider>().loadHeatmap(),
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }
}
