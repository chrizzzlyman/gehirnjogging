-- Rechenrunde: Datenbank für Supabase
--
-- Einspielen: Supabase-Dashboard → SQL Editor → New query → alles einfügen → Run.
-- Das Skript kann gefahrlos mehrfach ausgeführt werden.
--
-- Wer darf was?
--   Lehrkraft (angemeldet): alles lesen, anlegen, ändern, löschen.
--   Kinder (nicht angemeldet): Namen und Päckchen lesen, den eigenen Versuch speichern
--                              und den eigenen Verlauf abrufen. Sonst nichts.

-- ---------------------------------------------------------------- Tabellen

create table if not exists public.teachers (
  user_id uuid primary key references auth.users (id) on delete cascade
);

create table if not exists public.kids (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 14),
  color text not null default '#2f5bd8' check (color ~ '^#[0-9a-fA-F]{6}$'),
  created_at timestamptz not null default now()
);

create table if not exists public.packs (
  id text primary key check (id ~ '^[a-z0-9]{3,40}$'),
  title text not null check (char_length(title) between 1 and 40),
  mode text not null check (mode in ('add', 'sub', 'mul', 'div', 'mix')),
  range_max integer not null check (range_max in (10, 20, 100, 1000, 10000, 100000, 1000000)),
  rounded boolean not null default true,
  limit_min integer not null default 0 check (limit_min between 0 and 180),
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  tasks jsonb not null check (jsonb_typeof(tasks) = 'array' and jsonb_array_length(tasks) between 1 and 100),
  -- Einstellungen der genauen Aufgaben-Auswahl (Stellen und Ziffern). Leer = Auswahl nach Zahlenraum.
  spec jsonb check (spec is null or (jsonb_typeof(spec) = 'object' and octet_length(spec::text) < 4000))
);

-- Für Projekte, die mit einer älteren Version dieses Skripts eingerichtet wurden:
alter table public.packs add column if not exists spec jsonb
  check (spec is null or (jsonb_typeof(spec) = 'object' and octet_length(spec::text) < 4000));

create table if not exists public.sessions (
  id uuid primary key,
  kid_id uuid not null references public.kids (id) on delete cascade,
  pack_id text not null references public.packs (id) on delete cascade,
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  total integer not null check (total between 1 and 100),
  done boolean not null default false,
  timed_out boolean not null default false,
  elapsed_ms integer not null default 0 check (elapsed_ms >= 0),
  limit_min integer not null default 0 check (limit_min between 0 and 180),
  tasks jsonb not null default '[]'::jsonb
    check (jsonb_typeof(tasks) = 'array' and jsonb_array_length(tasks) <= 100 and octet_length(tasks::text) < 40000)
);

create index if not exists sessions_started_idx on public.sessions (started_at desc);
create index if not exists sessions_kid_pack_idx on public.sessions (kid_id, pack_id);
create index if not exists sessions_pack_idx on public.sessions (pack_id);

-- ---------------------------------------------------------------- Lehrkraft erkennen
-- Das erste bestätigte Konto im Projekt wird zur Lehrkraft. Alle anderen Konten
-- haben keine Lehrerrechte. Erstelle das Konto direkt nach diesem Skript und
-- schalte danach unter Authentication → Sign In / Providers die Registrierung neuer Nutzer ab.

create or replace function public.is_teacher()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.teachers t where t.user_id = auth.uid());
$$;

create or replace function public.claim_first_teacher()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.email_confirmed_at is not null and not exists (select 1 from public.teachers) then
    insert into public.teachers (user_id) values (new.id) on conflict do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists rechenrunde_claim_teacher on auth.users;
create trigger rechenrunde_claim_teacher
  after insert or update of email_confirmed_at on auth.users
  for each row execute function public.claim_first_teacher();

-- ---------------------------------------------------------------- Funktionen für die Kinder

-- Speichert (oder aktualisiert) einen Versuch. Das Kind kennt nur seine eigene Versuchs-ID.
create or replace function public.save_session(
  p_id uuid, p_kid uuid, p_pack text, p_started timestamptz, p_total integer,
  p_done boolean, p_timed_out boolean, p_elapsed integer, p_limit integer, p_tasks jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_tasks is null or jsonb_typeof(p_tasks) <> 'array' or jsonb_array_length(p_tasks) > 100
     or octet_length(p_tasks::text) >= 40000 then
    raise exception 'ungueltige Aufgaben' using errcode = '22023';
  end if;
  if not exists (select 1 from public.kids where id = p_kid) then
    raise exception 'unbekanntes Kind' using errcode = '22023';
  end if;
  if not exists (select 1 from public.packs where id = p_pack) then
    raise exception 'unbekanntes Paeckchen' using errcode = '22023';
  end if;

  insert into public.sessions
    (id, kid_id, pack_id, started_at, updated_at, total, done, timed_out, elapsed_ms, limit_min, tasks)
  values
    (p_id, p_kid, p_pack, least(coalesce(p_started, now()), now()), now(),
     greatest(1, least(100, coalesce(p_total, 1))), coalesce(p_done, false), coalesce(p_timed_out, false),
     greatest(0, coalesce(p_elapsed, 0)), greatest(0, least(180, coalesce(p_limit, 0))), p_tasks)
  on conflict (id) do update
    set updated_at = now(),
        done = excluded.done,
        timed_out = excluded.timed_out,
        elapsed_ms = excluded.elapsed_ms,
        tasks = excluded.tasks
    where public.sessions.kid_id = excluded.kid_id
      and public.sessions.pack_id = excluded.pack_id;
end;
$$;

-- Liefert die beendeten Versuche eines Kindes in einem Päckchen (für Verlauf und Bestwert).
create or replace function public.kid_history(p_kid uuid, p_pack text)
returns table (id uuid, started_at timestamptz, total integer, done boolean, timed_out boolean,
               elapsed_ms integer, limit_min integer, tasks jsonb)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select s.id, s.started_at, s.total, s.done, s.timed_out, s.elapsed_ms, s.limit_min, s.tasks
  from public.sessions s
  where s.kid_id = p_kid and s.pack_id = p_pack and s.done
  order by s.started_at
  limit 200;
$$;

-- Nur diese beiden Funktionen dürfen die Kinder (ohne Anmeldung) aufrufen.
-- Die Sicherheitswarnungen von Supabase dazu sind gewollt.
revoke all on function public.save_session(uuid, uuid, text, timestamptz, integer, boolean, boolean, integer, integer, jsonb) from public, anon, authenticated;
revoke all on function public.kid_history(uuid, text) from public, anon, authenticated;
revoke all on function public.is_teacher() from public, anon, authenticated;
revoke all on function public.claim_first_teacher() from public, anon, authenticated;
grant execute on function public.save_session(uuid, uuid, text, timestamptz, integer, boolean, boolean, integer, integer, jsonb) to anon, authenticated;
grant execute on function public.kid_history(uuid, text) to anon, authenticated;
grant execute on function public.is_teacher() to authenticated;

-- ---------------------------------------------------------------- Zugriffsregeln

alter table public.teachers enable row level security;
alter table public.kids enable row level security;
alter table public.packs enable row level security;
alter table public.sessions enable row level security;

revoke all on public.teachers from anon, authenticated;
revoke all on public.kids from anon;
revoke all on public.packs from anon;
revoke all on public.sessions from anon;
grant select on public.kids, public.packs to anon;
grant select, insert, update, delete on public.kids, public.packs, public.sessions to authenticated;

drop policy if exists kids_read on public.kids;
create policy kids_read on public.kids for select to anon, authenticated using (true);
drop policy if exists kids_teacher on public.kids;
create policy kids_teacher on public.kids for all to authenticated
  using (public.is_teacher()) with check (public.is_teacher());

drop policy if exists packs_read on public.packs;
create policy packs_read on public.packs for select to anon, authenticated using (true);
drop policy if exists packs_teacher on public.packs;
create policy packs_teacher on public.packs for all to authenticated
  using (public.is_teacher()) with check (public.is_teacher());

drop policy if exists sessions_teacher on public.sessions;
create policy sessions_teacher on public.sessions for all to authenticated
  using (public.is_teacher()) with check (public.is_teacher());

-- ---------------------------------------------------------------- Live-Aktualisierung

alter table public.sessions replica identity full;
alter table public.kids replica identity full;
alter table public.packs replica identity full;

do $$
declare t text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['sessions', 'kids', 'packs'] loop
      if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
      ) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end;
$$;
