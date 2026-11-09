import 'package:flutter/material.dart';

import '../models/goal_estimator.dart';
import 'strings.dart';

class GoalHelperResult {
  const GoalHelperResult({
    required this.protein,
    this.calories,
    this.fat,
    this.carbs,
  });
  final int protein;
  final int? calories;
  final int? fat;
  final int? carbs;
}

class GoalHelperPage extends StatefulWidget {
  const GoalHelperPage({super.key});

  @override
  State<GoalHelperPage> createState() => _GoalHelperPageState();
}

class _GoalHelperPageState extends State<GoalHelperPage> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();
  GoalMode _mode = GoalMode.maintenance;
  BiologicalSex? _sex;
  ActivityLevel _activity = ActivityLevel.sedentary;
  GoalEstimate? _estimate;
  String? _error;
  bool _underweight = false;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  void _calculate() {
    final s = S.of(context);
    final weight = _number(_weight);
    if (weight == null || !weight.isFinite || weight < 30 || weight > 300) {
      setState(() {
        _error = s.helperInvalidWeight;
        _estimate = null;
      });
      return;
    }
    final anyCalorieInput =
        _sex != null ||
        _age.text.trim().isNotEmpty ||
        _height.text.trim().isNotEmpty;
    final age = int.tryParse(_age.text.trim());
    final height = _number(_height);
    if (anyCalorieInput &&
        (_sex == null ||
            age == null ||
            age < 18 ||
            age > 100 ||
            height == null ||
            !height.isFinite ||
            height < 120 ||
            height > 230)) {
      setState(() {
        _error = s.helperInvalidDetails;
        _estimate = null;
      });
      return;
    }
    final underweight =
        _mode == GoalMode.loss &&
        height != null &&
        weight / (height / 100 * height / 100) < 18.5;
    final estimate = estimateGoal(
      mode: _mode,
      weightKg: weight,
      sex: underweight ? null : _sex,
      ageYears: underweight ? null : age,
      heightCm: underweight ? null : height,
      activity: _activity,
    );
    setState(() {
      _estimate = estimate;
      _underweight = underweight;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final estimate = _estimate;
    return Scaffold(
      appBar: AppBar(title: Text(s.helperTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(s.helperIntro),
          const SizedBox(height: 12),
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s.helperPrivacy)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final (mode, label) in [
                (GoalMode.loss, s.helperLoss),
                (GoalMode.maintenance, s.helperMaintain),
                (GoalMode.muscle, s.helperMuscle),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() {
                    _mode = mode;
                    _estimate = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.helperWeight,
              suffixText: s.t('кг', 'kg'),
            ),
            onChanged: (_) => setState(() => _estimate = null),
          ),
          const SizedBox(height: 12),
          Text(s.helperCaloriesOptional),
          const SizedBox(height: 12),
          DropdownButtonFormField<BiologicalSex>(
            isExpanded: true,
            initialValue: _sex,
            decoration: InputDecoration(labelText: s.helperSex),
            items: [
              DropdownMenuItem(
                value: BiologicalSex.female,
                child: Text(s.helperFemale),
              ),
              DropdownMenuItem(
                value: BiologicalSex.male,
                child: Text(s.helperMale),
              ),
            ],
            onChanged: (value) => setState(() {
              _sex = value;
              _estimate = null;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: s.helperAge),
            onChanged: (_) => setState(() => _estimate = null),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.helperHeight,
              suffixText: s.t('см', 'cm'),
            ),
            onChanged: (_) => setState(() => _estimate = null),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ActivityLevel>(
            isExpanded: true,
            initialValue: _activity,
            decoration: InputDecoration(labelText: s.helperActivity),
            items: [
              DropdownMenuItem(
                value: ActivityLevel.sedentary,
                child: Text(s.helperSedentary),
              ),
              DropdownMenuItem(
                value: ActivityLevel.light,
                child: Text(s.helperLight),
              ),
              DropdownMenuItem(
                value: ActivityLevel.moderate,
                child: Text(s.helperModerate),
              ),
              DropdownMenuItem(
                value: ActivityLevel.high,
                child: Text(s.helperHigh),
              ),
            ],
            onChanged: (value) => setState(() {
              _activity = value ?? ActivityLevel.sedentary;
              _estimate = null;
            }),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _calculate, child: Text(s.helperCalculate)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (estimate != null) ...[
            const SizedBox(height: 20),
            Text(
              s.helperResult,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (estimate.calories != null) ...[
              Text(s.helperMaintenanceValue(estimate.maintenance!)),
              Text(s.helperCaloriesValue(estimate.calories!)),
            ],
            Text(s.helperProteinValue(estimate.protein)),
            if (estimate.fat != null) Text(s.helperFatValue(estimate.fat!)),
            if (estimate.carbs != null)
              Text(s.helperCarbsValue(estimate.carbs!)),
            if (_underweight) Text(s.helperUnderweight),
            if (estimate.calories != null &&
                _mode == GoalMode.loss &&
                estimate.calories == estimate.maintenance)
              Text(s.helperNoDeficit),
            const SizedBox(height: 12),
            Text(s.helperMethod),
            const SizedBox(height: 12),
            Text(s.helperCaution),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                GoalHelperResult(
                  protein: estimate.protein,
                  calories: estimate.calories,
                  fat: estimate.fat,
                  carbs: estimate.carbs,
                ),
              ),
              child: Text(s.helperUse),
            ),
          ],
        ],
      ),
    );
  }
}
