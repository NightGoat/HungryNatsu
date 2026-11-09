import 'package:flutter/material.dart';

import '../data/food_repository.dart';
import '../models/product.dart';
import 'strings.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, required this.repository, this.barcode});
  final FoodRepository repository;
  final String? barcode;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();
  final _carbs = TextEditingController();
  late final TextEditingController _barcode = TextEditingController(
    text: widget.barcode ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _calories,
      _protein,
      _fat,
      _carbs,
      _barcode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.parse(controller.text.replaceAll(',', '.'));

  String? _validateNumber(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (number == null || !number.isFinite || number < 0 || number > 1000) {
      return S.of(context).invalidNumber;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final product = await widget.repository.saveProduct(
        Product(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: _name.text.trim(),
          calories: _number(_calories),
          protein: _number(_protein),
          fat: _number(_fat),
          carbs: _number(_carbs),
          barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, product);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.of(context).saveError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.newProduct)),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.enterPer100),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.name,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? s.enterName : null,
            ),
            const SizedBox(height: 12),
            _field(_calories, s.calories, 1000),
            _field(_protein, '${s.protein}, ${s.grams}', 100),
            _field(_fat, '${s.fat}, ${s.grams}', 100),
            _field(_carbs, '${s.carbs}, ${s.grams}', 100),
            TextFormField(
              controller: _barcode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.barcodeOptional,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null ||
                      value.trim().isEmpty ||
                      RegExp(r'^\d{8,14}$').hasMatch(value.trim()))
                  ? null
                  : s.barcodeDigits,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_saving ? s.saving : s.saveProduct),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, double max) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final error = _validateNumber(value);
            if (error != null) return error;
            return double.parse(value!.replaceAll(',', '.')) > max
                ? S.of(context).maxPer100(max)
                : null;
          },
        ),
      );
}
