import 'package:flutter/material.dart';

import '../models/product.dart';
import 'strings.dart';

class FoodWeightDialog extends StatefulWidget {
  const FoodWeightDialog({
    super.key,
    required this.product,
    this.initialGrams = 100,
    this.ingredient = false,
  });

  final Product product;
  final double initialGrams;
  final bool ingredient;

  @override
  State<FoodWeightDialog> createState() => _FoodWeightDialogState();
}

class _FoodWeightDialogState extends State<FoodWeightDialog> {
  late final _controller = TextEditingController(
    text: widget.initialGrams.toString().replaceFirst(RegExp(r'\.0$'), ''),
  );
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final grams = double.tryParse(_controller.text.replaceAll(',', '.'));
    final calories = grams == null
        ? null
        : widget.product.calories * grams / 100;
    return AlertDialog(
      scrollable: true,
      title: Text(widget.product.displayName(s.languageCode)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.sourceLabel(widget.product.slvId, widget.product.fdcId),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            onChanged: (_) => setState(() => _invalid = false),
            decoration: InputDecoration(
              labelText: widget.ingredient ? s.ingredientWeight : s.portion,
              suffixText: s.grams,
              errorText: _invalid ? s.invalidPortion : null,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            children: [
              for (final amount in [50, 100, 150, 200])
                ChoiceChip(
                  label: Text('$amount ${s.grams}'),
                  selected: grams == amount,
                  onSelected: (_) => setState(() {
                    _controller.text = '$amount';
                    _invalid = false;
                  }),
                ),
            ],
          ),
          if (calories != null && grams != null && grams > 0) ...[
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
            final value = double.tryParse(
              _controller.text.replaceAll(',', '.'),
            );
            if (value != null && value > 0 && value <= 10000) {
              Navigator.pop(context, value);
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
