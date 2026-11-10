import 'package:flutter/widgets.dart';

import '../models/diary_period.dart';

class S {
  S.of(BuildContext context)
    : en = Localizations.localeOf(context).languageCode == 'en';
  final bool en;
  String get languageCode => en ? 'en' : 'ru';
  String t(String ru, String english) => en ? english : ru;

  String get localMode => t('Локальный режим', 'Local mode');
  String get localModeNotice => t(
    'Данные сохраняются только на этом устройстве. Для синхронизации запустите приложение с настройками Supabase.',
    'Data is saved only on this device. Run the app with Supabase settings to sync it.',
  );
  String get account => t('Аккаунт', 'Account');
  String get email => t('Почта', 'Email');
  String get password => t('Пароль', 'Password');
  String get signIn => t('Войти', 'Sign in');
  String get register => t('Зарегистрироваться', 'Create account');
  String get createAccount =>
      t('Нет аккаунта? Зарегистрироваться', 'No account? Create one');
  String get haveAccount =>
      t('Уже есть аккаунт? Войти', 'Have an account? Sign in');
  String get signOut => t('Выйти', 'Sign out');
  String get checkEmail => t(
    'Проверьте почту и подтвердите регистрацию, затем войдите.',
    'Check your email to confirm registration, then sign in.',
  );
  String get invalidEmail =>
      t('Введите корректную почту', 'Enter a valid email');
  String get shortPassword => t('Минимум 6 символов', 'At least 6 characters');
  String get dailyGoal => t('Цель на день', 'Daily goal');
  String get saveGoal => t('Сохранить цель', 'Save goal');
  String get invalidGoal => t(
    'Введите целое число от 1 до 10000',
    'Enter a whole number from 1 to 10000',
  );
  String get invalidMacroGoal =>
      t('Введите число от 0 до 10000 г', 'Enter a number from 0 to 10000 g');
  String get optionalMacroGoal => t(
    'Для БЖУ: 0 или пустое поле скрывает остаток.',
    'For macros: 0 or an empty field hides the balance.',
  );
  String get helperTitle => t('Помощник по целям', 'Goal helper');
  String get helperIntro => t(
    'Необязательная оценка для взрослых. Для белка достаточно веса; для калорий, жиров и углеводов заполните остальные данные.',
    'Optional estimate for adults. Weight is enough for protein; fill in the other details for calories, fat, and carbs.',
  );
  String get helperPrivacy => t(
    'Вес, рост, возраст, пол и активность нигде не сохраняются и не отправляются на сервер. Они нужны только для расчёта на этом экране. При сохранении целей сохранятся только калории и БЖУ.',
    'Weight, height, age, sex, and activity are not saved anywhere or sent to a server. They are used only for this calculation. If you save the goals, only calories and macros are saved.',
  );
  String get helperLoss => t('Худение', 'Loss');
  String get helperMaintain => t('Поддержание', 'Maintain');
  String get helperMuscle => t('Набор мышц', 'Muscle gain');
  String get helperWeight => t('Вес', 'Weight');
  String get helperCaloriesOptional => t(
    'Для расчёта калорий (необязательно):',
    'For a calorie estimate (optional):',
  );
  String get helperSex => t('Пол для формулы', 'Sex for the equation');
  String get helperFemale => t('Женский', 'Female');
  String get helperMale => t('Мужской', 'Male');
  String get helperAge => t('Возраст, лет (18–100)', 'Age, years (18–100)');
  String get helperHeight => t('Рост', 'Height');
  String get helperActivity => t('Повседневная активность', 'Daily activity');
  String get helperSedentary => t('Малоподвижная', 'Sedentary');
  String get helperLight =>
      t('Лёгкая (1–3 тренировки в неделю)', 'Light (1–3 workouts/week)');
  String get helperModerate =>
      t('Умеренная (3–5 тренировок)', 'Moderate (3–5 workouts)');
  String get helperHigh => t('Высокая (6–7 тренировок)', 'High (6–7 workouts)');
  String get helperCalculate => t('Рассчитать', 'Calculate');
  String get helperResult =>
      t('Предложенные цели на день', 'Suggested daily goals');
  String helperMaintenanceValue(int value) =>
      t('Поддержание: $value ккал', 'Maintenance: $value kcal');
  String helperCaloriesValue(int value) =>
      t('Цель: $value ккал', 'Goal: $value kcal');
  String helperProteinValue(int value) =>
      t('Белок: $value г', 'Protein: $value g');
  String helperFatValue(int value) => t('Жиры: $value г', 'Fat: $value g');
  String helperCarbsValue(int value) =>
      t('Углеводы: $value г', 'Carbs: $value g');
  String get helperInvalidWeight =>
      t('Укажите вес от 30 до 300 кг.', 'Enter a weight from 30 to 300 kg.');
  String get helperInvalidDetails => t(
    'Для калорий нужны пол, возраст 18–100 лет и рост 120–230 см.',
    'Calories require sex, age 18–100, and height 120–230 cm.',
  );
  String get helperUnderweight => t(
    'При ИМТ ниже 18,5 цель для похудения не предлагается.',
    'No weight-loss calorie goal is suggested below BMI 18.5.',
  );
  String get helperNoDeficit => t(
    'Расчётный расход слишком мал для безопасного автоматического дефицита.',
    'Estimated expenditure is too low for an automatic calorie deficit.',
  );
  String get helperMethod => t(
    'Калории: формула Миффлина — Сан Жеора × активность; худение: −15% (не больше 500 ккал), набор: +10%. Белок: 1,6 / 0,8 / 1,8 г/кг для похудения / поддержания / набора, не более 30% калорий. Жиры: 25% калорий; углеводы: остаток.',
    'Calories: Mifflin–St Jeor × activity; loss: −15% (at most 500 kcal), gain: +10%. Protein: 1.6 / 0.8 / 1.8 g/kg for loss / maintenance / gain, capped at 30% of calories. Fat: 25% of calories; carbs: the remainder.',
  );
  String get helperCaution => t(
    'Это стартовая оценка, а не медицинское назначение. Корректируйте по динамике веса за 2–4 недели. При беременности, кормлении, болезни почек или расстройстве пищевого поведения обратитесь к специалисту.',
    'This is a starting estimate, not medical advice. Adjust using your 2–4 week weight trend. For pregnancy, breastfeeding, kidney disease, or an eating disorder, seek professional advice.',
  );
  String get helperUse => t('Подставить в цели', 'Use these goals');
  String get today => t('Сегодня', 'Today');
  String get eatenToday => t('Съедено за день', 'Eaten today');
  String get eatenOnDay => t('Съедено за день', 'Eaten that day');
  String remaining(int value) =>
      t('Осталось $value ккал', '$value kcal remaining');
  String overGoal(int value) =>
      t('Сверх цели на $value ккал', '$value kcal over goal');
  String macroRemaining(String value) =>
      t('Осталось $value г', '$value g remaining');
  String macroOverGoal(String value) =>
      t('Сверх цели на $value г', '$value g over goal');
  String macroGoal(String value) => t('Цель: $value г', 'Goal: $value g');
  String get noMacroGoal => t('Без цели', 'No goal');
  String get setGoal => t('Установить цель', 'Set a daily goal');
  String get previousDay => t('Предыдущий день', 'Previous day');
  String get nextDay => t('Следующий день', 'Next day');
  String get entryDeleted => t('Запись удалена', 'Entry deleted');
  String get undo => t('Отменить', 'Undo');
  String get more => t('Ещё', 'More');
  String get russian => 'Русский';
  String get english => 'English';
  String get kcal => t('ккал', 'kcal');
  String get grams => t('г', 'g');
  String get protein => t('Белки', 'Protein');
  String get fat => t('Жиры', 'Fat');
  String get carbs => t('Углеводы', 'Carbs');
  String get diary => t('Дневник', 'Diary');
  String diaryPeriod(DiaryPeriod period) => switch (period) {
    DiaryPeriod.morning => t('Утро', 'Morning'),
    DiaryPeriod.afternoon => t('День', 'Afternoon'),
    DiaryPeriod.evening => t('Вечер', 'Evening'),
    DiaryPeriod.night => t('Ночь', 'Night'),
  };
  String get statistics => t('Статистика', 'Statistics');
  String get calorieTrend => t('Калории по дням', 'Calories over time');
  String get statisticsDescription =>
      t('Последние дни, включая сегодня', 'Recent days, including today');
  String get last7Days => t('7 дней', '7 days');
  String get last30Days => t('30 дней', '30 days');
  String get dailyCalories => t('Калории за день', 'Daily calories');
  String get median => t('Медиана', 'Median');
  String get medianExplanation => t(
    'Линия показывает медиану калорий за дни с записями. Пустые дни не учитываются.',
    'The line shows the median calories for logged days. Empty days are excluded.',
  );
  String get noStatistics => t('Пока нет записей', 'No entries yet');
  String get retry => t('Повторить', 'Retry');
  String get emptyDiary => t(
    'Пока пусто. Добавьте первый продукт.',
    'Nothing here yet. Add your first food.',
  );
  String get delete => t('Удалить', 'Delete');
  String get addProduct => t('Добавить продукт', 'Add food');
  String get myDishes => t('Мои блюда', 'My dishes');
  String get newDish => t('Собрать блюдо', 'Build a dish');
  String get editDish => t('Изменить блюдо', 'Edit dish');
  String get noDishes => t('Пока нет сохранённых блюд', 'No saved dishes yet');
  String get recipeServings =>
      t('Сколько порций в блюде?', 'How many servings does it make?');
  String get recipeWeights => t(
    'Укажите вес каждого ингредиента на всё блюдо.',
    'Enter each ingredient’s weight for the whole dish.',
  );
  String get invalidRecipeServings =>
      t('Введите целое число больше нуля', 'Enter a positive whole number');
  String get addIngredient => t('Добавить ингредиент', 'Add ingredient');
  String get removeIngredient => t('Убрать ингредиент', 'Remove ingredient');
  String get ingredientWeight => t('Вес ингредиента', 'Ingredient weight');
  String get ingredientsRequired =>
      t('Добавьте хотя бы один ингредиент', 'Add at least one ingredient');
  String get saveDish => t('Сохранить блюдо', 'Save dish');
  String get eatenServings => t('Сколько порций съели?', 'Servings eaten');
  String invalidEatenServings(int total) => t(
    'Укажите больше 0 и не больше $total',
    'Enter a number greater than 0 and at most $total',
  );
  String servingsLabel(num servings) {
    final value = servings.toString().replaceFirst(RegExp(r'\.0$'), '');
    return t(
      '${value.replaceAll('.', ',')} порц.',
      '$value ${servings == 1 ? 'serving' : 'servings'}',
    );
  }

  String kcalPerServing(String value) =>
      t('$value ккал на порцию', '$value kcal per serving');
  String get addFirstEntry =>
      t('Добавить первую запись', 'Add your first entry');
  String get add => t('Добавить', 'Add');
  String get cancel => t('Отмена', 'Cancel');
  String get portion => t('Сколько съели?', 'How much did you eat?');
  String get invalidPortion =>
      t('Введите вес от 1 до 10000 г', 'Enter a weight from 1 to 10000 g');
  String get chooseProduct => t('Выбрать продукт', 'Choose food');
  String get searchHint => t('Название продукта', 'Food name');
  String get clearSearch => t('Очистить поиск', 'Clear search');
  String get recentFoods => t('Продукты', 'Foods');
  String get searchResults => t('Результаты поиска', 'Search results');
  String get scan => t('Сканировать', 'Scan');
  String get newProduct => t('Новый продукт', 'New food');
  String get notFound => t('Продукты не найдены', 'No foods found');
  String get scanBarcode => t('Сканировать штрихкод', 'Scan barcode');
  String get pointCamera =>
      t('Наведите камеру на штрихкод товара', 'Point the camera at a barcode');
  String get unknownBarcode => t(
    'Штрихкод не найден. Введите БЖУ продукта.',
    'Barcode not found. Enter the food values.',
  );
  String get per100 => t('на 100 г', 'per 100 g');
  String get enterPer100 => t(
    'Укажите значения на 100 г продукта.',
    'Enter values per 100 g of food.',
  );
  String get name => t('Название', 'Name');
  String get enterName => t('Введите название', 'Enter a name');
  String get calories => t('Калории, ккал', 'Calories, kcal');
  String get barcodeOptional =>
      t('Штрихкод (необязательно)', 'Barcode (optional)');
  String get barcodeDigits => t('Нужно 8–14 цифр', 'Use 8–14 digits');
  String get saving => t('Сохраняем…', 'Saving…');
  String get saveProduct => t('Сохранить продукт', 'Save food');
  String get invalidNumber =>
      t('Введите число от 0 до 1000', 'Enter a number from 0 to 1000');
  String maxPer100(num max) =>
      t('Не больше $max на 100 г', 'Maximum $max per 100 g');
  String error(Object value) => t('Ошибка: $value', 'Error: $value');
  String saveError(Object value) =>
      t('Не удалось сохранить: $value', 'Could not save: $value');
  String get language => t('Язык', 'Language');
  String get dataSources => t('Источники данных', 'Data sources');
  String sourceLabel(int? slvId, int? fdcId) => slvId != null
      ? 'Livsmedelsverket #$slvId'
      : fdcId != null
      ? 'USDA #$fdcId'
      : t('Ориентировочные данные', 'Approximate values');
  String get dataSourcesBody => t(
    'Крупы, большинство фруктов и овощей, мясо, рыба, орехи, мёд, яйца, бобовые, семена и зелень: Livsmedelsverkets Livsmedelsdatabas, версия 2026-07-01. Продукты без точного соответствия в шведской базе: USDA FoodData Central SR Legacy 2018. В шведских данных углеводы указаны без клетчатки, в USDA — с клетчаткой. Молоко 2,5%: ориентировочное значение. Всё на 100 г. Для фасованных продуктов сверяйте этикетку.',
    'Grains, most produce, meat, fish, nuts, honey, eggs, legumes, seeds, and herbs: Livsmedelsverkets Livsmedelsdatabas, version 2026-07-01. Foods without a precise Swedish match: USDA FoodData Central SR Legacy 2018. Swedish carbohydrates exclude fibre; USDA total carbohydrates include fibre. Milk 2.5%: approximate value. All values are per 100 g. Check the label for packaged foods.',
  );
}
