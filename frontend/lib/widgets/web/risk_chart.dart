import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/helpers.dart';

class RiskChart extends StatefulWidget {
  final Map<String, int> distribution;

  const RiskChart({super.key, required this.distribution});

  @override
  State<RiskChart> createState() => _RiskChartState();
}

class _RiskChartState extends State<RiskChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.distribution.values.fold<int>(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribuicao de Risco',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = response
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: _buildSections(total),
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.distribution.entries.map((entry) {
                        final percent = total > 0
                            ? (entry.value / total * 100).toStringAsFixed(1)
                            : '0';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Helpers.getRiskColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${Helpers.getRiskLabel(entry.key)} ($percent%)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(int total) {
    int index = 0;
    return widget.distribution.entries.map((entry) {
      final isTouched = _touchedIndex == index;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final percent =
          total > 0 ? (entry.value / total * 100).toStringAsFixed(0) : '0';

      final section = PieChartSectionData(
        color: Helpers.getRiskColor(entry.key),
        value: entry.value.toDouble(),
        title: '$percent%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      index++;
      return section;
    }).toList();
  }
}
