import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:progress_pals/core/theme/theme_extensions.dart';
import 'package:progress_pals/data/models/habit_model.dart';
import 'package:progress_pals/core/theme/app_colors.dart';

class HabitDetailPage extends StatefulWidget {
  final HabitModel? habit;
  const HabitDetailPage({Key? key, this.habit}) : super(key: key);

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  late List<Map<String, dynamic>> weeklyData;
  late double maxY;
  late double avgY;

  // We use standard colors here to match the sample's vibe,
  // but you can replace these with AppColors.contentColorCyan etc.
  List<Color> gradientColors = [Colors.purple, Colors.purpleAccent];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      weeklyData = _buildWeeklyCounts(widget.habit!);

      // Calculate Max Y for chart boundaries
      int maxCount = weeklyData
          .map((e) => e['count'] as int)
          .fold<int>(0, (p, n) => n > p ? n : p);
      maxY = (maxCount + 1).toDouble(); // Add 1 for top padding

      // Calculate Average for the avgData chart
      int totalCount = weeklyData
          .map((e) => e['count'] as int)
          .fold<int>(0, (p, n) => p + n);
      avgY = weeklyData.isNotEmpty ? totalCount / weeklyData.length : 0;
    }
  }

  // Compute week start (Monday) for a date
  DateTime _weekStart(DateTime d) {
    return DateTime(
      d.year,
      d.month,
      d.day,
    ).subtract(Duration(days: d.weekday - 1));
  }

  List<Map<String, dynamic>> _buildWeeklyCounts(
    HabitModel habit, {
    int weeks = 8,
  }) {
    final now = DateTime.now();
    final List<DateTime> weekStarts = List.generate(weeks, (i) {
      final start = _weekStart(now).subtract(Duration(days: 7 * i));
      return DateTime(start.year, start.month, start.day);
    }).reversed.toList();

    final Map<String, int> counts = {
      for (final ws in weekStarts) ws.toIso8601String(): 0,
    };

    if (habit.completionDates != null && habit.completionDates!.isNotEmpty) {
      for (final d in habit.completionDates!) {
        final ws = _weekStart(d);
        final key = ws.toIso8601String();
        if (counts.containsKey(key)) {
          counts[key] = counts[key]! + 1;
        }
      }
    } else {
      final key = _weekStart(now).toIso8601String();
      if (counts.containsKey(key)) counts[key] = habit.completedCount;
    }

    return counts.entries.map((e) {
      final dt = DateTime.parse(e.key);
      final label = '${dt.month}/${dt.day}';
      return {'label': label, 'count': e.value};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habit')),
        body: const Center(child: Text('No habit selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.habit!.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.habit!.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Completions per Week',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // --- THE REFACTORED CHART AREA ---
            SizedBox(
              height: 280,
              child: Card(
                color: context.themeBackground,
                child: Stack(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 18,
                        left: 12,
                        top: 24,
                        bottom: 12,
                      ),
                      child: LineChart(mainData()),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: SizedBox(width: 60, height: 34),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------------------------
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: weeklyData
                  .map(
                    (w) => Chip(label: Text('${w['label']} : ${w['count']}')),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: Color(0xff68737d),
    );

    final idx = value.toInt();
    if (idx < 0 || idx >= weeklyData.length) {
      return const SizedBox.shrink();
    }

    // To prevent crowding, skip some labels if there are many weeks
    if (weeklyData.length > 6 && idx % 2 != 0) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(weeklyData[idx]['label'], style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Color(0xff67727d),
    );

    // Only show integer labels on the Y axis
    if (value == value.toInt().toDouble()) {
      return Text(
        value.toInt().toString(),
        style: style,
        textAlign: TextAlign.left,
      );
    }
    return const SizedBox.shrink();
  }

  LineChartData mainData() {
    final spots = weeklyData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble());
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Color(0xff37434d), strokeWidth: 0);
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(color: Color(0xff37434d), strokeWidth: 0);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: Color(0xff37434d), width: 1),
          bottom: BorderSide(color: Color(0xff37434d), width: 1),
        ),
      ),
      minX: 0,
      maxX: (weeklyData.length + 1).toDouble(),
      minY: 0,
      maxY: maxY == 0 ? 1 : maxY, // Default to 5 if no data
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
