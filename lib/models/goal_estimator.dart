import 'dart:math' as math;

enum GoalMode { loss, maintenance, muscle }

enum BiologicalSex { female, male }

enum ActivityLevel { sedentary, light, moderate, high }

extension ActivityFactor on ActivityLevel {
  double get factor => switch (this) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.light => 1.375,
    ActivityLevel.moderate => 1.55,
    ActivityLevel.high => 1.725,
  };
}

class GoalEstimate {
  const GoalEstimate({
    required this.protein,
    this.calories,
    this.maintenance,
    this.fat,
    this.carbs,
  });
  final int protein;
  final int? calories;
  final int? maintenance;
  final int? fat;
  final int? carbs;
}

/// An initial estimate for adults; activity factors and intake need calibration
/// against the person's observed weight trend over several weeks.
GoalEstimate estimateGoal({
  required GoalMode mode,
  required double weightKg,
  BiologicalSex? sex,
  int? ageYears,
  double? heightCm,
  ActivityLevel activity = ActivityLevel.sedentary,
}) {
  if (!weightKg.isFinite || weightKg < 30 || weightKg > 300) {
    throw ArgumentError.value(weightKg, 'weightKg');
  }
  final proteinPerKg = switch (mode) {
    GoalMode.loss => 1.6,
    GoalMode.maintenance => 0.8,
    GoalMode.muscle => 1.8,
  };
  final protein = (weightKg * proteinPerKg).round();
  if (sex == null || ageYears == null || heightCm == null) {
    return GoalEstimate(protein: protein);
  }
  if (ageYears < 18 ||
      ageYears > 100 ||
      !heightCm.isFinite ||
      heightCm < 120 ||
      heightCm > 230) {
    throw ArgumentError('Invalid age or height');
  }
  // Mifflin–St Jeor (1990), then an activity multiplier for daily expenditure.
  final resting =
      10 * weightKg +
      6.25 * heightCm -
      5 * ageYears +
      (sex == BiologicalSex.male ? 5 : -161);
  final maintenance = (resting * activity.factor).round();
  final calories = switch (mode) {
    GoalMode.loss =>
      math
          .min(
            maintenance,
            math.max(
              sex == BiologicalSex.male ? 1500 : 1200,
              maintenance - math.min(500, (maintenance * 0.15).round()),
            ),
          )
          .toInt(),
    GoalMode.maintenance => maintenance,
    GoalMode.muscle => (maintenance * 1.10).round(),
  };
  // Keep protein within 30% of the energy budget, reserve 25% for fat,
  // and give the remaining energy to carbohydrate (4/9/4 kcal per gram).
  final energyAdjustedProtein = math.min(
    protein,
    (calories * 0.30 / 4).floor(),
  );
  final fat = (calories * 0.25 / 9).round();
  final carbs = ((calories - energyAdjustedProtein * 4 - fat * 9) / 4).round();
  return GoalEstimate(
    protein: energyAdjustedProtein,
    calories: calories,
    maintenance: maintenance,
    fat: fat,
    carbs: carbs,
  );
}
