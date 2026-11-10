# Hungry Natsu

<img src="assets/natsu_repository_art.png" alt="Illustration of a tabby cat in front of an orange circle" width="360">

Hungry Natsu is a Flutter app for Android and iOS that combines a food diary, calorie and macronutrient tracking, a food catalog, and barcode scanning.

## Features

- Search 257 staple foods without barcodes: fruit and vegetables, grains and rice, meat and fish, 23 nut products including raw cashews, plus honey, eggs, legumes, seeds, herbs, and other basics. Nutrition values are given per 100 g.
- Switch between English and Russian on the home screen. Search works with names in either language.
- Add foods manually with calories, protein, fat, carbohydrates, and an optional barcode.
- Scan 8–14 digit EAN/UPC-style barcodes with the camera using `flutter_zxing` (ZXing C++), instead of Google ML Kit. An unknown barcode opens the new-food form.
- Keep a diary by day, enter portion weights, calculate calories and macronutrients automatically, and delete entries.
- Sort foods by how often they have been added to the diary across all days. Ties are sorted by name, and deleted entries no longer count.
- Store data locally on the device without an account or network connection. When configured with Supabase, use email and password authentication, a private cloud diary protected by row-level security, and a shared catalog of foods created by signed-in users. Existing local entries are not transferred to the cloud automatically.
- Set a daily calorie goal and see progress on the home screen. In cloud mode, diary entries older than three months are deleted from the database daily at 03:00 UTC, and the calendar is limited to that period.
- Use the optional goal helper for weight loss, maintenance, or muscle gain. It estimates protein from body weight and uses sex, age, height, and activity level to estimate calorie, fat, and carbohydrate goals. Suggested goals can be edited before saving. The body measurements entered into the helper are not stored.

## Goal calculations

The goal helper is intended for adults. It estimates resting energy expenditure using the [Mifflin–St Jeor equation](https://pubmed.ncbi.nlm.nih.gov/2305711/) and multiplies it by an activity factor of 1.2, 1.375, 1.55, or 1.725. For weight loss, it starts with a 15% deficit capped at 500 kcal per day, with minimum targets of 1,200 kcal for women and 1,500 kcal for men. It does not suggest a weight-loss calorie target when BMI is below 18.5. For muscle gain, it starts with a 10% surplus; a [sports nutrition review](https://pmc.ncbi.nlm.nih.gov/articles/PMC6680710/) discusses a 10–20% range and adjustment based on the rate of weight gain.

Protein targets are 0.8 g/kg for maintenance, 1.6 g/kg for weight loss, and 1.8 g/kg for muscle gain with strength training. A [research review](https://ajcn.nutrition.org/article/S0002-9165%2823%2927427-4/fulltext) gives a 1.2–1.6 g/kg range for weight loss, and the [ISSN position stand](https://pmc.ncbi.nlm.nih.gov/articles/PMC5477153/) gives a 1.4–2.0 g/kg range for exercising individuals. These estimates are starting points, not medical prescriptions; needs should be adjusted based on weight trends over several weeks. Pregnancy, breastfeeding, kidney disease, and eating disorders require individual professional advice. The [NIH Body Weight Planner](https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner) likewise limits its calculations to adults and excludes pregnancy and breastfeeding.

For a complete goal, protein is capped at 30% of calories, fat is set to 25%, and carbohydrates fill the remaining energy budget using 4/9/4 kcal per gram. The fat share falls within the [20–35% adult range](https://www.nationalacademies.org/read/10872/chapter/13); the carbohydrate allocation follows the approach in the [bodybuilding nutrition review](https://pmc.ncbi.nlm.nih.gov/articles/PMC6680710/). Values are rounded to whole grams.

## Food data and attribution

Grains, rice, most fruit and vegetables, meat, fish, nuts, honey, eggs, legumes, seeds, and herbs come from **Livsmedelsverkets Livsmedelsdatabas, version 2026-07-01**, via the [Swedish Food Agency's open API](https://www.livsmedelsverket.se/en/about-us/open-data/food-composition-data/). This data is published under CC BY 4.0. The CSV retains each source record ID and original name, and the calorie and macronutrient values were copied without modification. Dry and cooked, plain, roasted, and salted variants are listed separately where available. These are generic foods rather than branded products.

The remaining 16 fruits and vegetables and six explicitly raw nut products, including cashews, come from [USDA FoodData Central, SR Legacy 2018](https://fdc.nal.usda.gov/download-datasets/) (CC0), used where no sufficiently close match was found in the Swedish database. Swedish carbohydrate values exclude fiber, while USDA total carbohydrate values include it. The 2.5% milk value is approximate. Actual values vary by variety and preparation; check the label for packaged foods.

Source IDs, names, and values are stored in `catalog/products.csv`, and each food's source is visible in the app. Russian names and USDA ID mappings are stored in `catalog/produce_map.csv`.

## Code structure

- `lib/models/` defines foods, diary entries, and goals. Food values always refer to 100 g.
- `lib/data/food_repository.dart` defines the storage interface and its local and Supabase implementations.
- `lib/ui/` contains the diary, food selection, account, and editing screens. The UI uses the storage interface.
- `lib/main.dart` selects local or cloud storage from build-time configuration.

## Licenses and third-party components

The project's code and original assets are licensed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0). The following dependencies and data retain their own terms:

| Component | License or terms | Use |
| --- | --- | --- |
| [Flutter](https://github.com/flutter/flutter/blob/stable/LICENSE) and [Dart](https://github.com/dart-lang/sdk/blob/main/LICENSE) | BSD 3-Clause | App framework and language SDK; Flutter's `flutter_localizations` and `flutter_test` are part of this SDK |
| [flutter_zxing](https://github.com/khoren93/flutter_zxing/blob/main/LICENSE) | MIT | Camera-based barcode scanning plugin |
| [zxing-cpp](https://github.com/zxing-cpp/zxing-cpp/blob/master/LICENSE) | Apache 2.0 | Native barcode recognition used by `flutter_zxing` |
| [shared_preferences](https://github.com/flutter/packages/blob/main/packages/shared_preferences/shared_preferences/LICENSE) | BSD 3-Clause | Local data storage |
| [supabase_flutter](https://github.com/supabase/supabase-flutter/blob/main/packages/supabase_flutter/LICENSE) | MIT | Optional cloud authentication and storage client |
| [flutter_lints](https://github.com/flutter/packages/blob/main/packages/flutter_lints/LICENSE) | BSD 3-Clause | Development-time lint rules |
| [Livsmedelsverket food composition data](https://www.livsmedelsverket.se/en/about-us/open-data/food-composition-data/) | CC BY 4.0 | Swedish food records; attribution to the Swedish Food Agency is required |
| [USDA FoodData Central data](https://fdc.nal.usda.gov/api-guide/) | CC0 1.0 | SR Legacy food records |

The licenses above apply to the named components, not to the project as a whole. Every resolved Dart package, including transitive and development dependencies, is listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) with its version and license. Native dependencies retain their own upstream terms.

## APIs and data sources

| API or source | When used | Purpose |
| --- | --- | --- |
| [Livsmedelsverket Food Composition API](https://www.livsmedelsverket.se/en/about-us/open-data/food-composition-data/) | Catalog preparation | Import Swedish food composition records |
| [USDA FoodData Central SR Legacy download](https://fdc.nal.usda.gov/download-datasets/) | Catalog preparation | Import additional foods from a downloadable dataset, not a runtime API |
| [Supabase Auth and database APIs](https://supabase.com/docs/reference/dart/introduction) | Runtime, only when cloud mode is configured | Email authentication, private diary storage, and shared food catalog |

The local mode does not require a network service. The app does not call an AI API at runtime.

## AI assistance

This application was written with the assistance of AI tools, including OpenAI Codex/ChatGPT.
