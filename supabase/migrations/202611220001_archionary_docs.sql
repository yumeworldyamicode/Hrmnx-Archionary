create table if not exists public.archionary_docs (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 slug text unique not null,
 summary text,
 body text not null default '',
 doc_category text not null default 'reference',
 published boolean not null default false,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.archionary_docs enable row level security;
drop policy if exists "public read published docs" on public.archionary_docs;
create policy "public read published docs" on public.archionary_docs for select to anon,authenticated using(published=true or private.is_archionary_admin());
drop policy if exists "admins manage docs" on public.archionary_docs;
create policy "admins manage docs" on public.archionary_docs for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
grant select on public.archionary_docs to anon,authenticated;
grant insert,update,delete on public.archionary_docs to authenticated;
