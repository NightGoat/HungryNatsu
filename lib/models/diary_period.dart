enum DiaryPeriod {
  morning('06:00–12:00'),
  afternoon('12:00–18:00'),
  evening('18:00–24:00'),
  night('00:00–06:00');

  const DiaryPeriod(this.timeRange);

  final String timeRange;

  static DiaryPeriod forTime(DateTime time) => switch (time.hour) {
    >= 6 && < 12 => morning,
    >= 12 && < 18 => afternoon,
    >= 18 => evening,
    _ => night,
  };
}
