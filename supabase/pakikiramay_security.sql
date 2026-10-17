-- ============================================================================
-- Pakikiramay security hardening (run once in Supabase Dashboard > SQL Editor)
--
-- WHAT THIS FIXES
--   Before this script, every table of the Pakikiramay page was readable and
--   writable by ANYONE who has the public anon key (it ships in the app).
--   A visitor could edit or delete anyone's messages, read the private
--   candle messages and the visitor address book, and clear reports.
--
--   After this script:
--     * Everyone (anon key) can INSERT new rows and READ public content.
--     * Nobody can UPDATE or DELETE any table row directly — those actions
--       go through PIN-verified server functions (security definer RPCs).
--     * The app's family PIN is now checked INSIDE the database, not just
--       on the phone.
--
-- HOW TO USE
--   1. Paste this whole file into Supabase Dashboard > SQL Editor and Run.
--   2. Replace the family PIN from the app's built-in default by running:
--        update public.app_admin_secret
--        set pin_hash = crypt('YOUR_NEW_6_DIGIT_PIN', gen_salt('bf'));
--   3. Deploy the matching app update (this repository). The app first
--      tries the new server functions and falls back to the old paths on
--      an unmigrated project, so order of deployment does not matter.
--
-- SAFE TO RE-RUN (idempotent): policy drops, `if not exists`, and
-- `create or replace` throughout.
-- ============================================================================

-- 0. pgcrypto gives us crypt()/gen_salt() to hash the family PIN.
create extension if not exists pgcrypto;

-- ============================================================================
-- 1. Family admin secret (the PIN, bcrypt-hashed)
-- ============================================================================
create table if not exists public.app_admin_secret (
  id smallint primary key default 1 check (id = 1),
  pin_hash text not null,
  updated_at timestamptz not null default now()
);

-- Seed with the app's built-in default PIN ('538523') exactly once.
insert into public.app_admin_secret (id, pin_hash)
values (1, crypt('538523', gen_salt('bf')))
on conflict (id) do nothing;

-- The secret table itself must stay hidden from everyone.
alter table public.app_admin_secret enable row level security;
revoke all on public.app_admin_secret from anon, authenticated;

-- ============================================================================
-- 2. New columns: device ownership for self-edit / self-delete
-- ============================================================================
-- New posts/replies are stamped with the device id that created them.
-- Old rows keep '' (no owner) — their authors lose remote edit/delete,
-- which is accepted (it also blocks impersonation edits).
alter table public.pakikiramay_messages
  add column if not exists device_id text not null default '';
alter table public.pakikiramay_replies
  add column if not exists device_id text not null default '';

-- `approved` stops being set by the client. The database owns the default
-- and any stray NULLs are cleaned up.
update public.pakikiramay_messages set approved = true where approved is null;
alter table public.pakikiramay_messages
  alter column approved set not null,
  alter column approved set default true;

-- ============================================================================
-- 3. Row Level Security lockdown of every Pakikiramay table
-- ============================================================================
do $$
declare
  t text;
  r record;
  tables constant text[] := array[
    'pakikiramay_messages',
    'pakikiramay_replies',
    'pakikiramay_reactions',
    'pakikiramay_reports',
    'candle_messages',
    'visitors'
  ];
begin
  -- Drop ALL existing policies so stale permissive ones can't survive.
  foreach t in array tables loop
    for r in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = t
    loop
      execute format('drop policy if exists %I on public.%I', r.policyname, t);
    end loop;
  end loop;
end $$;

-- ---------------------------------------------------------------- messages
alter table public.pakikiramay_messages enable row level security;
revoke all on public.pakikiramay_messages from anon, authenticated;
grant select, insert on public.pakikiramay_messages to anon;

create policy pakikiramay_messages_select
  on public.pakikiramay_messages for select to anon
  using (approved is true);

create policy pakikiramay_messages_insert
  on public.pakikiramay_messages for insert to anon
  with check (true);

-- UPDATE / DELETE: deliberately NO policy = nobody (not even the family)
-- may do it directly. Family moderation uses the admin RPCs below.

-- ----------------------------------------------------------------- replies
alter table public.pakikiramay_replies enable row level security;
revoke all on public.pakikiramay_replies from anon, authenticated;
grant select, insert on public.pakikiramay_replies to anon;

create policy pakikiramay_replies_select
  on public.pakikiramay_replies for select to anon
  using (true);

create policy pakikiramay_replies_insert
  on public.pakikiramay_replies for insert to anon
  with check (true);

-- --------------------------------------------------------------- reactions
-- Readable (public likes + names) and insertable. Unlike goes through
-- pakikiramay_unlike() so a leaked device id can't wipe random rows.
alter table public.pakikiramay_reactions enable row level security;
revoke all on public.pakikiramay_reactions from anon, authenticated;
grant select, insert on public.pakikiramay_reactions to anon;

create policy pakikiramay_reactions_select
  on public.pakikiramay_reactions for select to anon
  using (true);

create policy pakikiramay_reactions_insert
  on public.pakikiramay_reactions for insert to anon
  with check (true);

-- ------------------------------------------------------------------ reports
-- Insert-only. Counts are read through pakikiramay_report_counts() so the
-- raw report text/details stay private.
alter table public.pakikiramay_reports enable row level security;
revoke all on public.pakikiramay_reports from anon, authenticated;
grant insert on public.pakikiramay_reports to anon;

create policy pakikiramay_reports_insert
  on public.pakikiramay_reports for insert to anon
  with check (true);

-- ---------------------------------------------------------- candle_messages
-- PRIVATE congratulations-by-candle: insert only. Family reads/edits via
-- the candle admin RPCs.
alter table public.candle_messages enable row level security;
revoke all on public.candle_messages from anon, authenticated;
grant insert on public.candle_messages to anon;

create policy candle_messages_insert
  on public.candle_messages for insert to anon
  with check (true);

-- ---------------------------------------------------------------- visitors
-- The gate log: insert only, no public SELECT (addresses stay private).
-- The public candle page gets its count + names-only list through the
-- narrow RPCs below.
alter table public.visitors enable row level security;
revoke all on public.visitors from anon, authenticated;
grant insert on public.visitors to anon;

create policy visitors_insert
  on public.visitors for insert to anon
  with check (true);

-- ============================================================================
-- 4. PIN verification helper (used by every admin function)
-- ============================================================================
create or replace function public.pakikiramay_admin_ok(p_pin text)
returns boolean
language sql stable security definer
set search_path = public, extensions
as $$
  select p_pin is not null
     and p_pin ~ '^\d{6}$'
     and exists (
       select 1 from public.app_admin_secret s
       where s.id = 1
         and s.pin_hash = crypt(p_pin, s.pin_hash)
     );
$$;

-- Family can change the server PIN from the app (Change-PIN dialog).
create or replace function public.pakikiramay_admin_change_pin(
  p_old_pin text,
  p_new_pin text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  if not public.pakikiramay_admin_ok(p_old_pin) then
    return false;
  end if;
  if p_new_pin is null or p_new_pin !~ '^\d{6}$'
     or p_new_pin = p_old_pin then
    return false;
  end if;
  update public.app_admin_secret
  set pin_hash = crypt(p_new_pin, gen_salt('bf')),
      updated_at = now()
  where id = 1;
  return found;
end;
$$;

-- ============================================================================
-- 5. Public helper RPCs (no PIN needed — deliberately narrow)
-- ============================================================================

-- Shared reaction/report counts and candle page numbers as aggregates only.
create or replace function public.pakikiramay_report_counts()
returns table (target_id uuid, report_count bigint)
language sql stable security definer
set search_path = public, extensions
as $$
  select target_id, count(*)::bigint
  from public.pakikiramay_reports
  group by target_id;
$$;

-- Candle page: how many candles (visitors) have been logged.
create or replace function public.pakikiramay_candle_count()
returns integer
language sql stable security definer
set search_path = public, extensions
as $$
  select count(*)::integer from public.visitors;
$$;

-- Candle page: names only, newest first. Addresses and lang stay inside.
create or replace function public.pakikiramay_candle_names(p_limit integer default 50)
returns table (name text, created_at timestamptz)
language sql stable security definer
set search_path = public, extensions
as $$
  select v.name, v.created_at
  from public.visitors v
  order by v.created_at desc
  limit coalesce(p_limit, 50)::integer;
$$;

-- Like a post/reply (server dedupes nothing; the unique index stays in the
-- client's interest) is a plain INSERT — allowed by the insert policy.

create or replace function public.pakikiramay_unlike(
  p_target_id uuid,
  p_reaction_type text,
  p_device_id text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  if p_target_id is null or p_device_id is null
     or length(btrim(p_device_id)) = 0 then
    return false;
  end if;
  delete from public.pakikiramay_reactions
  where target_id = p_target_id
    and reaction_type = p_reaction_type
    and device_id = p_device_id;
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

-- ============================================================================
-- 6. Self-service edit / delete (device-id qualified, edit window enforced)
-- ============================================================================

-- Edit your own message. Owner must match AND the 15-minute edit window.
create or replace function public.pakikiramay_edit_message(
  p_id uuid,
  p_device_id text,
  p_message text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  if p_message is null
     or length(btrim(p_message)) = 0
     or length(btrim(p_message)) > 1000 then
    return false;
  end if;
  update public.pakikiramay_messages
  set message = btrim(p_message)
  where id = p_id
    and device_id = p_device_id
    and device_id <> ''          -- legacy rows (before this migration) unowned
    and created_at >= now() - interval '15 minutes';
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

-- Edit your own reply (same rules).
create or replace function public.pakikiramay_edit_reply(
  p_id uuid,
  p_post_id uuid,
  p_device_id text,
  p_message text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  if p_message is null
     or length(btrim(p_message)) = 0
     or length(btrim(p_message)) > 1000 then
    return false;
  end if;
  update public.pakikiramay_replies
  set message = btrim(p_message)
  where id = p_id
    and post_id = p_post_id
    and device_id = p_device_id
    and device_id <> ''
    and created_at >= now() - interval '15 minutes';
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

-- Delete your own message (+ its replies first, so non-cascade databases
-- stay consistent). No time limit, mirrors the app's rule.
create or replace function public.pakikiramay_delete_message(
  p_id uuid,
  p_device_id text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  delete from public.pakikiramay_replies
  where post_id = p_id
    and device_id = p_device_id
    and device_id <> '';
  delete from public.pakikiramay_messages
  where id = p_id
    and device_id = p_device_id
    and device_id <> '';
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

-- Delete your own reply.
create or replace function public.pakikiramay_delete_reply(
  p_id uuid,
  p_post_id uuid,
  p_device_id text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  delete from public.pakikiramay_replies
  where id = p_id
    and post_id = p_post_id
    and device_id = p_device_id
    and device_id <> '';
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

-- ============================================================================
-- 7. Family-admin RPCs (PIN verified inside the database, old PIN fails)
-- ============================================================================

-- List report rows for the moderation page. A wrong PIN raises
-- `insufficient_privilege` (HTTP 403) so the app can show "no permission"
-- instead of a misleading empty list.
create or replace function public.pakikiramay_admin_list_reports(
  p_pin text,
  p_limit integer default 200
)
returns table (
  id uuid,
  target_id uuid,
  target_kind text,
  reason text,
  details text,
  reporter_name text,
  created_at timestamptz
)
language plpgsql stable security definer
set search_path = public, extensions
as $$
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    raise insufficient_privilege
      using message = 'pakikiramay: wrong family PIN';
  end if;
  return query
    select r.id, r.target_id, r.target_kind, r.reason, r.details,
           r.reporter_name, r.created_at
    from public.pakikiramay_reports r
    order by r.created_at desc
    limit coalesce(p_limit, 200)::integer;
end;
$$;

-- Edit any message (admin; bypasses device ownership + edit window).
create or replace function public.pakikiramay_admin_edit_message(
  p_pin text,
  p_id uuid,
  p_message text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    return false;
  end if;
  if p_message is null
     or length(btrim(p_message)) = 0
     or length(btrim(p_message)) > 1000 then
    return false;
  end if;
  update public.pakikiramay_messages
  set message = btrim(p_message)
  where id = p_id;
  return found;
end;
$$;

-- Edit any reply.
create or replace function public.pakikiramay_admin_edit_reply(
  p_pin text,
  p_post_id uuid,
  p_reply_id uuid,
  p_message text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    return false;
  end if;
  if p_message is null
     or length(btrim(p_message)) = 0
     or length(btrim(p_message)) > 1000 then
    return false;
  end if;
  update public.pakikiramay_replies
  set message = btrim(p_message)
  where id = p_reply_id
    and post_id = p_post_id;
  return found;
end;
$$;

-- Delete a post (+ its replies), or one reply (parent post verified).
create or replace function public.pakikiramay_admin_delete_target(
  p_pin text,
  p_target_kind text,          -- 'post' or 'reply'
  p_target_id uuid,
  p_parent_post_id uuid default null
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare
  v_deleted int;
  v_parent uuid;
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    return false;
  end if;
  if lower(coalesce(p_target_kind, '')) = 'reply' then
    if p_parent_post_id is null then
      return false;
    end if;
    -- Verify the reply really belongs to that parent.
    select post_id into v_parent
    from public.pakikiramay_replies
    where id = p_target_id;
    if v_parent is null or v_parent <> p_parent_post_id then
      return false;
    end if;
    delete from public.pakikiramay_replies where id = p_target_id;
    get diagnostics v_deleted = row_count;
    return v_deleted > 0;
  end if;

  if p_target_id is null then
    return false;
  end if;
  delete from public.pakikiramay_replies where post_id = p_target_id;
  delete from public.pakikiramay_messages where id = p_target_id;
  get diagnostics v_deleted = row_count;
  return v_deleted > 0;
end;
$$;

-- Dismiss (delete) all reports against one target ("family reviewed,
-- kept the message"). Remote duplicates (double submit) are fine to send
-- from the client because the caller only needs one OK'd result.
create or replace function public.pakikiramay_admin_dismiss_reports(
  p_pin text,
  p_target_id uuid
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare v_removed int := 0;
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    return false;
  end if;
  if p_target_id is null then
    return false;
  end if;
  delete from public.pakikiramay_reports where target_id = p_target_id;
  get diagnostics v_removed = row_count;
  return v_removed > 0;
end;
$$;

-- Private candle messages: list / edit / delete (PIN gated; a wrong PIN
-- raises insufficient_privilege on the list call).
create or replace function public.pakikiramay_admin_list_candles(
  p_pin text,
  p_limit integer default 200
)
returns table (id uuid, name text, message text, created_at timestamptz)
language plpgsql stable security definer
set search_path = public, extensions
as $$
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    raise insufficient_privilege
      using message = 'pakikiramay: wrong family PIN';
  end if;
  return query
    select c.id, c.name, c.message, c.created_at
    from public.candle_messages c
    order by c.created_at desc
    limit coalesce(p_limit, 200)::integer;
end;
$$;

create or replace function public.pakikiramay_admin_edit_candle(
  p_pin text,
  p_id uuid,
  p_message text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    return false;
  end if;
  if p_message is null or length(btrim(p_message)) = 0
     or length(btrim(p_message)) > 500 then
    return false;
  end if;
  update public.candle_messages
  set message = btrim(p_message)
  where id = p_id;
  return found;
end;
$$;

create or replace function public.pakikiramay_admin_delete_candle(
  p_pin text,
  p_id uuid
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    return false;
  end if;
  delete from public.candle_messages where id = p_id;
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

-- Visitors: list / edit / delete for the family admin page (PIN gated;
-- a wrong PIN raises insufficient_privilege on the list call).
create or replace function public.pakikiramay_admin_list_visitors(
  p_pin text,
  p_limit integer default 200
)
returns table (
  id uuid, name text, address text, lang text, created_at timestamptz
)
language plpgsql stable security definer
set search_path = public, extensions
as $$
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    raise insufficient_privilege
      using message = 'pakikiramay: wrong family PIN';
  end if;
  return query
    select v.id, v.name, v.address, v.lang, v.created_at
    from public.visitors v
    order by v.created_at desc
    limit coalesce(p_limit, 200)::integer;
end;
$$;

create or replace function public.pakikiramay_admin_update_visitor(
  p_pin text,
  p_id uuid,
  p_name text,
  p_address text
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    return false;
  end if;
  if p_name is null or length(btrim(p_name)) = 0
     or p_address is null
     or length(btrim(p_address)) < 3
     or length(btrim(p_address)) > 200 then
    return false;
  end if;
  update public.visitors
  set name = btrim(p_name), address = btrim(p_address)
  where id = p_id;
  return found;
end;
$$;

create or replace function public.pakikiramay_admin_delete_visitor(
  p_pin text,
  p_id uuid
)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  if not public.pakikiramay_admin_ok(p_pin) then
    return false;
  end if;
  delete from public.visitors where id = p_id;
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

-- ============================================================================
-- Done. Reminder: change the family PIN with
--   update public.app_admin_secret set pin_hash = crypt('888888', gen_salt('bf'));
-- ============================================================================
