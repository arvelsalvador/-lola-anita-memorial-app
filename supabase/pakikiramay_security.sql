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
--     * `device_id` is stamped on posts/replies/reactions for ownership and
--       rate limiting, and is hidden from public SELECT so nobody can harvest
--       another visitor's device_id to edit or delete their posts.
--     * Server-side length limits, spam blocklist checks, and per-device
--       rate limits block API-level spam and oversized payloads.
--     * Nobody can UPDATE or DELETE any table row directly — those actions
--       go through PIN- or device-id-verified server functions
--       (security definer RPCs).
--     * The app's family PIN is now checked INSIDE the database, not just
--       on the phone.
--
-- HOW TO USE
--   1. Paste this whole file into Supabase Dashboard > SQL Editor and Run.
--   2. Replace the family PIN from the app's built-in default by running:
--        update public.app_admin_secret
--        set pin_hash = crypt('YOUR_NEW_6_DIGIT_PIN', gen_salt('bf'));
--   3. Deploy the matching app update (this repository).
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
-- 2. New columns & length constraints: device ownership + server spam limits
-- ============================================================================
-- New posts/replies are stamped with the device id that created them.
-- Old rows keep '' (no owner) — their authors lose remote edit/delete,
-- which is accepted (it also blocks impersonation edits).
alter table public.pakikiramay_messages
  add column if not exists device_id text not null default '';
alter table public.pakikiramay_replies
  add column if not exists device_id text not null default '';
alter table public.pakikiramay_replies
  add column if not exists reply_to_name text not null default '';
alter table public.pakikiramay_reactions
  add column if not exists device_id text not null default '';
alter table public.pakikiramay_reactions
  add column if not exists reactor_name text not null default 'Anonymous';

-- `approved` stops being set by the client. The database owns the default
-- and any stray NULLs are cleaned up.
update public.pakikiramay_messages set approved = true where approved is null;
alter table public.pakikiramay_messages
  alter column approved set not null,
  alter column approved set default true;

-- Early databases created `pakikiramay_reports.target_id` as `text` while
-- every other id column is `uuid`, which makes the aggregate/admin RPCs
-- fail with 42P13 ("return type mismatch in function declared to return
-- record"). All real values are UUIDs — the app refuses to upload temp
-- ids (msg-/reply-) — so normalizing the column is safe.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'pakikiramay_reports'
      and column_name = 'target_id'
      and data_type = 'text'
  ) then
    execute 'alter table public.pakikiramay_reports '
            'alter column target_id type uuid using target_id::uuid';
  end if;
end $$;

-- Database-level length constraints (`NOT VALID` so existing rows never
-- block the migration, while every new INSERT/UPDATE is enforced).
-- `length(device_id) <= 100` here allows admin edits on legacy rows with
-- `device_id = ''`; the INSERT policies below require a non-empty device_id.
alter table public.pakikiramay_messages
  drop constraint if exists pakikiramay_messages_length_check;
alter table public.pakikiramay_messages
  add constraint pakikiramay_messages_length_check check (
    length(btrim(name)) between 1 and 50
    and length(btrim(message)) between 1 and 1000
    and length(device_id) <= 100
  ) not valid;

alter table public.pakikiramay_replies
  drop constraint if exists pakikiramay_replies_length_check;
alter table public.pakikiramay_replies
  add constraint pakikiramay_replies_length_check check (
    length(btrim(author_name)) between 1 and 50
    and length(btrim(message)) between 1 and 1000
    and coalesce(length(btrim(reply_to_name)), 0) <= 50
    and length(device_id) <= 100
  ) not valid;

alter table public.pakikiramay_reactions
  drop constraint if exists pakikiramay_reactions_length_check;
alter table public.pakikiramay_reactions
  add constraint pakikiramay_reactions_length_check check (
    reaction_type = 'heart'
    and length(btrim(reactor_name)) between 1 and 50
    and length(device_id) <= 100
  ) not valid;

alter table public.pakikiramay_reports
  drop constraint if exists pakikiramay_reports_length_check;
alter table public.pakikiramay_reports
  add constraint pakikiramay_reports_length_check check (
    target_kind in ('post', 'reply')
    and length(btrim(reason)) between 1 and 50
    and coalesce(length(details), 0) <= 200
    and length(btrim(reporter_device_id)) between 1 and 100
    and length(btrim(reporter_name)) between 1 and 50
  ) not valid;

alter table public.candle_messages
  drop constraint if exists candle_messages_length_check;
alter table public.candle_messages
  add constraint candle_messages_length_check check (
    length(btrim(name)) between 1 and 50
    and length(btrim(message)) between 1 and 500
  ) not valid;

alter table public.visitors
  drop constraint if exists visitors_length_check;
alter table public.visitors
  add constraint visitors_length_check check (
    length(btrim(name)) between 1 and 50
    and length(btrim(address)) between 3 and 200
    and coalesce(length(btrim(lang)), 0) <= 10
  ) not valid;

-- Deduplication & rate-limit indexes (one report per target+device, one
-- reaction per target+type+device, and fast per-device cooldown lookups).
create unique index if not exists pakikiramay_reports_target_device_uidx
  on public.pakikiramay_reports (target_id, reporter_device_id)
  where reporter_device_id <> '';

create unique index if not exists pakikiramay_reactions_target_device_uidx
  on public.pakikiramay_reactions (target_id, reaction_type, device_id)
  where device_id <> '';

create index if not exists pakikiramay_messages_device_created_idx
  on public.pakikiramay_messages (device_id, created_at desc)
  where device_id <> '';

create index if not exists pakikiramay_replies_device_created_idx
  on public.pakikiramay_replies (device_id, created_at desc)
  where device_id <> '';

create index if not exists pakikiramay_reports_device_created_idx
  on public.pakikiramay_reports (reporter_device_id, created_at desc)
  where reporter_device_id <> '';

create index if not exists pakikiramay_reactions_device_created_idx
  on public.pakikiramay_reactions (device_id, created_at desc)
  where device_id <> '';

-- ============================================================================
-- 2b. Server-side spam blocklist + per-device rate-limit helpers
-- ============================================================================
-- Mirrors SpamGuard in the app so bypassing the UI still enforces the
-- same word/link blocklist, length caps, and per-device cooldowns.
-- Defined as SECURITY DEFINER because `device_id` is hidden from public
-- SELECT (and `pakikiramay_reports`, `candle_messages`, `visitors` have
-- no public SELECT at all).
create or replace function public.pakikiramay_is_blocked_text(p_text text)
returns boolean
language sql immutable security definer
set search_path = public, extensions
as $$
  select coalesce(p_text, '') ~* '(http://|https://|www\.|\.com|gcash|click here|free load)'
      or coalesce(p_text, '') ~* '\m(putangina|putang|tangina|tarantado|gago|ulol|bobo|tanga|leche|pakshet|peste|hayop|fuck|shit|bitch|asshole|bastard|casino|crypto|investment|promo|claim)\M';
$$;

-- 1 post per 60s per device_id + 1..50 char name + 1..1000 char message.
create or replace function public.pakikiramay_can_insert_message(
  p_device_id text,
  p_name text,
  p_message text
)
returns boolean
language sql stable security definer
set search_path = public, extensions
as $$
  select p_device_id is not null
     and length(btrim(p_device_id)) between 1 and 100
     and p_name is not null
     and length(btrim(p_name)) between 1 and 50
     and p_message is not null
     and length(btrim(p_message)) between 1 and 1000
     and not public.pakikiramay_is_blocked_text(p_name)
     and not public.pakikiramay_is_blocked_text(p_message)
     and not exists (
       select 1 from public.pakikiramay_messages m
       where m.device_id = p_device_id
         and m.created_at > now() - interval '60 seconds'
     );
$$;

-- 1 reply per 20s per device_id + 1..50 char author + 1..1000 char message.
create or replace function public.pakikiramay_can_insert_reply(
  p_device_id text,
  p_author_name text,
  p_message text,
  p_reply_to_name text
)
returns boolean
language sql stable security definer
set search_path = public, extensions
as $$
  select p_device_id is not null
     and length(btrim(p_device_id)) between 1 and 100
     and p_author_name is not null
     and length(btrim(p_author_name)) between 1 and 50
     and p_message is not null
     and length(btrim(p_message)) between 1 and 1000
     and coalesce(length(btrim(p_reply_to_name)), 0) <= 50
     and not public.pakikiramay_is_blocked_text(p_author_name)
     and not public.pakikiramay_is_blocked_text(p_message)
     and not exists (
       select 1 from public.pakikiramay_replies r
       where r.device_id = p_device_id
         and r.created_at > now() - interval '20 seconds'
     );
$$;

-- Max 5 reports per 60s per reporter_device_id + length caps.
-- Duplicate (target_id, reporter_device_id) is caught by the unique index
-- above so the client still receives SQLSTATE 23505 ("already reported").
create or replace function public.pakikiramay_can_insert_report(
  p_target_id uuid,
  p_target_kind text,
  p_reason text,
  p_details text,
  p_device_id text,
  p_reporter_name text
)
returns boolean
language sql stable security definer
set search_path = public, extensions
as $$
  select p_target_id is not null
     and p_target_kind in ('post', 'reply')
     and p_reason is not null
     and length(btrim(p_reason)) between 1 and 50
     and coalesce(length(p_details), 0) <= 200
     and p_device_id is not null
     and length(btrim(p_device_id)) between 1 and 100
     and p_reporter_name is not null
     and length(btrim(p_reporter_name)) between 1 and 50
     and (
       select count(*) from public.pakikiramay_reports r
       where r.reporter_device_id = p_device_id
         and r.created_at > now() - interval '60 seconds'
     ) < 5;
$$;

-- Max 30 likes per 60s per device_id + length caps.
create or replace function public.pakikiramay_can_insert_reaction(
  p_target_id uuid,
  p_reaction_type text,
  p_device_id text,
  p_reactor_name text
)
returns boolean
language sql stable security definer
set search_path = public, extensions
as $$
  select p_target_id is not null
     and p_reaction_type = 'heart'
     and p_device_id is not null
     and length(btrim(p_device_id)) between 1 and 100
     and p_reactor_name is not null
     and length(btrim(p_reactor_name)) between 1 and 50
     and (
       select count(*) from public.pakikiramay_reactions r
       where r.device_id = p_device_id
         and r.created_at > now() - interval '60 seconds'
     ) < 30;
$$;

-- 1 candle message per 60s per visitor name + 1..500 char message.
create or replace function public.pakikiramay_can_insert_candle(
  p_name text,
  p_message text
)
returns boolean
language sql stable security definer
set search_path = public, extensions
as $$
  select p_name is not null
     and length(btrim(p_name)) between 1 and 50
     and p_message is not null
     and length(btrim(p_message)) between 1 and 500
     and not public.pakikiramay_is_blocked_text(p_name)
     and not public.pakikiramay_is_blocked_text(p_message)
     and not exists (
       select 1 from public.candle_messages c
       where lower(btrim(c.name)) = lower(btrim(p_name))
         and c.created_at > now() - interval '60 seconds'
     );
$$;

-- 1 visitor gate entry per 60s per name + 3..200 char address.
create or replace function public.pakikiramay_can_insert_visitor(
  p_name text,
  p_address text,
  p_lang text
)
returns boolean
language sql stable security definer
set search_path = public, extensions
as $$
  select p_name is not null
     and length(btrim(p_name)) between 1 and 50
     and p_address is not null
     and length(btrim(p_address)) between 3 and 200
     and coalesce(length(btrim(p_lang)), 0) <= 10
     and not public.pakikiramay_is_blocked_text(p_name)
     and not exists (
       select 1 from public.visitors v
       where lower(btrim(v.name)) = lower(btrim(p_name))
         and v.created_at > now() - interval '60 seconds'
     );
$$;

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
-- `device_id` is deliberately omitted from SELECT grants so nobody with
-- the public anon key can read another visitor's device_id and impersonate
-- them in pakikiramay_edit_message / pakikiramay_delete_message.
-- INSERT is restricted to (name, message, device_id) so clients cannot
-- spoof `id`, `created_at`, or `approved`.
alter table public.pakikiramay_messages enable row level security;
revoke all on public.pakikiramay_messages from anon, authenticated;
grant select (id, name, message, approved, created_at)
  on public.pakikiramay_messages to anon;
grant insert (name, message, device_id)
  on public.pakikiramay_messages to anon;

create policy pakikiramay_messages_select
  on public.pakikiramay_messages for select to anon
  using (approved is true);

create policy pakikiramay_messages_insert
  on public.pakikiramay_messages for insert to anon
  with check (
    public.pakikiramay_can_insert_message(device_id, name, message)
  );

-- UPDATE / DELETE: deliberately NO policy = nobody (not even the family)
-- may do it directly. Family moderation uses the admin RPCs below.

-- ----------------------------------------------------------------- replies
-- `device_id` is hidden from public SELECT just like on messages.
alter table public.pakikiramay_replies enable row level security;
revoke all on public.pakikiramay_replies from anon, authenticated;
grant select (id, post_id, author_name, message, reply_to_name, created_at)
  on public.pakikiramay_replies to anon;
grant insert (post_id, author_name, message, reply_to_name, device_id)
  on public.pakikiramay_replies to anon;

create policy pakikiramay_replies_select
  on public.pakikiramay_replies for select to anon
  using (true);

create policy pakikiramay_replies_insert
  on public.pakikiramay_replies for insert to anon
  with check (
    public.pakikiramay_can_insert_reply(
      device_id,
      author_name,
      message,
      reply_to_name
    )
  );

-- --------------------------------------------------------------- reactions
-- Readable (public likes + names) and insertable, with `device_id` hidden
-- from public SELECT so a visitor's device_id cannot be harvested from
-- their likes either. Unlike goes through pakikiramay_unlike().
alter table public.pakikiramay_reactions enable row level security;
revoke all on public.pakikiramay_reactions from anon, authenticated;
grant select (id, target_id, reaction_type, reactor_name, created_at)
  on public.pakikiramay_reactions to anon;
grant insert (target_id, reaction_type, device_id, reactor_name)
  on public.pakikiramay_reactions to anon;

create policy pakikiramay_reactions_select
  on public.pakikiramay_reactions for select to anon
  using (true);

create policy pakikiramay_reactions_insert
  on public.pakikiramay_reactions for insert to anon
  with check (
    public.pakikiramay_can_insert_reaction(
      target_id,
      reaction_type,
      device_id,
      reactor_name
    )
  );

-- ------------------------------------------------------------------ reports
-- Insert-only. Counts are read through pakikiramay_report_counts() so the
-- raw report text/details and reporter_device_id stay private.
alter table public.pakikiramay_reports enable row level security;
revoke all on public.pakikiramay_reports from anon, authenticated;
grant insert (
  target_id,
  target_kind,
  reason,
  details,
  reporter_device_id,
  reporter_name
) on public.pakikiramay_reports to anon;

create policy pakikiramay_reports_insert
  on public.pakikiramay_reports for insert to anon
  with check (
    public.pakikiramay_can_insert_report(
      target_id,
      target_kind,
      reason,
      details,
      reporter_device_id,
      reporter_name
    )
  );

-- ---------------------------------------------------------- candle_messages
-- PRIVATE congratulations-by-candle: insert only. Family reads/edits via
-- the candle admin RPCs.
alter table public.candle_messages enable row level security;
revoke all on public.candle_messages from anon, authenticated;
grant insert (name, message) on public.candle_messages to anon;

create policy candle_messages_insert
  on public.candle_messages for insert to anon
  with check (
    public.pakikiramay_can_insert_candle(name, message)
  );

-- ---------------------------------------------------------------- visitors
-- The gate log: insert only, no public SELECT (addresses stay private).
-- The public candle page gets its count + names-only list through the
-- narrow RPCs below.
alter table public.visitors enable row level security;
revoke all on public.visitors from anon, authenticated;
grant insert (name, address, lang) on public.visitors to anon;

create policy visitors_insert
  on public.visitors for insert to anon
  with check (
    public.pakikiramay_can_insert_visitor(name, address, lang)
  );

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

-- Like a post/reply is a plain INSERT — checked by pakikiramay_reactions_insert.

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
     or length(btrim(p_message)) > 1000
     or public.pakikiramay_is_blocked_text(p_message) then
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
     or length(btrim(p_message)) > 1000
     or public.pakikiramay_is_blocked_text(p_message) then
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
  if p_id is null or p_device_id is null or length(btrim(p_device_id)) = 0 then
    return false;
  end if;
  delete from public.pakikiramay_replies
  where post_id = p_id
    and exists (
      select 1 from public.pakikiramay_messages m
      where m.id = p_id
        and m.device_id = p_device_id
        and m.device_id <> ''
    );
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
     or length(btrim(p_name)) > 50
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
-- 8. Enable Realtime publication on public forum tables (idempotent)
-- ============================================================================
do $$
declare
  t text;
  rt_tables constant text[] := array[
    'pakikiramay_messages',
    'pakikiramay_replies',
    'pakikiramay_reactions'
  ];
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array rt_tables loop
      if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = t
      ) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end $$;

-- ============================================================================
-- Done. Reminder: change the family PIN with
--   update public.app_admin_secret set pin_hash = crypt('888888', gen_salt('bf'));
-- ============================================================================
