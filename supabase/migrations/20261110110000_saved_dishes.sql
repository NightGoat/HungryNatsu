create table if not exists public.dishes (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  servings integer not null check (servings > 0),
  ingredients jsonb not null check (
    jsonb_typeof(ingredients) = 'array' and ingredients <> '[]'::jsonb
  )
);

create index if not exists dishes_user_name_idx on public.dishes (user_id, name, id);

alter table public.dishes enable row level security;
drop policy if exists "Manage own dishes" on public.dishes;
create policy "Manage own dishes" on public.dishes
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
grant select, insert, update on public.dishes to authenticated;

alter table public.diary_entries
  add column if not exists servings numeric check (servings > 0 and servings < 'Infinity'::numeric),
  alter column grams type numeric,
  drop constraint if exists diary_entries_grams_check;

alter table public.diary_entries
  add constraint diary_entries_grams_check check (
    grams > 0 and grams < 'Infinity'::numeric and (servings is not null or grams <= 10000)
  );
