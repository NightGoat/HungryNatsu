import 'product.dart';

class DishIngredient {
  const DishIngredient({required this.product, required this.grams});

  final Product product;
  final double grams;

  factory DishIngredient.fromJson(Map<String, dynamic> json) => DishIngredient(
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    grams: (json['grams'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'grams': grams,
  };
}

class Dish {
  Dish({
    required this.id,
    required this.name,
    required this.servings,
    required List<DishIngredient> ingredients,
  }) : ingredients = List.unmodifiable(ingredients);

  final String id;
  final String name;
  final int servings;
  final List<DishIngredient> ingredients;

  late final double _grams = ingredients.fold(
    0,
    (sum, item) => sum + item.grams,
  );

  double gramsFor(double portions) => _grams * (portions / servings);

  // Keep the diary's per-100 g nutrition snapshot based on ingredient weight.
  late final Product diaryProduct = Product(
    id: id,
    name: name,
    calories: _per100((product) => product.calories),
    protein: _per100((product) => product.protein),
    fat: _per100((product) => product.fat),
    carbs: _per100((product) => product.carbs),
  );

  double _per100(double Function(Product) nutrient) => ingredients.fold<double>(
    0,
    (sum, item) => sum + nutrient(item.product) * (item.grams / _grams),
  );

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
    id: json['id'] as String,
    name: json['name'] as String,
    servings: (json['servings'] as num).toInt(),
    ingredients: (json['ingredients'] as List)
        .map((item) => DishIngredient.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'servings': servings,
    'ingredients': ingredients.map((item) => item.toJson()).toList(),
  };
}
