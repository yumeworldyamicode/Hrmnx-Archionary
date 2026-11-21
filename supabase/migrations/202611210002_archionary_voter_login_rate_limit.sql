create table if not exists private.archionary_login_attempts (
 id bigint generated always as identity primary key,
 ip_hash text not null,
 username_hash text not null,
 created_at timestamptz not null default now()
);
alter table private.archionary_login_attempts enable row level security;
revoke all on private.archionary_login_attempts from anon,authenticated;
grant all on private.archionary_login_attempts to service_role;
create index if not exists archionary_login_attempts_window_idx on private.archionary_login_attempts(ip_hash,username_hash,created_at);
