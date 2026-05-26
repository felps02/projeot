import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assessment_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/mobile/daily_checkin_card.dart';
import '../../widgets/mobile/emergency_button.dart';
import '../../widgets/mobile/risk_indicator.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final assessmentProvider = context.read<AssessmentProvider>();
      assessmentProvider.checkToday(user.id);
      assessmentProvider.loadHistory(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          _buildAssessmentNav(),
          _buildHistoryNav(),
          _buildProfileNav(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Avaliacao',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Historico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: EmergencyButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.emergency);
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    final authProvider = context.watch<AuthProvider>();
    final assessmentProvider = context.watch<AssessmentProvider>();
    final user = authProvider.user;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryBlue, AppTheme.secondaryTeal],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${Helpers.getGreeting()}, ${user != null ? Helpers.getFirstName(user.nome) : ""}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatDateFull(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Daily check-in card
              DailyCheckinCard(
                completed: assessmentProvider.todayDone,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.assessment).then((_) {
                    if (user != null) {
                      assessmentProvider.checkToday(user.id);
                      assessmentProvider.loadHistory(user.id);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Risk indicator
              if (assessmentProvider.isLoading)
                const LoadingWidget(itemCount: 1, height: 180)
              else ...[
                FadeInUp(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Seu Nivel de Risco',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          RiskIndicator(
                            score: assessmentProvider.lastAssessment?.scoreRisco ?? 0,
                            level: assessmentProvider.lastAssessment?.nivelRisco ?? 'baixo',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mini chart - last 7 days
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ultimos 7 dias',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 120,
                            child: _buildMiniChart(assessmentProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Quick stats
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Avaliacoes',
                          '${assessmentProvider.totalAssessments}',
                          Icons.assignment_turned_in,
                          AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Sequencia',
                          '${assessmentProvider.streakDays} dias',
                          Icons.local_fire_department,
                          AppTheme.riskHigh,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChart(AssessmentProvider provider) {
    final assessments = provider.assessments.take(7).toList().reversed.toList();

    if (assessments.isEmpty) {
      return Center(
        child: Text(
          'Realize suas avaliacoes para ver o grafico',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
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
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= assessments.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  Helpers.getDayOfWeekShort(assessments[index].data.weekday),
                  style: TextStyle(
                    fontSize: 10,
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
        lineBarsData: [
          LineChartBarData(
            spots: assessments.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.scoreRisco);
            }).toList(),
            isCurved: true,
            color: AppTheme.primaryBlue,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primaryBlue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.2),
                  AppTheme.primaryBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentNav() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_rounded, size: 64, color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          const Text(
            'Avaliacao Diaria',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.assessment);
            },
            child: const Text('Iniciar Avaliacao'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryNav() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.history);
        },
        child: const Text('Ver Historico'),
      ),
    );
  }

  Widget _buildProfileNav() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.profile);
        },
        child: const Text('Ver Perfil'),
      ),
    );
  }
}
