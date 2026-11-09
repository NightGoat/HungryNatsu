import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/food_repository.dart';
import '../models/daily_goals.dart';
import 'goal_helper_page.dart';
import 'strings.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.repository,
    required this.online,
    this.onLanguageChanged,
  });
  final FoodRepository repository;
  final bool online;
  final ValueChanged<String>? onLanguageChanged;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _goal = TextEditingController();
  final _proteinGoal = TextEditingController();
  final _fatGoal = TextEditingController();
  final _carbsGoal = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final goals = await widget.repository.dailyGoals();
      if (!mounted) return;
      if (goals.calories != null) _goal.text = goals.calories.toString();
      _proteinGoal.text = goals.protein?.toString() ?? '';
      _fatGoal.text = goals.fat?.toString() ?? '';
      _carbsGoal.text = goals.carbs?.toString() ?? '';
    } catch (error) {
      if (mounted) setState(() => _message = S.of(context).error(error));
    }
  }

  @override
  void dispose() {
    _goal.dispose();
    _proteinGoal.dispose();
    _fatGoal.dispose();
    _carbsGoal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = S.of(context);
    final value = int.tryParse(_goal.text.trim());
    if (value == null || value < 1 || value > 10000) {
      setState(() => _message = s.invalidGoal);
      return;
    }
    double? parseMacro(TextEditingController controller) {
      final input = controller.text.trim().replaceAll(',', '.');
      if (input.isEmpty) return null;
      return double.tryParse(input);
    }

    final protein = parseMacro(_proteinGoal);
    final fat = parseMacro(_fatGoal);
    final carbs = parseMacro(_carbsGoal);
    final inputs = [_proteinGoal, _fatGoal, _carbsGoal];
    final values = [protein, fat, carbs];
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i].text.trim();
      if (input.isNotEmpty &&
          (values[i] == null ||
              !values[i]!.isFinite ||
              values[i]! < 0 ||
              values[i]! > 10000)) {
        setState(() => _message = s.invalidMacroGoal);
        return;
      }
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository.saveDailyGoals(
        DailyGoals(
          calories: value,
          protein: protein == 0 ? null : protein,
          fat: fat == 0 ? null : fat,
          carbs: carbs == 0 ? null : carbs,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _message = S.of(context).error(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = S.of(context).error(error);
        });
      }
    }
  }

  Future<void> _openHelper() async {
    final result = await Navigator.of(context).push<GoalHelperResult>(
      MaterialPageRoute(builder: (_) => const GoalHelperPage()),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.calories != null) _goal.text = result.calories.toString();
      _proteinGoal.text = result.protein.toString();
      if (result.fat != null) _fatGoal.text = result.fat.toString();
      if (result.carbs != null) _carbsGoal.text = result.carbs.toString();
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final email = widget.online
        ? Supabase.instance.client.auth.currentUser?.email
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(s.account)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (email != null) ...[
            Text(email, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
          ],
          OutlinedButton.icon(
            onPressed: _busy ? null : _openHelper,
            icon: const Icon(Icons.calculate_outlined),
            label: Text(s.helperTitle),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _goal,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.dailyGoal,
              suffixText: s.kcal,
            ),
          ),
          const SizedBox(height: 12),
          for (final (controller, label) in [
            (_proteinGoal, s.protein),
            (_fatGoal, s.fat),
            (_carbsGoal, s.carbs),
          ]) ...[
            TextField(
              controller: controller,
              enabled: !_busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '${s.dailyGoal}: $label',
                suffixText: s.grams,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(s.optionalMacroGoal),
          const SizedBox(height: 12),
          if (_message != null)
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(s.saveGoal),
          ),
          if (widget.online) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _busy ? null : _signOut,
              child: Text(s.signOut),
            ),
          ],
          const SizedBox(height: 28),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language_rounded),
            title: Text(s.language),
            trailing: DropdownButton<String>(
              value: s.languageCode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'ru', child: Text(s.russian)),
                DropdownMenuItem(value: 'en', child: Text(s.english)),
              ],
              onChanged: widget.onLanguageChanged == null
                  ? null
                  : (value) {
                      if (value != null) widget.onLanguageChanged!(value);
                    },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(s.dataSources),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Hungry Natsu',
              children: [Text(s.dataSourcesBody)],
            ),
          ),
        ],
      ),
    );
  }
}
