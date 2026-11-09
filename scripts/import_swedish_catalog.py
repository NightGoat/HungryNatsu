"""Refresh curated foods from the Swedish Food Agency's public API.

Values are copied from ENERC (kcal), PROT, FAT and CHO per 100 g edible part.
Run this script before generate_catalog.py when refreshing the catalog.
"""

import concurrent.futures
import csv
import json
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / 'catalog' / 'products.csv'
API = 'https://dataportal.livsmedelsverket.se/livsmedel/api/v1/livsmedel'

# Existing raw produce with a direct match in the Swedish database.
# Preparation and variety are checked against the English API names below.
PRODUCE = {
    'apricot': (552, 'Apricot'),
    'blackberry': (554, 'Blackberries'),
    'cherry': (571, 'Sweet cherries'),
    'sour_cherry': (570, 'Sour cherries'),
    'cranberry': (584, 'Cranberries'),
    'blackcurrant': (586, 'Black currant'),
    'redcurrant': (585, 'Red currant'),
    'fig': (561, 'Fig'),
    'gooseberry': (566, 'Gooseberries'),
    'grapefruit': (521, 'Grapefruit'),
    'grape': (587, 'Grapes'),
    'guava': (522, 'Guava'),
    'kiwi': (565, 'Kiwi fruit green'),
    'lemon': (559, 'Lemon'),
    'lime': (572, 'Lime'),
    'lychee': (2569, 'Lychee'),
    'mango': (574, 'Mango'),
    'honeydew': (546, 'Honeydew melon'),
    'cantaloupe': (547, 'Musk melon'),
    'watermelon': (549, 'Watermelon'),
    'nectarine': (576, 'Nectarine'),
    'papaya': (577, 'Papaya'),
    'peach': (580, 'Peach'),
    'pineapple': (550, 'Pineapple'),
    'plum': (582, 'Plum'),
    'pomegranate': (520, 'Pomegranate'),
    'quince': (569, 'Quince'),
    'passion_fruit': (579, 'Passion fruit'),
    'clementine': (560, 'Small citrus fruit clementine mandarin satsuma'),
    'mulberry': (7019, 'Mulberry'),
    'starfruit': (2570, 'Carambola (star fruit)'),
    'prickly_pear': (564, 'Prickly pear'),
    'kumquat': (568, 'Kumquat'),
    'plantain': (575, 'Plantain cooking banana'),
    'red_cabbage': (355, 'Red cabbage'),
    'savoy_cabbage': (357, 'Savoy cabbage'),
    'brussels_sprouts': (327, 'Brussels sprouts'),
    'eggplant': (372, 'Aubergine'),
    'zucchini': (362, 'Squash'),
    'red_pepper': (351, 'Bell pepper red'),
    'green_pepper': (350, 'Bell pepper green'),
    'yellow_pepper': (381, 'Bell pepper yellow'),
    'chili_pepper': (380, 'Chili pepper raw'),
    'leek': (354, 'Leek'),
    'kale': (337, 'Kale'),
    'cilantro': (7193, 'Coriander leaves'),
    'celery': (321, 'Celery'),
    'celeriac': (292, 'Celeriac'),
    'parsnip': (290, 'Parsnip'),
    'radish': (293, 'Radish'),
    'turnip': (297, 'Turnip'),
    'rutabaga': (288, 'Swede'),
    'sweet_potato': (3765, 'Sweet potatoe raw'),
    'sweet_corn': (345, 'Corn cobs'),
    'green_beans': (331, 'Green beans'),
    'fennel': (336, 'Fennel'),
    'artichoke': (342, 'Globe artichoke'),
    'swiss_chard': (348, 'Swiss chard'),
    'watercress': (367, 'Watercress'),
    'oyster_mushroom': (7035, 'Oyster mushroom'),
    'shiitake': (7034, 'Shiitake mushroom'),
    'ginger': (2269, 'Ginger fresh'),
    'kohlrabi': (343, 'Kohlrabi'),
    'bok_choy': (7192, 'Pak choi'),
    'chinese_cabbage': (358, 'Napa cabbage'),
    'arugula': (2561, 'Arugula rocket salad'),
    'romaine_lettuce': (2559, 'Romaine lettuce'),
    'cabbage': (370, 'White cabbage'),
}

# (id, Russian name, English name, category, SLV ID, exact API name)
NEW = [
    ('beef_raw', 'Говядина, сырая', 'Beef, raw', 'meat', 5066, 'Beef meat raw'),
    ('beef_sirloin_raw', 'Говяжий стейк, сырой', 'Beef sirloin, raw', 'meat', 946, 'Beef sirloin raw'),
    ('beef_tenderloin_raw', 'Говяжья вырезка, сырая', 'Beef tenderloin, raw', 'meat', 949, 'Beef tender loin raw'),
    ('beef_mince_10_raw', 'Говяжий фарш 10%, сырой', 'Beef mince 10% fat, raw', 'meat', 951, 'Beef minced meat raw 10% fat'),
    ('beef_mince_15_raw', 'Говяжий фарш 15%, сырой', 'Beef mince 15% fat, raw', 'meat', 963, 'Beef mince meat raw 15% fat'),
    ('beef_sirloin_fried', 'Говяжий стейк, жареный', 'Beef sirloin, fried', 'meat', 1014, 'Beef sirloin fried'),
    ('beef_roast_cooked', 'Говядина, варёная', 'Beef roast, boiled', 'meat', 1039, 'Beef roast or pot roast boiled w/ salt'),
    ('pork_raw', 'Свинина, сырая', 'Pork, raw', 'meat', 5447, 'Pork meat raw'),
    ('pork_tenderloin_raw', 'Свиная вырезка, сырая', 'Pork tenderloin, raw', 'meat', 970, 'Pork tenderloin raw'),
    ('pork_chop_raw', 'Свиная отбивная, сырая', 'Pork chop, raw', 'meat', 982, 'Pork chop raw w/o rind'),
    ('pork_mince_8_raw', 'Свиной фарш 8%, сырой', 'Pork mince 8% fat, raw', 'meat', 992, 'Pork minced meat raw 8% fat'),
    ('pork_mince_20_raw', 'Свиной фарш 20%, сырой', 'Pork mince 20% fat, raw', 'meat', 980, 'Pork minced meat raw 20% fat'),
    ('pork_tenderloin_cooked', 'Свиная вырезка, готовая', 'Pork tenderloin, cooked', 'meat', 6005, 'Pork tenderloin cooked'),
    ('pork_grilled', 'Свинина, гриль', 'Pork, grilled', 'meat', 1028, 'Pork meat grilled'),
    ('lamb_raw', 'Баранина, сырая', 'Lamb, raw', 'meat', 5067, 'Lamb meat raw'),
    ('lamb_roast', 'Баранина, запечённая', 'Lamb roast', 'meat', 1037, 'Lamb roast roasted'),
    ('veal_tenderloin_raw', 'Телячья вырезка, сырая', 'Veal tenderloin, raw', 'meat', 936, 'Veal tenderloin raw'),
    ('veal_tenderloin_fried', 'Телячья вырезка, жареная', 'Veal tenderloin, fried', 'meat', 1032, 'Veal tenderloin fried'),
    ('chicken_breast_raw', 'Куриная грудка без кожи, сырая', 'Chicken breast without skin, raw', 'meat', 1173, 'Chicken breast fillet raw w/o skin'),
    ('chicken_breast_fried', 'Куриная грудка без кожи, жареная', 'Chicken breast without skin, fried', 'meat', 1170, 'Chicken breast fillet fresh meat fried w/o skin'),
    ('chicken_boiled', 'Курица, варёная', 'Chicken, boiled', 'meat', 1181, 'Chicken boiled w/ salt'),
    ('turkey_fillet_raw', 'Филе индейки, сырое', 'Turkey fillet, raw', 'meat', 1162, 'Turkey fillet raw'),
    ('turkey_boiled', 'Индейка, варёная', 'Turkey, boiled', 'meat', 1178, 'Turkey boiled'),
    ('duck_breast_raw', 'Утиная грудка, сырая', 'Duck breast, raw', 'meat', 1151, 'Duck breast raw'),
    ('cod_raw', 'Треска, сырая', 'Cod, raw', 'fish', 1246, 'Cod raw'),
    ('cod_poached', 'Треска, отварная', 'Cod, poached', 'fish', 1335, 'Cod fillet poached w/ salt'),
    ('cod_fried', 'Треска, жареная', 'Cod, fried', 'fish', 1337, 'Cod fried'),
    ('salmon_farmed_raw', 'Лосось фермерский, сырой', 'Farmed salmon, raw', 'fish', 6225, 'Salmon farmed Norway raw'),
    ('salmon_wild_raw', 'Лосось дикий, сырой', 'Wild salmon, raw', 'fish', 6173, 'Salmon wild Sweden raw'),
    ('salmon_fried', 'Лосось, жареный', 'Salmon, fried', 'fish', 1316, 'Salmon fried w/ salt'),
    ('rainbow_trout_raw', 'Форель радужная, сырая', 'Rainbow trout, raw', 'fish', 1261, 'Rainbow trout farmed raw'),
    ('brown_trout_raw', 'Форель ручьевая, сырая', 'Brown trout, raw', 'fish', 1256, 'Brown trout brook trout Sweden raw'),
    ('arctic_char_raw', 'Голец, сырой', 'Arctic char, raw', 'fish', 1244, 'Arctic char raw'),
    ('tuna_raw', 'Тунец желтопёрый, сырой', 'Yellowfin tuna, raw', 'fish', 7156, 'Tuna yellowfin raw'),
    ('tuna_fried', 'Тунец, жареный', 'Tuna, fried', 'fish', 1334, 'Tuna fried w/ salt'),
    ('mackerel_raw', 'Скумбрия, сырая', 'Mackerel, raw', 'fish', 1260, 'Mackerel raw'),
    ('herring_raw', 'Сельдь, сырая', 'Herring, raw', 'fish', 1241, 'Herring raw'),
    ('haddock_raw', 'Пикша, сырая', 'Haddock, raw', 'fish', 1237, 'Haddock raw'),
    ('saithe_raw', 'Сайда, сырая', 'Saithe, raw', 'fish', 1202, 'Saithe raw'),
    ('plaice_raw', 'Камбала, сырая', 'Plaice, raw', 'fish', 1258, 'Plaice raw'),
    ('halibut_raw', 'Палтус дикий, сырой', 'Wild halibut, raw', 'fish', 1203, 'Halibut wild raw'),
    ('pike_raw', 'Щука, сырая', 'Pike, raw', 'fish', 1262, 'Pike raw'),
    ('perch_raw', 'Окунь, сырой', 'Perch, raw', 'fish', 1253, 'Perch raw'),
    ('hake_raw', 'Хек, сырой', 'Hake, raw', 'fish', 1238, 'Hake raw'),
    ('pollock_raw', 'Минтай, сырой', 'Alaska pollock, raw', 'fish', 4615, 'Alaska pollock raw'),
    ('shrimp_boiled', 'Креветки, варёные', 'Shrimp, boiled', 'fish', 1395, 'Shrimp boiled'),
]


def get_json(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.load(response)


def nutrients(item):
    product_id, expected_name = item
    detail = get_json(f'{API}/{product_id}?sprak=2')
    assert detail['namn'].strip() == expected_name.strip(), (product_id, detail['namn'], expected_name)
    values = get_json(f'{API}/{product_id}/naringsvarden?sprak=2')

    def value(code, unit):
        matches = [row['varde'] for row in values if row['euroFIRkod'] == code
                   and row['enhet'] == unit and row['viktGram'] == 100]
        assert len(matches) == 1, (product_id, code, matches)
        return matches[0]

    return product_id, {
        'calories': value('ENERC', 'kcal'),
        'protein': value('PROT', 'g'),
        'fat': value('FAT', 'g'),
        'carbs': value('CHO', 'g'),
        'slv_id': product_id,
        'fdc_id': '',
        'source_description': expected_name,
    }


def main():
    with CATALOG.open(newline='', encoding='utf-8') as file:
        rows = list(csv.DictReader(file))
    fields = list(rows[0])
    by_id = {row['id']: row for row in rows}
    selections = {row['id']: (int(row['slv_id']), row['source_description'])
                  for row in rows if row['slv_id']}
    selections.update(PRODUCE)
    selections.update({row[0]: (row[4], row[5]) for row in NEW})
    source_names = {}
    for number, description in selections.values():
        assert number not in source_names or source_names[number] == description
        source_names[number] = description
    assert all(key in by_id for key in PRODUCE)
    assert all(key not in by_id or by_id[key]['slv_id'] == str(number)
               for key, _, _, _, number, _ in NEW)

    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
        values = dict(pool.map(nutrients, source_names.items()))

    for key, (number, _) in selections.items():
        if key in by_id:
            by_id[key].update(values[number])
    for key, name, name_en, category, number, _ in NEW:
        if key not in by_id:
            row = dict.fromkeys(fields, '')
            row.update(id=key, name=name, name_en=name_en, category=category)
            rows.append(row)
            by_id[key] = row
        by_id[key].update(values[number])

    # Replace the old approximate chicken breast with an explicit cooked item.
    by_id['chicken'].update(name='Куриная грудка, жареная',
                            name_en='Chicken breast, fried',
                            category='meat', **values[1170])
    # The separate entry for this same source value is not needed.
    rows = [row for row in rows if row['id'] not in {'chicken_breast_fried', 'lamb_minced_raw'}]

    with CATALOG.open('w', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    print(f'Updated {len(PRODUCE)} produce; catalog now has {len(rows)} products.')


if __name__ == '__main__':
    main()
