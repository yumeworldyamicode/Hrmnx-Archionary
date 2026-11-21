create or replace function public.archionary_bootstrap_grant_admin(target_user_id uuid)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if coalesce(auth.jwt()->>'role','')<>'service_role' then raise exception 'Not authorized'; end if;
 insert into private.archionary_admins(user_id) values(target_user_id) on conflict(user_id) do nothing;
end;
$$;
revoke all on function public.archionary_bootstrap_grant_admin(uuid) from public,anon,authenticated;
grant execute on function public.archionary_bootstrap_grant_admin(uuid) to service_role;