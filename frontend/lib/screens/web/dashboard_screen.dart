import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/web/sidebar_menu.dart';
import '../../widgets/web/kpi_card.dart';
import '../../widgets/web/risk_chart.dart';
import '../../widgets/web/trend_chart.dart';
import '../../widgets/web/alert_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<DashboardProvider>().loadDashboard();
  }

  void _onMenuItemSelected(int index) {
    setState(() => _selectedIndex = index);
    final routes = [
      AppRoutes.webDashboard,
      AppRoutes.webTeam,
      AppRoutes.webReports,
      AppRoutes.webAlerts,
      AppRoutes.webHeatmap,
      AppRoutes.webSettings,
    ];
    if (index > 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = context.watch<DashboardProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            selectedIndex: _selectedIndex,
            onItemSelected: _onMenuItemSelected,
          ),
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
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
                        'Painel de Gestao',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        onPressed: () => themeProvider.toggleTheme(),
                        tooltip: 'Alternar tema',
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, AppRoutes.webAlerts);
                            },
                            tooltip: 'Alertas',
                          ),
                          if (dashProvider.unreadAlerts > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.riskCritical,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${dashProvider.unreadAlerts}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppTheme.primaryBlue.withValues(alpha: 0.15),
                        child: Text(
                          user != null ? user.nome[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user?.nome ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'logout') {
                            authProvider.logout();
                            Navigator.pushReplacementNamed(
                                context, AppRoutes.login);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 18),
                                SizedBox(width: 8),
                                Text('Sair'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: dashProvider.isLoading
                      ? const Center(child: LoadingWidget(itemCount: 4))
                      : RefreshIndicator(
                          onRefresh: () => dashProvider.loadDashboard(),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // KPI row
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final kpis = dashProvider.kpis;
                                    final icons = [
                                      Icons.people,
                                      Icons.how_to_reg,
                                      Icons.analytics,
                                      Icons.warning_amber,
                                    ];
                                    final colors = [
                                      AppTheme.primaryBlue,
                                      AppTheme.secondaryTeal,
                                      AppTheme.riskHigh,
                                      AppTheme.riskCritical,
                                    ];

                                    if (constraints.maxWidth > 900) {
                                      return Row(
                                        children: List.generate(
                                          kpis.length,
                                          (i) => Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: i < kpis.length - 1
                                                    ? 12
                                                    : 0,
                                              ),
                                              child: KPICard(
                                                kpi: kpis[i],
                                                icon: icons[
                                                    i % icons.length],
                                                color: colors[
                                                    i % colors.length],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: List.generate(
                                        kpis.length,
                                        (i) => SizedBox(
                                          width:
                                              (constraints.maxWidth - 12) / 2,
                                          child: KPICard(
                                            kpi: kpis[i],
                                            icon:
                                                icons[i % icons.length],
                                            color:
                                                colors[i % colors.length],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Charts row
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth > 800) {
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: TrendChart(
                                              data:
                                                  dashProvider.tendencias,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: RiskChart(
                                              distribution: dashProvider
                                                  .resumo
                                                  .distribuicaoRisco,
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    return Column(
                                      children: [
                                        TrendChart(
                                            data:
                                                dashProvider.tendencias),
                                        const SizedBox(height: 16),
                                        RiskChart(
                                          distribution: dashProvider
                                              .resumo.distribuicaoRisco,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Participation bar chart
                                _buildParticipationChart(context),
                                const SizedBox(height: 24),

                                // Recent alerts
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'Alertas Recentes',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () {
                                                Navigator
                                                    .pushReplacementNamed(
                                                  context,
                                                  AppRoutes.webAlerts,
                                                );
                                              },
                                              child: const Text(
                                                  'Ver todos'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...dashProvider.alerts
                                            .take(3)
                                            .map((alert) => Padding(
                                                  padding:
                                                      const EdgeInsets
                                                          .only(
                                                          bottom: 8),
                                                  child: AlertCard(
                                                    alert: alert,
                                                    onMarkRead: () {
                                                      dashProvider
                                                          .markAlertAsRead(
                                                              alert.id);
                                                    },
                                                  ),
                                                )),
                                        if (dashProvider.alerts.isEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.all(20),
                                            child: Center(
                                              child: Text(
                                                'Nenhum alerta recente',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.5),
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
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationChart(BuildContext context) {
    final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    final values = [85.0, 78.0, 92.0, 88.0, 75.0, 30.0, 15.0];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Participacao por Dia da Semana',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${days[group.x]}\n${rod.toY.toStringAsFixed(0)}%',
                          const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.secondaryTeal,
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
