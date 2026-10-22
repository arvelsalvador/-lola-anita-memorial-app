-- ============================================================================
-- Schema snapshot (READ-ONLY — contains no names, addresses or messages)
--
-- WHY: the table definitions currently live only in the Supabase dashboard.
-- If the project is ever deleted or lost, this snapshot is what lets us
-- rebuild the identical database.
--
-- HOW TO USE
--   1. Supabase Dashboard -> SQL Editor -> New query.
--   2. Paste this whole file and click Run.
--   3. Download the result (the "Download CSV" button) or copy the single
--      JSON cell.
--   4. Save it in the repo as:  supabase/schema_snapshot.json
--
-- Run it again whenever the tables, columns, policies or functions change.
-- Safe to run as often as you like: it only reads catalog metadata.
-- ============================================================================

select jsonb_pretty(
  jsonb_build_object(
    'generated_at', now(),
    'postgres_version', version(),
    'extensions', (
      select jsonb_agg(jsonb_build_object(
        'name', e.extname,
        'schema', n.nspname
      ) order by e.extname)
      from pg_extension e
      join pg_namespace n on n.oid = e.extnamespace
    ),
    'tables', (
      select jsonb_object_agg(c.relname, jsonb_build_object(
        'columns', (
          select jsonb_agg(jsonb_build_object(
            'name', a.attname,
            'type', format_type(a.atttypid, a.atttypmod),
            'not_null', a.attnotnull,
            'default', pg_get_expr(d.adbin, d.adrelid),
            'identity', a.attidentity,
            'generated', a.attgenerated
          ) order by a.attnum)
          from pg_attribute a
          left join pg_attrdef d
            on d.adrelid = a.attrelid and d.adnum = a.attnum
          where a.attrelid = c.oid
            and a.attnum > 0
            and not a.attisdropped
        ),
        'primary_key', (
          select pg_get_constraintdef(con.oid)
          from pg_constraint con
          where con.conrelid = c.oid and con.contype = 'p'
        ),
        'constraints', (
          select jsonb_agg(jsonb_build_object(
            'name', con.conname,
            'definition', pg_get_constraintdef(con.oid)
          ) order by con.conname)
          from pg_constraint con
          where con.conrelid = c.oid and con.contype <> 'p'
        ),
        'indexes', (
          select jsonb_agg(pg_get_indexdef(i.indexrelid) order by i.indexrelid)
          from pg_index i
          where i.indrelid = c.oid
            and not exists (
              select 1 from pg_constraint cc
              where cc.conindid = i.indexrelid
            )
        ),
        'rls_enabled', c.relrowsecurity,
        'policies', (
          select jsonb_agg(jsonb_build_object(
            'name', p.policyname,
            'command', p.cmd,
            'permissive', p.permissive,
            'roles', p.roles,
            'using', p.qual,
            'with_check', p.with_check
          ) order by p.policyname)
          from pg_policies p
          where p.schemaname = 'public' and p.tablename = c.relname
        )
      ))
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'r'
    ),
    'functions', (
      select jsonb_agg(jsonb_build_object(
        'name', p.proname,
        'definition', pg_get_functiondef(p.oid)
      ) order by p.proname)
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.prokind = 'f'
    ),
    'triggers', (
      select jsonb_agg(jsonb_build_object(
        'name', t.tgname,
        'definition', pg_get_triggerdef(t.oid)
      ) order by t.tgname)
      from pg_trigger t
      join pg_class c on c.oid = t.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and not t.tgisinternal
    ),
    'sequences', (
      select jsonb_agg(jsonb_build_object(
        'name', s.sequencename,
        'definition', format('create sequence %I.%I;', s.schemaname, s.sequencename)
      ) order by s.sequencename)
      from pg_sequences s
      where s.schemaname = 'public'
    ),
    'grants', (
      select jsonb_agg(jsonb_build_object(
        'table', g.table_name,
        'grantee', g.grantee,
        'privilege', g.privilege_type
      ) order by g.table_name, g.grantee, g.privilege_type)
      from information_schema.role_table_grants g
      where g.table_schema = 'public'
    )
  )
) as schema_snapshot;
