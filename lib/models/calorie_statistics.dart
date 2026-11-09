import 'diary_entry.dart';

class DailyCalories {
  const DailyCalories(this.day, this.calories, this.hasEntries);

  final DateTime day;
  final double calories;
  final bool hasEntries;
}

class CalorieStatistics {
  CalorieStatistics({
    required DateTime firstDay,
    required int dayCount,
    required List<DiaryEntry> entries,
  }) {
    final totals = <DateTime, double>{};
    for (final entry in entries) {
      final date = entry.eatenAt;
      final day = DateTime(date.year, date.month, date.day);
      totals.update(
        day,
        (value) => value + entry.calories,
        ifAbsent: () => entry.calories,
      );
    }
    days = List.generate(dayCount, (index) {
      final day = DateTime(firstDay.year, firstDay.month, firstDay.day + index);
      return DailyCalories(day, totals[day] ?? 0, totals.containsKey(day));
    });
    final recorded =
        days.where((day) => day.hasEntries).map((day) => day.calories).toList()
          ..sort();
    median = recorded.isEmpty
        ? null
        : recorded.length.isOdd
        ? recorded[recorded.length ~/ 2]
        : (recorded[recorded.length ~/ 2 - 1] +
                  recorded[recorded.length ~/ 2]) /
              2;
  }

  late final List<DailyCalories> days;
  late final double? median;
}
