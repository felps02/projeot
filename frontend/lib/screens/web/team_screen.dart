import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/web/sidebar_menu.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String _filterSetor = 'Todos';
  String _filterRisco = 'Todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<DashboardProvider>().loadTeam();
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = context.watch<DashboardProvider>();
    final members = _filterMembers(dashProvider.teamMembers);

    final setores = <String>{'Todos'};
    for (final m in dashProvider.teamMembers) {
      setores.add(m['setor'] ?? '');
    }

    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            selectedIndex: 1,
            onItemSelected: (index) {
              final routes = [
                AppRoutes.webDashboard,
                AppRoutes.webTeam,
                AppRoutes.webReports,
                AppRoutes.webAlerts,
                AppRoutes.webHeatmap,
                AppRoutes.webSettings,
              ];
              if (index != 1) {
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
                      ? const Center(child: LoadingWidget(itemCount: 5))
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filters
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Buscar por nome...',
                                        prefixIcon:
                                            const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                      ),
                                      onChanged: (v) => setState(
                                          () => _searchQuery = v),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _filterSetor,
                                      decoration: InputDecoration(
                                        labelText: 'Setor',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                      ),
                                      items: setores.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        );
                                      }).toList(),
                                      onChanged: (v) => setState(
                                          () => _filterSetor = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _filterRisco,
                                      decoration: InputDecoration(
                                        labelText: 'Nivel de Risco',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Todos',
                                            child: Text('Todos')),
                                        DropdownMenuItem(
                                            value: 'baixo',
                                            child: Text('Baixo')),
                                        DropdownMenuItem(
                                            value: 'moderado',
                                            child: Text('Moderado')),
                                        DropdownMenuItem(
                                            value: 'alto',
                                            child: Text('Alto')),
                                        DropdownMenuItem(
                                            value: 'critico',
                                            child: Text('Critico')),
                                      ],
                                      onChanged: (v) => setState(
                                          () => _filterRisco = v!),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${members.length} funcionarios encontrados',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Table
                              Expanded(
                                child: Card(
                                  child: SingleChildScrollView(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                        columns: const [
                                          DataColumn(
                                              label: Text('Nome',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight
                                                              .w600))),
                                          DataColumn(
                                              label: Text('Setor',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight
                                                              .w600))),
                                          DataColumn(
                                              label: Text(
                                                  'Ultimo Check-in',
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
                                              label: Text('Nivel',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight
                                                              .w600))),
                                          DataColumn(
                                              label: Text('Status',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight
                                                              .w600))),
                                        ],
                                        rows: members.map((m) {
                                          final nivel =
                                              m['nivelRisco'] ?? 'baixo';
                                          final color =
                                              Helpers.getRiskColor(nivel);
                                          final checkin = m['ultimoCheckin'] != null
                                              ? DateTime.tryParse(
                                                  m['ultimoCheckin'])
                                              : null;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor: AppTheme
                                                          .primaryBlue
                                                          .withValues(
                                                              alpha: 0.1),
                                                      child: Text(
                                                        (m['nome'] ??
                                                                'U')[0]
                                                            .toUpperCase(),
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                          color: AppTheme
                                                              .primaryBlue,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: 10),
                                                    Text(
                                                        m['nome'] ?? ''),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                  Text(m['setor'] ?? '')),
                                              DataCell(Text(
                                                checkin != null
                                                    ? Helpers.timeAgo(
                                                        checkin)
                                                    : '-',
                                              )),
                                              DataCell(Text(
                                                '${(m['scoreRisco'] ?? 0).toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: color,
                                                ),
                                              )),
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
                                                        .withValues(alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(8),
                                                  ),
                                                  child: Text(
                                                    Helpers.getRiskLabel(
                                                        nivel),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: color,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration:
                                                          BoxDecoration(
                                                        color: m['status'] ==
                                                                'ativo'
                                                            ? AppTheme
                                                                .riskLow
                                                            : Colors.grey,
                                                        shape: BoxShape
                                                            .circle,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: 6),
                                                    Text(m['status'] ==
                                                            'ativo'
                                                        ? 'Ativo'
                                                        : 'Inativo'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
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

  List<Map<String, dynamic>> _filterMembers(
      List<Map<String, dynamic>> all) {
    return all.where((m) {
      final matchSetor =
          _filterSetor == 'Todos' || m['setor'] == _filterSetor;
      final matchRisco =
          _filterRisco == 'Todos' || m['nivelRisco'] == _filterRisco;
      final matchSearch = _searchQuery.isEmpty ||
          (m['nome'] ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchSetor && matchRisco && matchSearch;
    }).toList();
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
            'Equipe',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.read<DashboardProvider>().loadTeam(),
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }
}
