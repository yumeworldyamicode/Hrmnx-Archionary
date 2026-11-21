# Archionary Admin Setup

## First account: 001@nemo

The first administrator is provisioned through the account page at `account.html`. The one-time bootstrap Edge Function is named `archionary-admin-bootstrap`.

Before the setup form can work, configure the Edge Function secret in the Supabase Dashboard:
1. Open Project Settings → Edge Functions → Secrets.
2. Add `ARCHIONARY_BOOTSTRAP_SECRET`.
3. Set it to a randomly generated value of at least 32 characters. Do not commit it to this repository or paste it into public issue trackers.
4. Open `account.html`, choose **First-time setup**, set a password of at least 12 characters, and enter the secret.
5. The endpoint only accepts the designated address `001@nemo`, checks whether the account already exists, confirms the Auth user without email delivery, and assigns the Archionary admin role through a service-role-only RPC.
6. Once created, use the Sign in tab. The bootstrap endpoint will not create a second account with that address.

The admin portal checks its restricted permissions before showing the dashboard. The Shimei Awards control room is also a separate management page.

## Administration modules

- Archive: browse existing records through `shimei_archive_search`, with source table + source record ID kept intact.
- Honours: create recognition records, associate them with source records, and publish/unpublish.
- Dictionary: create term/person/system/history entries and publish/unpublish.
- Special pages: create dedicated pages for approved people or subjects and publish/unpublish.
- Applications: review honour applications, special page requests, nominations, and set status/private notes.
- Shimei Awards: linked separate control room for seasons, entries, vote totals, nominations, winners, and audit log.

## Important source coverage

Existing tables are reused. The current connected database has published KiKi News stories, KiKi posts, public DEMs/demos, In-Home Artists, In-Home Artist songs/albums, and profile records. A separate music-post source table was not found in the connected project yet; once that exists, add it to the archive view.
