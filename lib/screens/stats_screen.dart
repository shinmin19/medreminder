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
  String _selectedPeriod = 'week';
  List<FlSpot> _chartData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  void _loadStats() {
    // Generate chart data from monthly stats
    _generateChartData();
  }

  void _generateChartData() {
    // Simulated weekly data - in production, query from DB
    _chartData = List.generate(7, (i) {
      return FlSpot(i.toDouble(), (60 + i * 5 + (i % 3) * 10).toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 统计报告'),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 16),
              _buildAdherenceCard(provider),
              const SizedBox(height: 16),
              _buildTrendChart(),
              const SizedBox(height: 16),
              _buildDetailedStats(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildPeriodButton('week', '本周'),
            _buildPeriodButton('month', '本月'),
            _buildPeriodButton('all', '全部'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdherenceCard(MedicationProvider provider) {
    Map<String, dynamic> stats;
    String periodLabel;
    
    switch (_selectedPeriod) {
      case 'week':
        stats = provider.weekStats;
        periodLabel = '本周';
        break;
      case 'month':
        stats = provider.monthStats;
        periodLabel = '本月';
        break;
      default:
        stats = provider.monthStats;
        periodLabel = '全部';
    }

    final rate = stats['adherenceRate'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final total = stats['total'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '$periodLabel服药依从率',
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: taken.toDouble(),
                      color: AppTheme.takenColor,
                      radius: 30,
                      title: '$taken',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: (total - taken).toDouble(),
                      color: Colors.grey[200],
                      radius: 30,
                      title: '${total - taken}',
                      titleStyle: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$rate%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: rate >= 80 ? AppTheme.takenColor : 
                       rate >= 50 ? AppTheme.pendingColor : AppTheme.missedColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rate >= 80 ? '🎉 服药习惯很好！继续保持！' :
              rate >= 50 ? '⚠️ 还需要加油哦！' : '❌ 请记得按时服药！',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 服药趋势',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final days = ['一', '二', '三', '四', '五', '六', '日'];
                          final index = value.toInt();
                          if (index >= 0 && index < 7) {
                            return Text(days[index], style: const TextStyle(fontSize: 12));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', 
                            style: const TextStyle(fontSize: 11));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData,
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(MedicationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 详细数据',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('今日服用', '${provider.todayTaken}次', AppTheme.takenColor),
            _buildStatRow('今日漏服', '${provider.todayMissed}次', AppTheme.missedColor),
            _buildStatRow('今日待服', '${provider.todayPending}次', AppTheme.pendingColor),
            const Divider(),
            _buildStatRow('本月服用', '${provider.monthStats['taken'] ?? 0}次', AppTheme.takenColor),
            _buildStatRow('本月漏服', '${provider.monthStats['missed'] ?? 0}次', AppTheme.missedColor),
            _buildStatRow('本月总次数', '${provider.monthStats['total'] ?? 0}次', AppTheme.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
