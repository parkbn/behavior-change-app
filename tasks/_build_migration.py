"""Regenerate tasks/migrate_legacy_external_ids.sql from tasks/legacy_users.json.
Not committed — run locally to rebuild the SQL when the dump changes."""
import json, pathlib

ROOT = pathlib.Path(__file__).resolve().parent
data = json.loads((ROOT / 'legacy_users.json').read_text(encoding='utf-8'))

compact = []
for r in data:
    if not (r.get('externalId') and r.get('email')):
        continue
    compact.append({
        'externalId':  r['externalId'],
        'email':       r['email'],
        'firstName':   r.get('firstName') or '',
        'lastName':    r.get('lastName') or '',
        'timezone':    r.get('timezone'),
        'accountId':   r.get('accountId'),
        'lastLogin':   r.get('lastLogin'),
        'loginCount':  r.get('loginCount'),
    })

lines = [json.dumps(r, ensure_ascii=False) for r in compact]
json_block = "[\n  " + ",\n  ".join(lines) + "\n]"

template = r"""-- Migrate legacy HEALTHFLEXX Medical users into public.person
-- Project: behavior_change_app (run in Supabase SQL editor)
-- Source : HEALTHFLEXX Medical public.users ({count} rows)
-- Join   : lower(email)
--
-- Single-column strategy (Option A):
--   public.person.external_user_id is the universal join key.
--     * Legacy users: external_user_id = 'auth0|...' (from dump)
--     * New users:    external_user_id = person.id::text (trigger)
--   Downstream tables (steps, sleep, etc.) always join on
--   person.external_user_id regardless of origin.
--
-- Run each STEP one at a time. Read every SELECT result before
-- moving on. Transactions around destructive steps let you
-- ROLLBACK if a count looks wrong.

-- ============================================================
-- STEP 1 — Add the new columns to public.person
-- ============================================================
ALTER TABLE public.person
  ADD COLUMN IF NOT EXISTS timezone    text,
  ADD COLUMN IF NOT EXISTS account_id  text,
  ADD COLUMN IF NOT EXISTS last_login  timestamptz,
  ADD COLUMN IF NOT EXISTS login_count integer,
  ADD COLUMN IF NOT EXISTS picture_url text;

-- Confirm they landed
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'person'
  AND column_name IN ('timezone','account_id','last_login','login_count','picture_url')
ORDER BY column_name;

-- ============================================================
-- STEP 2 — Delete orphan person row(s) with no external_user_id
-- ============================================================
-- Preview first
SELECT id, email, first_name, last_name, created_at
FROM public.person
WHERE external_user_id IS NULL;

-- Delete inside a transaction
BEGIN;

DELETE FROM public.person
WHERE external_user_id IS NULL;

-- Verify — should match the count from the preview
SELECT count(*) AS remaining_null_external_user_id
FROM public.person
WHERE external_user_id IS NULL;

-- COMMIT;
-- ROLLBACK;

-- ============================================================
-- STEP 3 — Create/refresh public.legacy_user_map
-- ============================================================
-- Persistent map so the BEFORE INSERT trigger in Step 6 can
-- auto-link any legacy user who signs up in the new app later.
-- Re-run this block whenever the source dump refreshes.

CREATE TABLE IF NOT EXISTS public.legacy_user_map (
  email        text PRIMARY KEY,
  external_id  text NOT NULL,
  first_name   text,
  last_name    text,
  timezone     text,
  account_id   text,
  last_login   timestamptz,
  login_count  integer,
  loaded_at    timestamptz NOT NULL DEFAULT now()
);

-- RLS on, no policies — only service_role and SECURITY DEFINER trigger can read
ALTER TABLE public.legacy_user_map ENABLE ROW LEVEL SECURITY;

INSERT INTO public.legacy_user_map
  (email, external_id, first_name, last_name, timezone, account_id, last_login, login_count)
SELECT
  lower(r->>'email')                      AS email,
  r->>'externalId'                        AS external_id,
  NULLIF(r->>'firstName','')              AS first_name,
  NULLIF(r->>'lastName','')               AS last_name,
  NULLIF(r->>'timezone','')               AS timezone,
  NULLIF(r->>'accountId','')              AS account_id,
  NULLIF(r->>'lastLogin','')::timestamptz AS last_login,
  NULLIF(r->>'loginCount','')::integer    AS login_count
FROM jsonb_array_elements(
$legacy${json_block}$legacy$::jsonb
) AS r
WHERE r->>'externalId' IS NOT NULL
ON CONFLICT (email) DO UPDATE
  SET external_id = EXCLUDED.external_id,
      first_name  = EXCLUDED.first_name,
      last_name   = EXCLUDED.last_name,
      timezone    = EXCLUDED.timezone,
      account_id  = EXCLUDED.account_id,
      last_login  = EXCLUDED.last_login,
      login_count = EXCLUDED.login_count,
      loaded_at   = now();

SELECT count(*) AS staged_rows FROM public.legacy_user_map;

-- ============================================================
-- STEP 4 — Dry run: preview matches and misses
-- ============================================================

-- 4a. Legacy users that already have a person row (will be updated)
SELECT m.email, m.external_id, p.id AS person_id, p.external_user_id
FROM public.legacy_user_map m
JOIN public.person p ON lower(p.email) = m.email
ORDER BY m.email;

-- 4b. Legacy users with no person row yet (auto-linked by trigger on future signup)
SELECT m.email, m.external_id, m.first_name, m.last_name
FROM public.legacy_user_map m
LEFT JOIN public.person p ON lower(p.email) = m.email
WHERE p.id IS NULL
ORDER BY m.email;

-- 4c. Duplicate emails in person (should return zero rows)
SELECT lower(email) AS email, count(*)
FROM public.person
GROUP BY lower(email)
HAVING count(*) > 1;

-- ============================================================
-- STEP 5 — Backfill existing person rows from legacy_user_map
-- ============================================================
BEGIN;

UPDATE public.person p
SET external_user_id = m.external_id,
    timezone         = COALESCE(p.timezone,    m.timezone),
    account_id       = COALESCE(p.account_id,  m.account_id),
    last_login       = COALESCE(p.last_login,  m.last_login),
    login_count      = COALESCE(p.login_count, m.login_count),
    first_name       = COALESCE(p.first_name,  m.first_name),
    last_name        = COALESCE(p.last_name,   m.last_name)
FROM public.legacy_user_map m
WHERE lower(p.email) = m.email;

-- Verify — should match the row count from Step 4a
SELECT count(*) AS rows_now_linked
FROM public.person
WHERE external_user_id LIKE 'auth0|%';

-- COMMIT;
-- ROLLBACK;

-- ============================================================
-- STEP 6 — BEFORE INSERT trigger: auto-link + default
-- ============================================================
-- Rules:
--   * If external_user_id is NULL, look it up in legacy_user_map by email.
--     If found, copy external_id + timezone + account_id + login stats.
--   * If still NULL after that, set external_user_id := NEW.id::text.
-- Covers every insert path (handle_new_user, admin imports, manual).

CREATE OR REPLACE FUNCTION public.set_external_user_id_default()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
DECLARE
  m public.legacy_user_map%ROWTYPE;
BEGIN
  IF NEW.external_user_id IS NULL AND NEW.email IS NOT NULL THEN
    SELECT * INTO m
    FROM public.legacy_user_map
    WHERE email = lower(NEW.email);

    IF FOUND THEN
      NEW.external_user_id := m.external_id;
      NEW.timezone         := COALESCE(NEW.timezone,    m.timezone);
      NEW.account_id       := COALESCE(NEW.account_id,  m.account_id);
      NEW.last_login       := COALESCE(NEW.last_login,  m.last_login);
      NEW.login_count      := COALESCE(NEW.login_count, m.login_count);
      NEW.first_name       := COALESCE(NEW.first_name,  m.first_name);
      NEW.last_name        := COALESCE(NEW.last_name,   m.last_name);
    END IF;
  END IF;

  IF NEW.external_user_id IS NULL THEN
    NEW.external_user_id := NEW.id::text;
  END IF;

  RETURN NEW;
END;
$func$;

DROP TRIGGER IF EXISTS person_set_external_user_id ON public.person;
CREATE TRIGGER person_set_external_user_id
BEFORE INSERT ON public.person
FOR EACH ROW
EXECUTE FUNCTION public.set_external_user_id_default();

-- Safety net: any remaining person rows still NULL get id::text
UPDATE public.person
SET external_user_id = id::text
WHERE external_user_id IS NULL;

-- ============================================================
-- SMOKE TEST — verify pilot users
-- ============================================================
SELECT id, email, external_user_id, timezone, account_id, last_login, login_count
FROM public.person
WHERE external_user_id IN (
  'auth0|64e6236f07a0c7e17eb00bfd',  -- Ben
  'auth0|63dd8971c6848b5e2fe17ab3'   -- JR Gayman
);
"""

out = template.format(count=len(compact), json_block=json_block)
(ROOT / 'migrate_legacy_external_ids.sql').write_text(out, encoding='utf-8')
print(f'wrote {len(out)} chars, {len(compact)} records embedded')
