create table if not exists public.archionary_honours (
 id uuid primary key default gen_random_uuid(),honour_type text not null check(honour_type in ('person','story','post','music','demo','event','artist','songwriter','song','album','milestone','special')),
 title text not null,subtitle text,description text,source_table text,source_record_id text,source_url text,slug text unique,featured boolean not null default false,published boolean not null default false,award_year integer,created_by uuid references auth.users(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.archionary_dictionary_entries (
 id uuid primary key default gen_random_uuid(),entry_type text not null check(entry_type in ('term','person','artist','songwriter','system','service','history','place','other')),title text not null,slug text unique,summary text,body text,related_entry_ids uuid[] not null default '{}',source_table text,source_record_id text,published boolean not null default false,created_by uuid references auth.users(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.archionary_special_pages (
 id uuid primary key default gen_random_uuid(),title text not null,slug text unique,subtitle text,body text,subject_type text,subject_id text,application_id uuid, published boolean not null default false,created_by uuid references auth.users(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.archionary_applications (
 id uuid primary key default gen_random_uuid(),application_type text not null,applicant_name text not null,contact_email text not null,subject text not null,links text,reason text not null,status text not null default 'pending' check(status in ('pending','reviewing','approved','declined','closed')),admin_notes text,submitted_at timestamptz not null default now(),reviewed_at timestamptz,reviewed_by uuid references auth.users(id)
);
alter table public.archionary_honours enable row level security;
alter table public.archionary_dictionary_entries enable row level security;
alter table public.archionary_special_pages enable row level security;
alter table public.archionary_applications enable row level security;
drop policy if exists "public read published honours" on public.archionary_honours;
create policy "public read published honours" on public.archionary_honours for select to anon,authenticated using(published=true or private.is_archionary_admin());
drop policy if exists "admins manage honours" on public.archionary_honours;
create policy "admins manage honours" on public.archionary_honours for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
drop policy if exists "public read published dictionary" on public.archionary_dictionary_entries;
create policy "public read published dictionary" on public.archionary_dictionary_entries for select to anon,authenticated using(published=true or private.is_archionary_admin());
drop policy if exists "admins manage dictionary" on public.archionary_dictionary_entries;
create policy "admins manage dictionary" on public.archionary_dictionary_entries for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
drop policy if exists "public read published special pages" on public.archionary_special_pages;
create policy "public read published special pages" on public.archionary_special_pages for select to anon,authenticated using(published=true or private.is_archionary_admin());
drop policy if exists "admins manage special pages" on public.archionary_special_pages;
create policy "admins manage special pages" on public.archionary_special_pages for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
drop policy if exists "public submit applications" on public.archionary_applications;
create policy "public submit applications" on public.archionary_applications for insert to anon,authenticated with check(status='pending' and admin_notes is null and reviewed_at is null and reviewed_by is null);
drop policy if exists "admins view applications" on public.archionary_applications;
create policy "admins view applications" on public.archionary_applications for select to authenticated using(private.is_archionary_admin());
drop policy if exists "admins update applications" on public.archionary_applications;
create policy "admins update applications" on public.archionary_applications for update to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
grant select on public.archionary_honours,public.archionary_dictionary_entries,public.archionary_special_pages to anon,authenticated;
grant insert,update,delete on public.archionary_honours,public.archionary_dictionary_entries,public.archionary_special_pages to authenticated;
grant insert on public.archionary_applications to anon,authenticated;
grant select,update on public.archionary_applications to authenticated;
