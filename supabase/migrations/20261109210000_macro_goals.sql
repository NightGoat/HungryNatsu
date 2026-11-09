alter table public.profiles
  add column if not exists protein_goal numeric(8,2) check (protein_goal between 0 and 10000),
  add column if not exists fat_goal numeric(8,2) check (fat_goal between 0 and 10000),
  add column if not exists carbs_goal numeric(8,2) check (carbs_goal between 0 and 10000);
