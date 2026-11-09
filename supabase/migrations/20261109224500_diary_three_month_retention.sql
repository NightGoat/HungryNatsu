-- Keep diary entries from the current calendar day minus three months onward.
create extension if not exists pg_cron;

drop policy if exists "Create own diary" on public.diary_entries;
create policy "Create own diary" on public.diary_entries
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and eaten_at >= date_trunc('day', now() - interval '3 months')
  );

delete from public.diary_entries
where eaten_at < date_trunc('day', now() - interval '3 months');

select cron.schedule(
  'purge-old-diary-entries',
  '0 3 * * *',
  $$delete from public.diary_entries
    where eaten_at < date_trunc('day', now() - interval '3 months')$$
);
