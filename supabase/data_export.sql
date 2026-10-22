-- ============================================================================
-- FULL DATA EXPORT — CONTAINS PERSONAL DATA (names, addresses, messages)
--
-- Use this on the FREE Supabase plan, which does NOT get automatic backups.
-- Keep the downloaded file private (password manager / private cloud folder).
-- Never commit the exported file to this public repository.
--
-- HOW TO USE
--   1. Supabase Dashboard -> SQL Editor -> New query.
--   2. Paste this whole file and click Run.
--   3. Click "Download CSV" (top-right of the results).
--   4. Rename it like:  pakikiramay-data-2026-10-22.csv
--   5. Store it somewhere private.
--
-- Do this monthly, and before any risky change.
--
-- NOTE: app_admin_secret holds the bcrypt HASH of the family PIN, not the
-- PIN itself. It is included so a restore keeps the same PIN. Treat the
-- file as sensitive either way.
-- ============================================================================

select 'app_admin_secret' as table_name, to_jsonb(t) as row_data
from public.app_admin_secret t

union all
select 'visitors', to_jsonb(t)
from public.visitors t

union all
select 'candle_messages', to_jsonb(t)
from public.candle_messages t

union all
select 'pakikiramay_messages', to_jsonb(t)
from public.pakikiramay_messages t

union all
select 'pakikiramay_replies', to_jsonb(t)
from public.pakikiramay_replies t

union all
select 'pakikiramay_reactions', to_jsonb(t)
from public.pakikiramay_reactions t

union all
select 'pakikiramay_reports', to_jsonb(t)
from public.pakikiramay_reports t

order by table_name;
