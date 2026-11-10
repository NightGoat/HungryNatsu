import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hungry_natsu/data/food_repository.dart';
import 'package:hungry_natsu/models/diary_entry.dart';
import 'package:hungry_natsu/models/daily_goals.dart';
import 'package:hungry_natsu/models/calorie_statistics.dart';
import 'package:hungry_natsu/models/product.dart';
import 'package:hungry_natsu/models/goal_estimator.dart';
import 'package:hungry_natsu/ui/home_page.dart';
import 'package:hungry_natsu/ui/statistics_page.dart';

void main() {
  test('oldest diary day clamps at the end of short months', () {
    expect(oldestDiaryDay(DateTime(2026, 5, 31)), DateTime(2026, 2, 28));
    expect(oldestDiaryDay(DateTime(2024, 5, 31)), DateTime(2024, 2, 29));
    expect(oldestDiaryDay(DateTime(2026, 11, 9)), DateTime(2026, 8, 9));
  });

  test('goal estimator handles protein-only and each calorie mode', () {
    final proteinOnly = estimateGoal(mode: GoalMode.muscle, weightKg: 70);
    expect(proteinOnly.protein, 126);
    expect(proteinOnly.calories, isNull);

    GoalEstimate estimate(GoalMode mode) => estimateGoal(
      mode: mode,
      weightKg: 70,
      heightCm: 175,
      ageYears: 30,
      sex: BiologicalSex.male,
      activity: ActivityLevel.moderate,
    );
    expect(estimate(GoalMode.maintenance).calories, 2556);
    expect(estimate(GoalMode.maintenance).protein, 56);
    expect(estimate(GoalMode.loss).calories, 2173);
    expect(estimate(GoalMode.loss).protein, 112);
    expect(estimate(GoalMode.muscle).calories, 2812);
    expect(estimate(GoalMode.muscle).protein, 126);
    for (final mode in GoalMode.values) {
      final result = estimate(mode);
      expect(result.fat, greaterThan(0));
      expect(result.carbs, greaterThan(0));
      expect(
        (result.protein * 4 +
                result.fat! * 9 +
                result.carbs! * 4 -
                result.calories!)
            .abs(),
        lessThanOrEqualTo(6),
      );
    }
  });

  test('common produce is available without barcodes', () {
    expect(seedProducts.length, 257);
    final watermelon = seedProducts.singleWhere(
      (product) => product.name == 'Арбуз',
    );
    expect(watermelon.calories, 34);
    expect(watermelon.slvId, 549);
    expect(watermelon.barcode, isNull);
    expect(
      seedProducts
          .singleWhere((product) => product.name == 'Брокколи')
          .calories,
      36,
    );
    final oats = seedProducts.singleWhere(
      (product) => product.nameEn == 'Rolled oats, dry',
    );
    expect(oats.calories, 375);
    expect(oats.protein, 9.5);
    final chicken = seedProducts.singleWhere(
      (product) => product.id == 'chicken',
    );
    expect(chicken.slvId, 1170);
    expect(chicken.calories, 116);
    final cod = seedProducts.singleWhere((product) => product.id == 'cod_raw');
    expect(cod.slvId, 1246);
    expect(cod.calories, 78);
    expect(Product.fromJson(cod.toJson()).slvId, cod.slvId);
    final almonds = seedProducts.singleWhere(
      (product) => product.id == 'almonds',
    );
    expect(almonds.nameEn, 'Almonds');
    expect(almonds.slvId, 1575);
    expect(almonds.calories, 592);
    final honey = seedProducts.singleWhere((product) => product.id == 'honey');
    expect(honey.slvId, 1896);
    expect(honey.calories, 332);
    final egg = seedProducts.singleWhere((product) => product.id == 'egg');
    expect(egg.slvId, 2205);
    expect(egg.name, 'Яйцо, варёное');
    final rawCashews = seedProducts.singleWhere(
      (product) => product.id == 'cashews_raw',
    );
    expect(rawCashews.fdcId, 170162);
    expect(rawCashews.calories, 553);
  });

  test(
    'English names are searchable while Russian names remain available',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalFoodRepository(
        await SharedPreferences.getInstance(),
      );
      expect(
        (await repository.search('buckwheat')).map((p) => p.nameEn),
        contains('Buckwheat, dry'),
      );
      expect(
        (await repository.search('гречка')).map((p) => p.nameEn),
        contains('Buckwheat, dry'),
      );
    },
  );

  test(
    'foods are ordered by diary frequency and update after deletion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalFoodRepository(
        await SharedPreferences.getInstance(),
      );
      final potato = seedProducts.singleWhere((p) => p.id == 'potato');
      final apple = seedProducts.singleWhere((p) => p.id == 'apple');
      Future<void> add(String id, Product product) => repository.addEntry(
        DiaryEntry(
          id: id,
          product: product,
          grams: 100,
          eatenAt: DateTime(2026, 1, 1),
        ),
      );

      await add('potato-1', potato);
      await add('apple-1', apple);
      await add('potato-2', potato);
      expect((await repository.search('')).first.id, 'potato');
      expect((await repository.search('pot')).first.id, 'potato');

      await repository.deleteEntry('potato-1');
      await repository.deleteEntry('potato-2');
      expect((await repository.search('')).first.id, 'apple');
    },
  );

  test('portion scales calories and macronutrients from 100 g', () {
    final entry = DiaryEntry(
      id: '1',
      product: const Product(
        id: 'x',
        name: 'Пример',
        calories: 200,
        protein: 10,
        fat: 5,
        carbs: 30,
      ),
      grams: 150,
      eatenAt: DateTime(2026, 1, 1),
    );
    expect(entry.calories, 300);
    expect(entry.protein, 15);
    expect(entry.fat, 7.5);
    expect(entry.carbs, 45);
  });

  test('daily calorie goal persists with local diary', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = LocalFoodRepository(prefs);
    expect(await repository.calorieGoal(), isNull);
    await repository.saveCalorieGoal(2100);
    expect(await LocalFoodRepository(prefs).calorieGoal(), 2100);
  });

  test('macro goals persist and zero or missing goals stay hidden', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = LocalFoodRepository(prefs);
    await repository.saveDailyGoals(
      const DailyGoals(calories: 2100, protein: 125.5, fat: 0),
    );
    var goals = await LocalFoodRepository(prefs).dailyGoals();
    expect(goals.calories, 2100);
    expect(goals.protein, 125.5);
    expect(goals.fat, isNull);
    expect(goals.carbs, isNull);

    await repository.saveDailyGoals(
      const DailyGoals(calories: 2100, carbs: 200),
    );
    goals = await repository.dailyGoals();
    expect(goals.protein, isNull);
    expect(goals.carbs, 200);
  });

  testWidgets('home shows compact macro goals only when configured', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final repository = LocalFoodRepository(
      await SharedPreferences.getInstance(),
    );
    await repository.saveDailyGoals(
      const DailyGoals(calories: 2000, protein: 10, fat: 5),
    );
    await repository.addEntry(
      DiaryEntry(
        id: 'today',
        product: const Product(
          id: 'test',
          name: 'Test',
          calories: 100,
          protein: 15,
          fat: 2,
          carbs: 20,
        ),
        grams: 100,
        eatenAt: DateTime.now(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HomePage(repository: repository, online: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Цель: 10 г'), findsOneWidget);
    expect(find.text('Цель: 5 г'), findsOneWidget);
    expect(find.text('Без цели'), findsOneWidget);
    expect(find.text('15.0 г'), findsOneWidget);
    expect(find.text('20.0 г'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'statistics sum daily calories and use logged days for median',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalFoodRepository(
        await SharedPreferences.getInstance(),
      );
      const product = Product(
        id: 'test',
        name: 'Test',
        calories: 100,
        protein: 0,
        fat: 0,
        carbs: 0,
      );
      for (final (id, day, grams) in [
        ('a', 1, 100.0),
        ('b', 1, 100.0),
        ('c', 3, 400.0),
        ('d', 4, 600.0),
      ]) {
        await repository.addEntry(
          DiaryEntry(
            id: id,
            product: product,
            grams: grams,
            eatenAt: DateTime(2026, 1, day),
          ),
        );
      }
      final entries = await repository.entriesBetween(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 5),
      );
      final stats = CalorieStatistics(
        firstDay: DateTime(2026, 1, 1),
        dayCount: 4,
        entries: entries,
      );
      expect(stats.days.map((day) => day.calories), [200, 0, 400, 600]);
      expect(stats.days[1].hasEntries, isFalse);
      expect(stats.median, 400);
    },
  );

  testWidgets('statistics screen shows median and changes range', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalFoodRepository(
      await SharedPreferences.getInstance(),
    );
    await repository.addEntry(
      DiaryEntry(
        id: 'today',
        product: const Product(
          id: 'test',
          name: 'Test',
          calories: 200,
          protein: 0,
          fat: 0,
          carbs: 0,
        ),
        grams: 100,
        eatenAt: DateTime.now(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: StatisticsPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Медиана: 200 ккал'), findsOneWidget);
    await tester.tap(find.text('30 дней'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Медиана: 200 ккал'), findsOneWidget);
  });

  testWidgets('saving a product opens its portion dialog', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalFoodRepository(
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HomePage(repository: repository, online: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить продукт'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Новый продукт'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Тестовый йогурт');
    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await tester.enterText(find.byType(TextFormField).at(2), '4');
    await tester.enterText(find.byType(TextFormField).at(3), '2');
    await tester.enterText(find.byType(TextFormField).at(4), '8');
    await tester.enterText(find.byType(TextFormField).at(5), '12345678');
    await tester.tap(find.text('Сохранить продукт'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Тестовый йогурт'), findsOneWidget);
    expect(find.text('Сколько съели?'), findsOneWidget);
  });

  testWidgets(
    'closing portion dialog keeps its controller alive through transition',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalFoodRepository(
        await SharedPreferences.getInstance(),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HomePage(repository: repository, online: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Добавить продукт'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Картофель');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Картофель'));
      await tester.pumpAndSettle();
      expect(find.text('Сколько съели?'), findsOneWidget);
      await tester.tap(find.text('Добавить'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('81'), findsWidgets);
      expect(find.text('Картофель'), findsOneWidget);
    },
  );
}
