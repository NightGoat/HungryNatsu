-- USDA FoodData Central SR Legacy 2018: explicitly raw nuts.
begin;
insert into public.products (name, name_en, calories, protein, fat, carbs, slv_id, fdc_id) values
  ('Кешью, сырой', 'Cashews, raw', 553, 18.22, 43.85, 30.19, null, 170162),
  ('Макадамия, сырая', 'Macadamia nuts, raw', 718, 7.91, 75.77, 13.82, null, 170178),
  ('Фисташки, сырые', 'Pistachios, raw', 560, 20.16, 45.32, 27.17, null, 170184),
  ('Арахис, сырой', 'Peanuts, raw', 567, 25.8, 49.24, 16.13, null, 172430),
  ('Каштаны европейские, сырые', 'European chestnuts, raw', 196, 1.63, 1.25, 44.17, null, 170575),
  ('Кокосовая мякоть, сырая', 'Coconut meat, raw', 354, 3.33, 33.49, 15.23, null, 170169)
on conflict (name) where owner_id is null do update set
  name_en = excluded.name_en, calories = excluded.calories, protein = excluded.protein,
  fat = excluded.fat, carbs = excluded.carbs, slv_id = excluded.slv_id, fdc_id = excluded.fdc_id;
commit;
