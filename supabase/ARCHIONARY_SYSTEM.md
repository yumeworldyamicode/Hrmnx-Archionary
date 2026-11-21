# Archionary System Foundation

## Shared database
Archionary currently uses the existing KiKi Supabase project (shared authentication and content tables). Archive entries are referenced by source table + source record ID; Archionary does not copy the underlying posts/news/music content into its own tables.

## Archive candidate search
The `public.shimei_archive_search` view is security-invoker and reads from the existing sources:
- Person: `profiles` where `profile_type='user'`
- Story: published `kiki_news_posts`
- Post: `posts` (KiKi posts)
- Demo: public/published `indesign_dems` and eligible public `song_demos`
- Artist: active `in_music_home_artists`
- Songwriter: `profiles` with songwriter/composer profile type
- Song: `in_music_home_songs`
- Album: album/full-album `in_music_home_releases`
- Event: manually entered in Shimei administration because the connected database has no dedicated cultural-events table.

There is not currently a separate InMusic music-post table in the connected project; add that source to the view when such a table is introduced.

## Shimei Awards workflow
- Season states: draft, first_vote, nominations, final_vote, closed.
- Voting rounds: 1 (fan vote) and 2 (final vote).
- Each authenticated user can submit/change one vote per season/category/round.
- Final-round vote eligibility is restricted to published nominations.
- Nominee limit defaults to 20 per category.
- Votes are private; voters can see their own vote and the Archionary admin can see vote data and aggregate tallies.
- Ties at the nomination cutoff are not auto-selected. Tied final winners are skipped and need manual resolution.
- Public winner records appear only once declared.

## Administration security
- Admin membership is in `private.archionary_admins`; no client can grant itself admin.
- `private.is_archionary_admin()` is used by RLS policies.
- Vote data and admin audit records are restricted by RLS.
- Admin audit log tracks season, round, candidate import, entry review, nomination generation/publishing, and winner declarations.

## First administrator
The intended Nemo address is `001@nemo`. This account is not yet present in Supabase Auth and is not yet assigned to the private Archionary admin list. After account provisioning, its Auth user ID must be added to `private.archionary_admins` by an authorized database/service-role administrator. Do not expose the service-role key in the website.

## Frontend configuration
`assets/js/supabase-config.js` contains the public Supabase URL and publishable key only. This is a browser-safe key; security relies on RLS and is not a secret.
