import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:progress_pals/core/theme/theme_extensions.dart';
import 'package:progress_pals/data/models/habit_model.dart';

class HabitDetailPage extends StatefulWidget {
  final HabitModel? habit;
  const HabitDetailPage({super.key, this.habit});

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  late List<Map<String, dynamic>> weeklyData;
  late double maxY;
  late double avgY;

  List<Color> gradientColors = [Colors.purple, Colors.purpleAccent];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      weeklyData = _buildWeeklyCounts(widget.habit!);

      // --- 1. SET MAX Y TO WEEKLY TARGET ---
      // IMPORTANT: Change '.frequency' to the actual property name in your 
      // HabitModel that stores the repeat-per-week target (e.g., .targetDays)
      maxY = widget.habit!.repeatPerWeek.toDouble(); 

      // Calculate Average for the avgData chart (if you ever toggle it)
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

  List<Map<String, dynamic>> _buildWeeklyCounts(HabitModel habit) {
    final now = DateTime.now();

    // 1. Default starting point: 1 week back
    DateTime earliestDate = now.subtract(const Duration(days: 14));

    // 2. If the habit has older completions, adjust the starting point to the oldest date
    if (habit.completionDates != null && habit.completionDates!.isNotEmpty) {
      final oldestCompletion = habit.completionDates!.reduce((a, b) => a.isBefore(b) ? a : b);
      if (oldestCompletion.isBefore(earliestDate)) {
        earliestDate = oldestCompletion;
      }
    }

    DateTime currentWeekStart = _weekStart(now);
    DateTime iterationWeek = _weekStart(earliestDate);

    // 3. Dynamically build the weeks from the start point to "Now"
    final List<DateTime> weekStarts = [];
    while (iterationWeek.isBefore(currentWeekStart) || iterationWeek.isAtSameMomentAs(currentWeekStart)) {
      weekStarts.add(iterationWeek);
      iterationWeek = iterationWeek.add(const Duration(days: 7));
    }

    // 4. Create the empty count map for our dynamic weeks
    final Map<String, int> counts = {
      for (final ws in weekStarts) ws.toIso8601String(): 0,
    };

    // 5. Fill in the actual completion data
    if (habit.completionDates != null && habit.completionDates!.isNotEmpty) {
      for (final d in habit.completionDates!) {
        final ws = _weekStart(d);
        final key = ws.toIso8601String();
        if (counts.containsKey(key)) {
          counts[key] = counts[key]! + 1;
        }
      }
    } else {
      // Fallback for habits with a count but no specific dates
      final key = _weekStart(now).toIso8601String();
      if (counts.containsKey(key)) counts[key] = habit.completedCount;
    }

    // 6. Format for the chart
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
              'Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // --- THE CHART AREA ---
            SizedBox(
              height: 280,
              child: Card(
                color: context.themeBackground,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 24, // Added a little more padding on the right to prevent cutoff
                    left: 12,
                    top: 24,
                    bottom: 12,
                  ),
                  child: LineChart(mainData()),
                ),
              ),
            ),
            
            // --- 3. WRAP WIDGET REMOVED FROM HERE ---
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
        
        // --- 2. ADDED X-AXIS LABEL ("Weeks") ---
        bottomTitles: AxisTitles(
          axisNameWidget: const Text(
            'Weeks',
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: Color(0xff68737d),
            ),
          ),
          axisNameSize: 32,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        
        // --- 2. ADDED Y-AXIS LABEL ("Completions") ---
        leftTitles: AxisTitles(
          axisNameWidget: const Text(
            'Completions',
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: Color(0xff67727d),
            ),
          ),
          axisNameSize: 32, // Gives space for the text
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 24, // Adjusted to fit alongside the axis name
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Color(0xff37434d), width: 1),
          bottom: BorderSide(color: Color(0xff37434d), width: 1),
        ),
      ),
      minX: 0,
      maxX: (weeklyData.length - 1).toDouble(), // Fixed to perfectly align data at the end
      minY: 0,
      maxY: maxY == 0 ? 1 : maxY, // Now strictly respects your weekly target
      lineBarsData: [
        LineChartBarData(
          preventCurveOverShooting: true,
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