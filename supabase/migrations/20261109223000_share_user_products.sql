-- Products submitted by an authenticated user are searchable by everyone
-- with an account. Only the creator can insert a row with their owner_id.
drop policy if exists "Read products" on public.products;
create policy "Read products" on public.products
  for select to authenticated using (true);
