-- Archionary / Shimei Awards base system
-- Content remains in the existing KiKi / InDesign / InMusic tables.
-- This migration creates only award workflow metadata, votes and curated entry references.
create schema if not exists private;
create table if not exists private.archionary_admins (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 granted_by uuid references auth.users(id)
);
alter table private.archionary_admins enable row level security;
revoke all on private.archionary_admins from anon,authenticated;
create or replace function private.is_archionary_admin()
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from private.archionary_admins a where a.user_id=(select auth.uid())); $$;
revoke all on function private.is_archionary_admin() from public;
grant usage on schema private to authenticated;
grant execute on function private.is_archionary_admin() to authenticated;

create table if not exists public.shimei_seasons (
 id uuid primary key default gen_random_uuid(), season_year integer not null unique,
 title text not null default 'Shimei Awards', award_date date not null,
 status text not null default 'draft' check(status in ('draft','first_vote','nominations','final_vote','closed')),
 nominee_limit integer not null default 20 check(nominee_limit between 1 and 100),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.shimei_categories (
 id text primary key,label text not null,description text not null,source_types text[] not null default '{}',sort_order int not null unique
);
create table if not exists public.shimei_rounds (
 id uuid primary key default gen_random_uuid(),season_id uuid not null references public.shimei_seasons(id) on delete cascade,
 round_number smallint not null check(round_number in (1,2)),label text not null,
 status text not null default 'pending' check(status in ('pending','open','closed')),
 opens_at timestamptz,closes_at timestamptz,created_at timestamptz not null default now(),
 unique(season_id,round_number),check(closes_at is null or opens_at is null or closes_at>opens_at)
);
create table if not exists public.shimei_entries (
 id uuid primary key default gen_random_uuid(),season_id uuid not null references public.shimei_seasons(id) on delete cascade,
 category_id text not null references public.shimei_categories(id),source_table text,source_record_id text,
 display_title text not null,display_subtitle text not null default '',entry_url text,summary text not null default '',
 entry_kind text not null default 'archive' check(entry_kind in ('archive','manual')),
 eligible boolean not null default true,approval_status text not null default 'pending' check(approval_status in ('pending','approved','rejected','withdrawn')),
 added_by uuid references auth.users(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 unique(season_id,category_id,source_table,source_record_id),
 check(entry_kind='manual' or (source_table is not null and source_record_id is not null))
);
create table if not exists public.shimei_votes (
 id uuid primary key default gen_random_uuid(),season_id uuid not null references public.shimei_seasons(id) on delete cascade,
 round_number smallint not null check(round_number in (1,2)),category_id text not null references public.shimei_categories(id),
 entry_id uuid not null references public.shimei_entries(id) on delete cascade,voter_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 unique(season_id,round_number,category_id,voter_id)
);
create table if not exists public.shimei_nominations (
 id uuid primary key default gen_random_uuid(),season_id uuid not null references public.shimei_seasons(id) on delete cascade,
 category_id text not null references public.shimei_categories(id),entry_id uuid not null references public.shimei_entries(id) on delete cascade,
 rank_position int check(rank_position between 1 and 100),nomination_status text not null default 'draft' check(nomination_status in ('draft','published','removed')),
 vote_count bigint not null default 0,nominated_by uuid references auth.users(id),created_at timestamptz not null default now(),
 unique(season_id,category_id,entry_id)
);
create table if not exists public.shimei_winners (
 id uuid primary key default gen_random_uuid(),season_id uuid not null references public.shimei_seasons(id) on delete cascade,
 category_id text not null references public.shimei_categories(id),entry_id uuid not null references public.shimei_entries(id) on delete restrict,
 final_vote_count bigint not null default 0,declared_at timestamptz,declared_by uuid references auth.users(id),
 unique(season_id,category_id)
);
create table if not exists public.shimei_admin_audit (
 id bigint generated always as identity primary key,season_id uuid references public.shimei_seasons(id) on delete set null,
 actor_id uuid references auth.users(id),action text not null,object_type text,object_id text,details jsonb not null default '{}',created_at timestamptz not null default now()
);
create index if not exists shimei_entries_season_category_idx on public.shimei_entries(season_id,category_id,approval_status);
create index if not exists shimei_votes_entry_idx on public.shimei_votes(season_id,round_number,category_id,entry_id);
create index if not exists shimei_votes_voter_idx on public.shimei_votes(voter_id,season_id);
create index if not exists shimei_nominations_status_idx on public.shimei_nominations(season_id,category_id,nomination_status,rank_position);

alter table public.shimei_seasons enable row level security;
alter table public.shimei_categories enable row level security;
alter table public.shimei_rounds enable row level security;
alter table public.shimei_entries enable row level security;
alter table public.shimei_votes enable row level security;
alter table public.shimei_nominations enable row level security;
alter table public.shimei_winners enable row level security;
alter table public.shimei_admin_audit enable row level security;

drop policy if exists shimei_categories_public_read on public.shimei_categories;
create policy shimei_categories_public_read on public.shimei_categories for select to anon,authenticated using(true);
drop policy if exists shimei_seasons_public_read on public.shimei_seasons;
create policy shimei_seasons_public_read on public.shimei_seasons for select to anon,authenticated using(status<>'draft');
drop policy if exists shimei_seasons_staff_all on public.shimei_seasons;
create policy shimei_seasons_staff_all on public.shimei_seasons for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
drop policy if exists shimei_rounds_public_read on public.shimei_rounds;
create policy shimei_rounds_public_read on public.shimei_rounds for select to anon,authenticated using(status='open');
drop policy if exists shimei_rounds_staff_all on public.shimei_rounds;
create policy shimei_rounds_staff_all on public.shimei_rounds for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
drop policy if exists shimei_entries_public_read on public.shimei_entries;
create policy shimei_entries_public_read on public.shimei_entries for select to anon,authenticated using(eligible=true and approval_status='approved');
drop policy if exists shimei_entries_staff_all on public.shimei_entries;
create policy shimei_entries_staff_all on public.shimei_entries for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
drop policy if exists shimei_votes_voter_read on public.shimei_votes;
create policy shimei_votes_voter_read on public.shimei_votes for select to authenticated using(voter_id=(select auth.uid()));
drop policy if exists shimei_votes_staff_read on public.shimei_votes;
create policy shimei_votes_staff_read on public.shimei_votes for select to authenticated using(private.is_archionary_admin());
drop policy if exists shimei_votes_insert_open_round on public.shimei_votes;
create policy shimei_votes_insert_open_round on public.shimei_votes for insert to authenticated with check(
 voter_id=(select auth.uid())
 and exists(select 1 from public.shimei_seasons s where s.id=shimei_votes.season_id and s.status in ('first_vote','final_vote'))
 and exists(select 1 from public.shimei_rounds r where r.season_id=shimei_votes.season_id and r.round_number=shimei_votes.round_number and r.status='open' and (r.opens_at is null or r.opens_at<=now()) and (r.closes_at is null or r.closes_at>now()))
 and exists(select 1 from public.shimei_entries e where e.id=shimei_votes.entry_id and e.season_id=shimei_votes.season_id and e.category_id=shimei_votes.category_id and e.eligible=true and e.approval_status='approved')
 and ((shimei_votes.round_number=1 and exists(select 1 from public.shimei_seasons s where s.id=shimei_votes.season_id and s.status='first_vote')) or (shimei_votes.round_number=2 and exists(select 1 from public.shimei_seasons s where s.id=shimei_votes.season_id and s.status='final_vote') and exists(select 1 from public.shimei_nominations n where n.season_id=shimei_votes.season_id and n.category_id=shimei_votes.category_id and n.entry_id=shimei_votes.entry_id and n.nomination_status='published')))
);
drop policy if exists shimei_votes_update_open_round on public.shimei_votes;
create policy shimei_votes_update_open_round on public.shimei_votes for update to authenticated using(voter_id=(select auth.uid())) with check(
 voter_id=(select auth.uid())
 and exists(select 1 from public.shimei_seasons s where s.id=shimei_votes.season_id and s.status in ('first_vote','final_vote'))
 and exists(select 1 from public.shimei_rounds r where r.season_id=shimei_votes.season_id and r.round_number=shimei_votes.round_number and r.status='open' and (r.opens_at is null or r.opens_at<=now()) and (r.closes_at is null or r.closes_at>now()))
 and exists(select 1 from public.shimei_entries e where e.id=shimei_votes.entry_id and e.season_id=shimei_votes.season_id and e.category_id=shimei_votes.category_id and e.eligible=true and e.approval_status='approved')
 and (shimei_votes.round_number=1 or exists(select 1 from public.shimei_nominations n where n.season_id=shimei_votes.season_id and n.category_id=shimei_votes.category_id and n.entry_id=shimei_votes.entry_id and n.nomination_status='published'))
);
drop policy if exists shimei_nominations_public_read on public.shimei_nominations;
create policy shimei_nominations_public_read on public.shimei_nominations for select to anon,authenticated using(nomination_status='published');
drop policy if exists shimei_nominations_staff_all on public.shimei_nominations;
create policy shimei_nominations_staff_all on public.shimei_nominations for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
drop policy if exists shimei_winners_public_read on public.shimei_winners;
create policy shimei_winners_public_read on public.shimei_winners for select to anon,authenticated using(declared_at is not null);
drop policy if exists shimei_winners_staff_all on public.shimei_winners;
create policy shimei_winners_staff_all on public.shimei_winners for all to authenticated using(private.is_archionary_admin()) with check(private.is_archionary_admin());
drop policy if exists shimei_audit_staff_read on public.shimei_admin_audit;
create policy shimei_audit_staff_read on public.shimei_admin_audit for select to authenticated using(private.is_archionary_admin());
drop policy if exists shimei_audit_staff_insert on public.shimei_admin_audit;
create policy shimei_audit_staff_insert on public.shimei_admin_audit for insert to authenticated with check(private.is_archionary_admin());

insert into public.shimei_categories(id,label,description,source_types,sort_order) values
('person','Person','KiKi users',array['profile'],1),('story','Story','News stories',array['news'],2),('post','Post','KiKi posts',array['post'],3),
('demo','Demo','DEM / Demo',array['song_demo','indesign_dem'],4),('event','Event','Cultural events',array['manual_event'],5),
('artist','Artist','In-Home Artists',array['in_music_home_artist'],6),('songwriter','Songwriter','InDesign Music songwriters',array['profile_songwriter','manual_songwriter'],7),
('song','Song','In-Home Artist songs',array['in_music_home_song'],8),('album','Album','In-Home Artist albums',array['in_music_home_album'],9)
on conflict(id) do update set label=excluded.label,description=excluded.description,source_types=excluded.source_types,sort_order=excluded.sort_order;
insert into public.shimei_seasons(season_year,award_date,status,title) values(2027,'2027-09-30','draft','Shimei Awards 2027') on conflict(season_year) do nothing;
insert into public.shimei_rounds(season_id,round_number,label,status) select id,1,'First fan vote','pending' from public.shimei_seasons where season_year=2027 on conflict(season_id,round_number) do nothing;
insert into public.shimei_rounds(season_id,round_number,label,status) select id,2,'Final fan vote','pending' from public.shimei_seasons where season_year=2027 on conflict(season_id,round_number) do nothing;

create or replace view public.shimei_archive_search with (security_invoker=true) as
select 'person'::text category_id,'profiles'::text source_table,p.id::text source_record_id,coalesce(nullif(p.display_name,''),p.username) display_title,coalesce(p.username,'') display_subtitle,coalesce(p.bio,'') summary,null::text entry_url from public.profiles p where p.profile_type='user'
union all select 'story','kiki_news_posts',n.id::text,n.title,coalesce(n.subtitle,''),'',null::text from public.kiki_news_posts n where n.is_published=true
union all select 'post','posts',po.id::text,coalesce(nullif(po.title,''),'KiKi post #'||po.id::text),coalesce(p.username,''),left(po.content,240),null::text from public.posts po left join public.profiles p on p.id=po.author_id
union all select 'demo','indesign_dems',d.id::text,d.title,d.artist,coalesce(d.description,''),null::text from public.indesign_dems d where d.visibility='public' and d.is_public=true and (d.scheduled_at is null or d.scheduled_at<=now())
union all select 'demo','song_demos',sd.id::text,sd.title,coalesce(a.name,''),sd.demo_type,null::text from public.song_demos sd left join public.artists a on a.id=sd.artist_id where sd.visibility='public' and sd.status in ('published','poll_active','poll_ended','under_review','approved','released')
union all select 'artist','in_music_home_artists',a.id::text,a.artist_name,a.artist_type,a.description,null::text from public.in_music_home_artists a where a.is_active=true
union all select 'songwriter','profiles',p.id::text,coalesce(nullif(p.display_name,''),p.username),coalesce(p.username,''),coalesce(p.bio,''),null::text from public.profiles p where p.profile_type in ('songwriter','composer')
union all select 'song','in_music_home_songs',s.id::text,s.title,a.artist_name,coalesce(s.dem_slug,''),null::text from public.in_music_home_songs s join public.in_music_home_artists a on a.id=s.home_artist_id
union all select 'album','in_music_home_releases',r.id::text,r.title,a.artist_name,coalesce(r.description,''),null::text from public.in_music_home_releases r join public.in_music_home_artists a on a.id=r.home_artist_id where lower(r.release_type) in ('album','full album');
grant select on public.shimei_archive_search to anon,authenticated;
create or replace view public.shimei_vote_tallies with (security_invoker=true) as select season_id,round_number,category_id,entry_id,count(*)::bigint vote_count from public.shimei_votes group by season_id,round_number,category_id,entry_id;
grant select on public.shimei_vote_tallies to authenticated;
grant select on public.shimei_categories,public.shimei_seasons,public.shimei_rounds,public.shimei_entries,public.shimei_nominations,public.shimei_winners,public.shimei_archive_search to anon,authenticated;
grant select,insert,update,delete on public.shimei_entries,public.shimei_seasons,public.shimei_rounds,public.shimei_nominations,public.shimei_winners to authenticated;
grant select,insert,update on public.shimei_votes to authenticated;
grant select,insert on public.shimei_admin_audit to authenticated;
