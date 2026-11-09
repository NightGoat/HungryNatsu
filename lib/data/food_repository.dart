import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/diary_entry.dart';
import '../models/daily_goals.dart';
import '../models/product.dart';

abstract class FoodRepository {
  Future<List<Product>> search(String query);
  Future<Product?> findBarcode(String barcode);
  Future<Product> saveProduct(Product product);
  Future<List<DiaryEntry>> entriesFor(DateTime day);
  Future<List<DiaryEntry>> entriesBetween(DateTime start, DateTime end);
  Future<void> addEntry(DiaryEntry entry);
  Future<void> deleteEntry(String id);
  Future<int?> calorieGoal();
  Future<void> saveCalorieGoal(int goal);
  Future<DailyGoals> dailyGoals();
  Future<void> saveDailyGoals(DailyGoals goals);
}

List<Product> sortProductsByFrequency(
  List<Product> products,
  Map<String, int> usageCounts,
) => products
  ..sort((a, b) {
    final byFrequency = (usageCounts[b.id] ?? 0).compareTo(
      usageCounts[a.id] ?? 0,
    );
    return byFrequency != 0 ? byFrequency : a.name.compareTo(b.name);
  });

class LocalFoodRepository implements FoodRepository {
  LocalFoodRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _productsKey = 'products_v1';
  static const _entriesKey = 'entries_v1';
  static const _goalKey = 'calorie_goal_v1';
  static const _proteinGoalKey = 'protein_goal_v1';
  static const _fatGoalKey = 'fat_goal_v1';
  static const _carbsGoalKey = 'carbs_goal_v1';

  @override
  Future<DailyGoals> dailyGoals() async => DailyGoals(
    calories: _prefs.getInt(_goalKey),
    protein: _prefs.getDouble(_proteinGoalKey),
    fat: _prefs.getDouble(_fatGoalKey),
    carbs: _prefs.getDouble(_carbsGoalKey),
  );

  @override
  Future<void> saveDailyGoals(DailyGoals goals) async {
    if (goals.calories != null) await _prefs.setInt(_goalKey, goals.calories!);
    for (final (key, value) in [
      (_proteinGoalKey, goals.protein),
      (_fatGoalKey, goals.fat),
      (_carbsGoalKey, goals.carbs),
    ]) {
      if (value == null || value <= 0) {
        await _prefs.remove(key);
      } else {
        await _prefs.setDouble(key, value);
      }
    }
  }

  @override
  Future<int?> calorieGoal() async => _prefs.getInt(_goalKey);

  @override
  Future<void> saveCalorieGoal(int goal) async {
    await _prefs.setInt(_goalKey, goal);
  }

  List<Product> get _products {
    final saved = (_prefs.getStringList(_productsKey) ?? []).map(
      (item) => Product.fromJson(jsonDecode(item) as Map<String, dynamic>),
    );
    return [...seedProducts, ...saved];
  }

  List<DiaryEntry> get _entries => (_prefs.getStringList(_entriesKey) ?? [])
      .map(
        (item) => DiaryEntry.fromJson(jsonDecode(item) as Map<String, dynamic>),
      )
      .toList();

  @override
  Future<List<Product>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final usageCounts = <String, int>{};
    for (final entry in _entries) {
      usageCounts.update(
        entry.product.id,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return sortProductsByFrequency(
      _products
          .where(
            (p) =>
                p.name.toLowerCase().contains(normalized) ||
                (p.nameEn?.toLowerCase().contains(normalized) ?? false),
          )
          .toList(),
      usageCounts,
    );
  }

  @override
  Future<Product?> findBarcode(String barcode) async {
    for (final product in _products) {
      if (product.barcode == barcode) return product;
    }
    return null;
  }

  @override
  Future<Product> saveProduct(Product product) async {
    if (product.barcode != null &&
        await findBarcode(product.barcode!) != null) {
      throw StateError('Этот штрихкод уже есть в каталоге');
    }
    final custom = (_prefs.getStringList(_productsKey) ?? [])
      ..add(jsonEncode(product.toJson()));
    await _prefs.setStringList(_productsKey, custom);
    return product;
  }

  @override
  Future<List<DiaryEntry>> entriesFor(DateTime day) async {
    final result = _entries
        .where(
          (e) =>
              e.eatenAt.year == day.year &&
              e.eatenAt.month == day.month &&
              e.eatenAt.day == day.day,
        )
        .toList();
    result.sort((a, b) => b.eatenAt.compareTo(a.eatenAt));
    return result;
  }

  @override
  Future<List<DiaryEntry>> entriesBetween(DateTime start, DateTime end) async =>
      _entries
          .where(
            (entry) =>
                !entry.eatenAt.isBefore(start) && entry.eatenAt.isBefore(end),
          )
          .toList();

  @override
  Future<void> addEntry(DiaryEntry entry) async {
    final entries = _entries..add(entry);
    await _prefs.setStringList(
      _entriesKey,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  Future<void> deleteEntry(String id) async {
    final entries = _entries..removeWhere((e) => e.id == id);
    await _prefs.setStringList(
      _entriesKey,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

class SupabaseFoodRepository implements FoodRepository {
  SupabaseFoodRepository(this._client);
  final SupabaseClient _client;
  Future<Map<String, int>>? _usageCountsFuture;
  String? _usageCountsUserId;

  String get _userId => _client.auth.currentUser!.id;

  @override
  Future<int?> calorieGoal() async {
    final row = await _client
        .from('profiles')
        .select('calorie_goal')
        .eq('user_id', _userId)
        .maybeSingle();
    return (row?['calorie_goal'] as num?)?.toInt();
  }

  @override
  Future<DailyGoals> dailyGoals() async {
    final row = await _client
        .from('profiles')
        .select('calorie_goal, protein_goal, fat_goal, carbs_goal')
        .eq('user_id', _userId)
        .maybeSingle();
    return DailyGoals(
      calories: (row?['calorie_goal'] as num?)?.toInt(),
      protein: (row?['protein_goal'] as num?)?.toDouble(),
      fat: (row?['fat_goal'] as num?)?.toDouble(),
      carbs: (row?['carbs_goal'] as num?)?.toDouble(),
    );
  }

  @override
  Future<void> saveDailyGoals(DailyGoals goals) async {
    await _client.from('profiles').upsert({
      'user_id': _userId,
      'calorie_goal': goals.calories,
      'protein_goal': goals.protein,
      'fat_goal': goals.fat,
      'carbs_goal': goals.carbs,
    });
  }

  @override
  Future<void> saveCalorieGoal(int goal) async {
    await _client.from('profiles').upsert({
      'user_id': _userId,
      'calorie_goal': goal,
    });
  }

  @override
  Future<List<Product>> search(String query) async {
    if (_usageCountsUserId != _userId) {
      _usageCountsFuture = null;
      _usageCountsUserId = _userId;
    }
    final clean = query.trim().replaceAll(RegExp(r'[%_,()]'), ' ');
    late final Map<String, int> usageCounts;
    try {
      usageCounts = await (_usageCountsFuture ??= _loadUsageCounts());
    } catch (_) {
      _usageCountsFuture = null;
      rethrow;
    }
    const pageSize = 1000;
    final products = <Product>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('products')
          .select()
          .or('name.ilike.%$clean%,name_en.ilike.%$clean%')
          .order('name')
          .order('id')
          .range(offset, offset + pageSize - 1);
      products.addAll(rows.map((row) => Product.fromJson(row)));
      if (rows.length < pageSize) break;
    }
    return sortProductsByFrequency(products, usageCounts);
  }

  Future<Map<String, int>> _loadUsageCounts() async {
    const pageSize = 1000;
    final counts = <String, int>{};
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('diary_entries')
          .select('product')
          .eq('user_id', _userId)
          .order('id')
          .range(offset, offset + pageSize - 1);
      for (final row in rows) {
        final product = row['product'];
        if (product is Map && product['id'] != null) {
          final id = product['id'].toString();
          counts.update(id, (count) => count + 1, ifAbsent: () => 1);
        }
      }
      if (rows.length < pageSize) break;
    }
    return counts;
  }

  @override
  Future<Product?> findBarcode(String barcode) async {
    final row = await _client
        .from('products')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();
    return row == null ? null : Product.fromJson(row);
  }

  @override
  Future<Product> saveProduct(Product product) async {
    final row = await _client
        .from('products')
        .insert({
          'owner_id': _userId,
          'name': product.name,
          'name_en': product.nameEn,
          'calories': product.calories,
          'protein': product.protein,
          'fat': product.fat,
          'carbs': product.carbs,
          'barcode': product.barcode,
          'slv_id': product.slvId,
          'fdc_id': product.fdcId,
        })
        .select()
        .single();
    return Product.fromJson(row);
  }

  @override
  Future<List<DiaryEntry>> entriesFor(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day).toUtc();
    final end = DateTime(day.year, day.month, day.day + 1).toUtc();
    final rows = await _client
        .from('diary_entries')
        .select()
        .gte('eaten_at', start.toIso8601String())
        .lt('eaten_at', end.toIso8601String())
        .order('eaten_at', ascending: false);
    return rows.map((row) => DiaryEntry.fromJson(row)).toList();
  }

  @override
  Future<List<DiaryEntry>> entriesBetween(DateTime start, DateTime end) async {
    const pageSize = 1000;
    final entries = <DiaryEntry>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('diary_entries')
          .select()
          .eq('user_id', _userId)
          .gte('eaten_at', start.toUtc().toIso8601String())
          .lt('eaten_at', end.toUtc().toIso8601String())
          .order('eaten_at')
          .order('id')
          .range(offset, offset + pageSize - 1);
      entries.addAll(rows.map((row) => DiaryEntry.fromJson(row)));
      if (rows.length < pageSize) break;
    }
    return entries;
  }

  @override
  Future<void> addEntry(DiaryEntry entry) async {
    await _client.from('diary_entries').insert({
      'id': entry.id,
      'user_id': _userId,
      'product': entry.product.toJson(),
      'grams': entry.grams,
      'eaten_at': entry.eatenAt.toUtc().toIso8601String(),
    });
    _usageCountsFuture = null;
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _client.from('diary_entries').delete().eq('id', id);
    _usageCountsFuture = null;
  }
}
