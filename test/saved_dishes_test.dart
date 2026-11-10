import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hungry_natsu/data/food_repository.dart';
import 'package:hungry_natsu/ui/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('save a dish and reuse its portions on another day', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalFoodRepository(
      await SharedPreferences.getInstance(),
    );
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HomePage(repository: repository, online: false),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tap(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    Future<void> addIngredient(String name, String grams) async {
      await tap('Добавить ингредиент');
      await tester.enterText(find.byType(TextField), name);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, name));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        grams,
      );
      await tap('Добавить');
    }

    await tester.tap(find.byTooltip('Мои блюда'));
    await tester.pumpAndSettle();
    await tap('Собрать блюдо');
    await tester.enterText(find.byType(TextFormField).at(0), 'Мой завтрак');
    await tester.enterText(find.byType(TextFormField).at(1), '4');
    await addIngredient('Картофель', '500');
    await addIngredient('Яблоко', '100');
    await tap('Сохранить блюдо');

    final dish = (await repository.dishes()).single;
    expect(dish.servings, 4);
    expect(dish.ingredients.map((item) => item.grams), [500, 100]);

    await tap('Мой завтрак');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '1',
    );
    await tap('Добавить');

    final entry = (await repository.entriesFor(today)).single;
    expect(entry.servings, 1);
    expect(entry.grams, 150);
    expect(entry.calories, closeTo(113.25, 0.001));
    expect(entry.protein, closeTo(2.25, 0.001));
    expect(entry.fat, closeTo(0.125, 0.001));
    expect(entry.carbs, closeTo(23.65, 0.001));
    expect(find.text('1 порц.'), findsOneWidget);

    await tester.tap(find.byTooltip('Предыдущий день'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Мои блюда'));
    await tester.pumpAndSettle();
    await tap('Мой завтрак');
    await tester.enterText(find.byType(TextField), '0');
    await tap('Добавить');
    expect(find.text('Укажите больше 0 и не больше 4'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0,5');
    await tap('Добавить');

    final half = (await repository.entriesFor(yesterday)).single;
    expect(half.servings, 0.5);
    expect(half.calories, closeTo(entry.calories / 2, 0.001));
    expect(find.text('0,5 порц.'), findsOneWidget);
    expect((await repository.entriesFor(today)).single.servings, 1);
  });
}
