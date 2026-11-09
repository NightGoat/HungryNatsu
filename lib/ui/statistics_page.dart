import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/food_repository.dart';
import '../models/calorie_statistics.dart';
import 'strings.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.repository});

  final FoodRepository repository;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _dayCount = 7;
  CalorieStatistics? _statistics;
  bool _loading = true;
  Object? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    final today = DateTime.now();
    final firstDay = DateTime(
      today.year,
      today.month,
      today.day - _dayCount + 1,
    );
    final end = DateTime(today.year, today.month, today.day + 1);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await widget.repository.entriesBetween(firstDay, end);
      if (!mounted || request != _request) return;
      setState(() {
        _statistics = CalorieStatistics(
          firstDay: firstDay,
          dayCount: _dayCount,
          entries: entries,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final stats = _statistics;
    return Scaffold(
      appBar: AppBar(title: Text(s.statistics)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              s.calorieTrend,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              s.statisticsDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 7, label: Text(s.last7Days)),
                ButtonSegment(value: 30, label: Text(s.last30Days)),
              ],
              selected: {_dayCount},
              onSelectionChanged: (selection) {
                setState(() => _dayCount = selection.first);
                _load();
              },
            ),
            const SizedBox(height: 20),
            if (_loading)
              const SizedBox(
                height: 330,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Text(s.error(_error!)),
                    TextButton(onPressed: _load, child: Text(s.retry)),
                  ],
                ),
              )
            else if (stats != null) ...[
              _StatisticsChart(statistics: stats),
              const SizedBox(height: 16),
              Text(
                s.medianExplanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatisticsChart extends StatelessWidget {
  const _StatisticsChart({required this.statistics});

  final CalorieStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final median = statistics.median;
    final maxCalories = statistics.days.fold<double>(
      0,
      (max, day) => math.max(max, day.calories),
    );
    final scale = math.max(1.0, math.max(maxCalories, median ?? 0) * 1.15);
    final dates = MaterialLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.dailyCalories,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              median == null
                  ? s.noStatistics
                  : '${s.median}: ${median.round()} ${s.kcal}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFFB85D3B),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${scale.ceil()} ${s.kcal}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final day in statistics.days)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: statistics.days.length == 7
                                    ? 4
                                    : 1.5,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: day.hasEntries
                                      ? math.max(day.calories / scale, 0.012)
                                      : 0.012,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: day.hasEntries
                                          ? const Color(0xFFB85D3B)
                                          : colors.outlineVariant,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (median != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 220 * median / scale,
                      child: const _MedianLine(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dates.formatShortDate(statistics.days.first.day)),
                Text(dates.formatShortDate(statistics.days.last.day)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB85D3B),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 7),
                Text(s.dailyCalories),
                const SizedBox(width: 18),
                Container(width: 20, height: 2, color: const Color(0xFFDBA662)),
                const SizedBox(width: 7),
                Text(s.median),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MedianLine extends StatelessWidget {
  const _MedianLine();

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(double.infinity, 2),
    painter: _DashedLinePainter(),
  );
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDBA662)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, 1),
        Offset(math.min(x + 6, size.width), 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
