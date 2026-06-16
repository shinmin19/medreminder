import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/medication_provider.dart';
import '../utils/theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用药统计'),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          final allRecords = provider.records;
          final totalDoses = allRecords.length;
          final takenDoses = allRecords.where((r) => r.isTaken).length;
          final skippedDoses = allRecords.where((r) => r.isSkipped).length;
          final pendingDoses = totalDoses - takenDoses - skippedDoses;

          final adherenceRate =
              totalDoses > 0 ? (takenDoses / totalDoses * 100).round() : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '总用药次数',
                        '$totalDoses',
                        Icons.medication,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '服药率',
                        '$adherenceRate%',
                        Icons.trending_up,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '已服用',
                        '$takenDoses',
                        Icons.check_circle,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '已跳过',
                        '$skippedDoses',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pie chart
                const Text(
                  '服药情况分布',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: _buildPieSections(
                        takenDoses,
                        skippedDoses,
                        pendingDoses,
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(),

                const SizedBox(height: 24),

                // Bar chart - weekly trend
                const Text(
                  '近期趋势',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['一', '二', '三', '四', '五', '六', '日'];
                              final now = DateTime.now();
                              final weekday = now.weekday - 7 + value.toInt();
                              final targetDay = now.add(Duration(days: weekday));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  days[value.toInt() % 7],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}',
                                  style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _buildBarGroups(provider),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Per-medication stats
                if (provider.medications.isNotEmpty) ...[
                  const Text(
                    '各药物统计',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...provider.medications.map((med) {
                    final medRecords = allRecords
                        .where((r) => r.medicationId == med.id)
                        .toList();
                    final medTaken = medRecords.where((r) => r.isTaken).length;
                    final medTotal = medRecords.length;
                    final rate = medTotal > 0
                        ? (medTaken / medTotal * 100).round()
                        : 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.medication,
                              color: AppTheme.primaryColor),
                        ),
                        title: Text(med.name),
                        subtitle: LinearProgressIndicator(
                          value: medTotal > 0 ? medTaken / medTotal : 0,
                          backgroundColor: Colors.grey[200],
                          color: AppTheme.primaryColor,
                        ),
                        trailing: Text(
                          '$rate%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      int taken, int skipped, int pending) {
    final total = taken + skipped + pending;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: '暂无数据',
          color: Colors.grey[300]!,
          radius: 50,
        ),
      ];
    }

    return List.generate(3, (i) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final values = [taken.toDouble(), pending.toDouble(), skipped.toDouble()];
      final colors = [AppTheme.primaryColor, Colors.orange, Colors.red];
      final labels = ['已服用', '待服用', '已跳过'];

      return PieChartSectionData(
        value: values[i],
        title: '${(values[i] / total * 100).round()}%',
        color: colors[i],
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('已服用', AppTheme.primaryColor),
        const SizedBox(width: 16),
        _legendItem('待服用', Colors.orange),
        const SizedBox(width: 16),
        _legendItem('已跳过', Colors.red),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(MedicationProvider provider) {
    return List.generate(7, (i) {
      final now = DateTime.now();
      final day = now.subtract(Duration(days: 6 - i));
      final dayRecords = provider.getRecordsForDate(day);
      final taken = dayRecords.where((r) => r.isTaken).length.toDouble();

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: taken,
            color: AppTheme.primaryColor,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}
