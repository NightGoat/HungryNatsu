import 'product.dart';

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.product,
    required this.grams,
    required this.eatenAt,
    this.servings,
  });

  final String id;
  final Product product;
  final double grams;
  final DateTime eatenAt;
  final double? servings;

  double get calories => product.calories * grams / 100;
  double get protein => product.protein * grams / 100;
  double get fat => product.fat * grams / 100;
  double get carbs => product.carbs * grams / 100;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'].toString(),
    product: Product.fromJson(
      Map<String, dynamic>.from(json['product'] as Map),
    ),
    grams: (json['grams'] as num).toDouble(),
    servings: (json['servings'] as num?)?.toDouble(),
    eatenAt: DateTime.parse(json['eaten_at'] as String).toLocal(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product.toJson(),
    'grams': grams,
    if (servings != null) 'servings': servings,
    'eaten_at': eatenAt.toUtc().toIso8601String(),
  };
}
