part 'seed_products.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    this.nameEn,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.barcode,
    this.slvId,
    this.fdcId,
  });

  final String id;
  final String name;
  final String? nameEn;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String? barcode;
  final int? slvId;
  final int? fdcId;

  String displayName(String languageCode) =>
      languageCode == 'en' && nameEn != null && nameEn!.isNotEmpty
      ? nameEn!
      : name;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'].toString(),
    name: json['name'] as String,
    nameEn: json['name_en'] as String?,
    calories: (json['calories'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    barcode: json['barcode'] as String?,
    slvId: (json['slv_id'] as num?)?.toInt(),
    fdcId: (json['fdc_id'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_en': nameEn,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'barcode': barcode,
    'slv_id': slvId,
    'fdc_id': fdcId,
  };
}
