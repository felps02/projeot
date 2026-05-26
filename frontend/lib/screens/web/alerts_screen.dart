import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/web/sidebar_menu.dart';
import '../../widgets/web/alert_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filterType = 'Todos';
  String _filterLevel = 'Todos';
  String _filterRead = 'Todos';

  @override
  void initState() {
    super.initState();
    context.read<DashboardProvider>().loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = context.watch<DashboardProvider>();
    final filteredAlerts = dashProvider.alerts.where((a) {
      final matchType = _filterType == 'Todos' || a.tipo == _filterType;
      final matchLevel =
          _filterLevel == 'Todos' || a.nivel == _filterLevel;
      final matchRead = _filterRead == 'Todos' ||
          (_filterRead == 'nao_lido' && !a.lido) ||
          (_filterRead == 'lido' && a.lido);
      return matchType && matchLevel && matchRead;
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            selectedIndex: 3,
            onItemSelected: (index) {
              final routes = [
                AppRoutes.webDashboard,
                AppRoutes.webTeam,
                AppRoutes.webReports,
                AppRoutes.webAlerts,
                AppRoutes.webHeatmap,
                AppRoutes.webSettings,
              ];
              if (index != 3) {
                Navigator.pushReplacementNamed(context, routes[index]);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, dashProvider),
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
                                    child:
                                        DropdownButtonFormField<String>(
                                      initialValue: _filterType,
                                      decoration: InputDecoration(
                                        labelText: 'Tipo',
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
                                            value: 'risco_alto',
                                            child: Text('Risco Alto')),
                                        DropdownMenuItem(
                                            value: 'emergencia',
                                            child:
                                                Text('Emergencia')),
                                        DropdownMenuItem(
                                            value: 'ausencia',
                                            child: Text('Ausencia')),
                                        DropdownMenuItem(
                                            value: 'tendencia',
                                            child:
                                                Text('Tendencia')),
                                      ],
                                      onChanged: (v) => setState(
                                          () => _filterType = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child:
                                        DropdownButtonFormField<String>(
                                      initialValue: _filterLevel,
                                      decoration: InputDecoration(
                                        labelText: 'Nivel',
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
                                            value: 'info',
                                            child: Text('Info')),
                                        DropdownMenuItem(
                                            value: 'atencao',
                                            child: Text('Atencao')),
                                        DropdownMenuItem(
                                            value: 'urgente',
                                            child: Text('Urgente')),
                                        DropdownMenuItem(
                                            value: 'critico',
                                            child: Text('Critico')),
                                      ],
                                      onChanged: (v) => setState(
                                          () => _filterLevel = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child:
                                        DropdownButtonFormField<String>(
                                      initialValue: _filterRead,
                                      decoration: InputDecoration(
                                        labelText: 'Status',
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
                                            value: 'nao_lido',
                                            child:
                                                Text('Nao lidos')),
                                        DropdownMenuItem(
                                            value: 'lido',
                                            child: Text('Lidos')),
                                      ],
                                      onChanged: (v) => setState(
                                          () => _filterRead = v!),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${filteredAlerts.length} alertas encontrados',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: filteredAlerts.isEmpty
                                    ? const EmptyStateWidget(
                                        message:
                                            'Nenhum alerta encontrado',
                                        icon: Icons
                                            .notifications_off_outlined,
                                      )
                                    : ListView.builder(
                                        itemCount:
                                            filteredAlerts.length,
                                        itemBuilder: (context, index) {
                                          final alert =
                                              filteredAlerts[index];
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    bottom: 8),
                                            child: AlertCard(
                                              alert: alert,
                                              onMarkRead: alert.lido
                                                  ? null
                                                  : () {
                                                      dashProvider
                                                          .markAlertAsRead(
                                                              alert
                                                                  .id);
                                                    },
                                            ),
                                          );
                                        },
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

  Widget _buildTopBar(
      BuildContext context, DashboardProvider dashProvider) {
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
            'Alertas',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (dashProvider.unreadAlerts > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${dashProvider.unreadAlerts} nao lidos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
          const Spacer(),
          TextButton.icon(
            onPressed: () => dashProvider.loadAlerts(),
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }
}
