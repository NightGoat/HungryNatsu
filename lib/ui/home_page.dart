import 'dart:math';

import 'package:flutter/material.dart';

import '../data/food_repository.dart';
import '../models/diary_entry.dart';
import '../models/diary_period.dart';
import '../models/daily_goals.dart';
import '../models/product.dart';
import 'dishes_page.dart';
import 'food_weight_dialog.dart';
import 'product_picker_page.dart';
import 'account_page.dart';
import 'strings.dart';
import 'statistics_page.dart';

DateTime oldestDiaryDay(DateTime today) {
  final month = DateTime(today.year, today.month - 3);
  final lastDay = DateTime(today.year, today.month - 2, 0).day;
  return DateTime(month.year, month.month, min(today.day, lastDay));
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.online,
    this.onLanguageChanged,
  });
  final FoodRepository repository;
  final bool online;
  final ValueChanged<String>? onLanguageChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _day = DateTime.now();
  List<DiaryEntry> _entries = [];
  bool _loading = true;
  DailyGoals _goals = const DailyGoals();
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    try {
      final goals = await widget.repository.dailyGoals();
      if (mounted) setState(() => _goals = goals);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openAccount() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AccountPage(
          repository: widget.repository,
          online: widget.online,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );
    if (saved == true && mounted) await _loadGoal();
  }

  Future<void> _load() async {
    final request = ++_loadRequest;
    final day = _day;
    setState(() => _loading = true);
    try {
      final entries = await widget.repository.entriesFor(day);
      if (mounted && request == _loadRequest) {
        setState(() => _entries = entries);
      }
    } catch (error) {
      if (request == _loadRequest) _showError(error);
    } finally {
      if (mounted && request == _loadRequest) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).error(error))));
  }

  Future<void> _addFood() async {
    final product = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => ProductPickerPage(repository: widget.repository),
      ),
    );
    if (product == null || !mounted) return;
    final grams = await showDialog<double>(
      context: context,
      builder: (_) => FoodWeightDialog(product: product),
    );
    if (grams == null || !mounted) return;
    await _addEntry(product, grams);
  }

  Future<void> _addDish() async {
    final selection = await Navigator.of(context).push<DishSelection>(
      MaterialPageRoute(
        builder: (_) => DishesPage(repository: widget.repository),
      ),
    );
    if (selection == null || !mounted) return;
    final (dish, servings) = selection;
    await _addEntry(
      dish.diaryProduct,
      dish.gramsFor(servings),
      servings: servings,
    );
  }

  Future<void> _addEntry(
    Product product,
    double grams, {
    double? servings,
  }) async {
    try {
      final now = DateTime.now();
      await widget.repository.addEntry(
        DiaryEntry(
          id: '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
          product: product,
          grams: grams,
          servings: servings,
          eatenAt: DateTime(
            _day.year,
            _day.month,
            _day.day,
            now.hour,
            now.minute,
          ),
        ),
      );
      if (mounted) await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _delete(DiaryEntry entry) async {
    try {
      await widget.repository.deleteEntry(entry.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).entryDeleted),
          action: SnackBarAction(
            label: S.of(context).undo,
            onPressed: () async {
              try {
                await widget.repository.addEntry(entry);
                if (mounted) await _load();
              } catch (error) {
                _showError(error);
              }
            },
          ),
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _chooseDay() async {
    final today = DateTime.now();
    final firstDate = oldestDiaryDay(today);
    final selected = await showDatePicker(
      context: context,
      initialDate: _day.isBefore(firstDate) ? firstDate : _day,
      firstDate: firstDate,
      lastDate: today,
    );
    if (selected == null || !mounted) return;
    _day = selected;
    await _load();
  }

  void _shiftDay(int days) {
    final next = DateTime(_day.year, _day.month, _day.day + days);
    if (next.isBefore(oldestDiaryDay(DateTime.now()))) return;
    _day = next;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final calories = _entries.fold<double>(0, (sum, e) => sum + e.calories);
    final protein = _entries.fold<double>(0, (sum, e) => sum + e.protein);
    final fat = _entries.fold<double>(0, (sum, e) => sum + e.fat);
    final carbs = _entries.fold<double>(0, (sum, e) => sum + e.carbs);
    final today = DateTime.now();
    final oldestDay = oldestDiaryDay(today);
    final isToday = DateUtils.isSameDay(_day, today);
    final dateLabel = isToday
        ? s.today
        : MaterialLocalizations.of(context).formatMediumDate(_day);
    final goal = _goals.calories;
    final remaining = goal == null ? null : goal - calories.round();
    final entriesByPeriod = <DiaryPeriod, List<DiaryEntry>>{};
    for (final entry in _entries) {
      (entriesByPeriod[DiaryPeriod.forTime(entry.eatenAt)] ??= []).add(entry);
    }
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                'assets/natsu_icon.png',
                width: 34,
                height: 34,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Hungry Natsu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.myDishes,
            icon: const Icon(Icons.restaurant_menu_rounded),
            onPressed: _addDish,
          ),
          IconButton(
            tooltip: s.statistics,
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StatisticsPage(repository: widget.repository),
              ),
            ),
          ),
          IconButton(
            tooltip: s.account,
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: _openAccount,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            if (!widget.online) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_outlined),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.localModeNotice)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  tooltip: s.previousDay,
                  onPressed: _day.isAfter(oldestDay)
                      ? () => _shiftDay(-1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _chooseDay,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: s.nextDay,
                  onPressed: isToday ? null : () => _shiftDay(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF49382E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? s.eatenToday : s.eatenOnDay,
                    style: const TextStyle(
                      color: Color(0xFFE9D9C7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        calories.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          s.kcal,
                          style: const TextStyle(
                            color: Color(0xFFE9D9C7),
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (goal != null && goal > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (calories / goal).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFF77665B),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFFC28E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remaining! >= 0
                          ? s.remaining(remaining)
                          : s.overGoal(-remaining),
                      style: const TextStyle(
                        color: Color(0xFFFFE3C9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else
                    TextButton.icon(
                      onPressed: _openAccount,
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(s.setGoal),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFD0A8),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MacroTile(
                  label: s.protein,
                  value: protein,
                  goal: _goals.protein,
                  color: const Color(0xFFCA7653),
                ),
                const SizedBox(width: 8),
                _MacroTile(
                  label: s.fat,
                  value: fat,
                  goal: _goals.fat,
                  color: const Color(0xFFE0AA5C),
                ),
                const SizedBox(width: 8),
                _MacroTile(
                  label: s.carbs,
                  value: carbs,
                  goal: _goals.carbs,
                  color: const Color(0xFF8D9D73),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.diary,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${_entries.length}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_entries.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.ramen_dining_rounded,
                      size: 34,
                      color: Color(0xFFB85D3B),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.emptyDiary,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            else
              for (final period in DiaryPeriod.values)
                if (entriesByPeriod[period] case final entries?) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.diaryPeriod(period),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          period.timeRange,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  for (final entry in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.product.displayName(s.languageCode),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.calories.toStringAsFixed(0)} ${s.kcal}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            entry.servings == null
                                ? '${entry.grams.toStringAsFixed(0)} ${s.grams}'
                                : s.servingsLabel(entry.servings!),
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${s.protein} ${entry.protein.toStringAsFixed(1)} ${s.grams} · ${s.fat} ${entry.fat.toStringAsFixed(1)} ${s.grams} · ${s.carbs} ${entry.carbs.toStringAsFixed(1)} ${s.grams}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _delete(entry),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                                label: Text(s.delete),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFood,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addProduct),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.value,
    this.goal,
    required this.color,
  });

  final String label;
  final double value;
  final double? goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hasGoal = goal != null && goal! > 0;
    final overGoal = hasGoal && value > goal!;
    final balance = !hasGoal
        ? ''
        : overGoal
        ? s.macroOverGoal((value - goal!).toStringAsFixed(1))
        : s.macroRemaining((goal! - value).toStringAsFixed(1));
    return Expanded(
      child: Tooltip(
        message: hasGoal ? '$label: $balance' : label,
        child: Container(
          height: MediaQuery.textScalerOf(context).scale(92),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${value.toStringAsFixed(1)} ${s.grams}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: overGoal ? Theme.of(context).colorScheme.error : null,
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: hasGoal ? (value / goal!).clamp(0.0, 1.0) : 0,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasGoal ? s.macroGoal(goal!.toStringAsFixed(0)) : s.noMacroGoal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
