import 'dart:math';

import 'package:flutter/material.dart';

import '../data/food_repository.dart';
import '../models/dish.dart';
import '../models/product.dart';
import 'food_weight_dialog.dart';
import 'product_picker_page.dart';
import 'strings.dart';

typedef DishSelection = (Dish, double);

class DishesPage extends StatefulWidget {
  const DishesPage({super.key, required this.repository});

  final FoodRepository repository;

  @override
  State<DishesPage> createState() => _DishesPageState();
}

class _DishesPageState extends State<DishesPage> {
  late Future<List<Dish>> _dishes = widget.repository.dishes();

  void _reload() {
    final dishes = widget.repository.dishes();
    setState(() {
      _dishes = dishes;
    });
  }

  Future<void> _edit([Dish? dish]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _DishForm(repository: widget.repository, dish: dish),
      ),
    );
    if (mounted && saved == true) _reload();
  }

  Future<void> _choose(Dish dish) async {
    final servings = await showDialog<double>(
      context: context,
      builder: (_) => _DishServingsDialog(dish: dish),
    );
    if (mounted && servings != null) Navigator.pop(context, (dish, servings));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.myDishes)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.newDish),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Dish>>(
              future: _dishes,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.error(snapshot.error!),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(onPressed: _reload, child: Text(s.retry)),
                      ],
                    ),
                  );
                }
                final dishes = snapshot.data!;
                if (dishes.isEmpty) return Center(child: Text(s.noDishes));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dishes.length,
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    final calories =
                        dish.diaryProduct.calories * dish.gramsFor(1) / 100;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.restaurant_menu_rounded),
                        title: Text(dish.name),
                        subtitle: Text(
                          '${s.servingsLabel(dish.servings)} · '
                          '${s.kcalPerServing(calories.toStringAsFixed(0))}',
                        ),
                        onTap: () => _choose(dish),
                        trailing: IconButton(
                          tooltip: s.editDish,
                          onPressed: () => _edit(dish),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DishForm extends StatefulWidget {
  const _DishForm({required this.repository, this.dish});

  final FoodRepository repository;
  final Dish? dish;

  @override
  State<_DishForm> createState() => _DishFormState();
}

class _DishFormState extends State<_DishForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.dish?.name);
  late final _servings = TextEditingController(
    text: widget.dish?.servings.toString() ?? '1',
  );
  late final _ingredients = [...?widget.dish?.ingredients];
  late final _id =
      widget.dish?.id ??
      'dish-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _servings.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final product = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => ProductPickerPage(repository: widget.repository),
      ),
    );
    if (product == null || !mounted) return;
    await _setWeight(product);
  }

  Future<void> _setWeight(Product product, {int? index}) async {
    final grams = await showDialog<double>(
      context: context,
      builder: (_) => FoodWeightDialog(
        product: product,
        initialGrams: index == null ? 100 : _ingredients[index].grams,
        ingredient: true,
      ),
    );
    if (!mounted || grams == null) return;
    final ingredient = DishIngredient(product: product, grams: grams);
    setState(() {
      if (index == null) {
        _ingredients.add(ingredient);
      } else {
        _ingredients[index] = ingredient;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final s = S.of(context);
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.ingredientsRequired)));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.saveDish(
        Dish(
          id: _id,
          name: _name.text.trim(),
          servings: int.parse(_servings.text.trim(), radix: 10),
          ingredients: _ingredients,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.saveError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.dish == null ? s.newDish : s.editDish),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: s.name),
                validator: (value) =>
                    value!.trim().isEmpty ? s.enterName : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _servings,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: s.recipeServings),
                validator: (value) {
                  final servings = int.tryParse(value!.trim(), radix: 10);
                  return servings == null ||
                          servings < 1 ||
                          servings > 2147483647
                      ? s.invalidRecipeServings
                      : null;
                },
              ),
              const SizedBox(height: 20),
              Text(s.recipeWeights),
              const SizedBox(height: 8),
              for (final (index, item) in _ingredients.indexed)
                ListTile(
                  title: Text(item.product.displayName(s.languageCode)),
                  subtitle: Text('${item.grams} ${s.grams}'),
                  onTap: _saving
                      ? null
                      : () => _setWeight(item.product, index: index),
                  trailing: IconButton(
                    tooltip: s.removeIngredient,
                    onPressed: _saving
                        ? null
                        : () => setState(() => _ingredients.removeAt(index)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _addIngredient,
                icon: const Icon(Icons.add_rounded),
                label: Text(s.addIngredient),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? s.saving : s.saveDish),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DishServingsDialog extends StatefulWidget {
  const _DishServingsDialog({required this.dish});

  final Dish dish;

  @override
  State<_DishServingsDialog> createState() => _DishServingsDialogState();
}

class _DishServingsDialogState extends State<_DishServingsDialog> {
  final _servings = TextEditingController(text: '1');
  bool _invalid = false;

  double? get _validServings {
    final servings = double.tryParse(_servings.text.replaceAll(',', '.'));
    if (servings == null ||
        !(servings > 0 && servings <= widget.dish.servings) ||
        widget.dish.gramsFor(servings) <= 0) {
      return null;
    }
    return servings;
  }

  @override
  void dispose() {
    _servings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final dish = widget.dish;
    final servings = _validServings;
    final calories = servings == null
        ? null
        : dish.diaryProduct.calories * dish.gramsFor(servings) / 100;
    return AlertDialog(
      scrollable: true,
      title: Text(dish.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _servings,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.eatenServings,
              helperText: s.servingsLabel(dish.servings),
              errorText: _invalid
                  ? s.invalidEatenServings(dish.servings)
                  : null,
              errorMaxLines: 2,
            ),
            onChanged: (_) => setState(() => _invalid = false),
          ),
          if (calories != null) ...[
            const SizedBox(height: 12),
            Text(
              '${calories.toStringAsFixed(0)} ${s.kcal}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            final servings = _validServings;
            if (servings != null) {
              Navigator.pop(context, servings);
            } else {
              setState(() => _invalid = true);
            }
          },
          child: Text(s.add),
        ),
      ],
    );
  }
}
