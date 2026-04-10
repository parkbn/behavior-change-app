-- Migrate legacy externalId -> persons.external_id + persons.resolved_id
-- Project: behavior_change_app (run in Supabase SQL editor)
-- Source : HEALTHFLEXX Medical project, public.users (<300 rows)
-- Join   : lower(email)
--
-- Strategy:
--   1. Persist the legacy email->externalId map as a real table
--      (public.legacy_user_map) so the insert trigger can consult
--      it when legacy users sign up in the new app LATER.
--   2. Backfill persons rows that already exist (legacy user who
--      has already signed up in the new app).
--   3. Install a BEFORE INSERT trigger that auto-links any future
--      persons row whose email matches the legacy map, and
--      defaults resolved_id to id::text when no legacy match.

-- ============================================================
-- STEP 1 — Create/refresh the persistent legacy_user_map
-- ============================================================
-- Paste the FULL JSON array from the Medical project in the
-- jsonb literal below (between $json$ ... $json$). The sample
-- here holds the 10 records you shared; replace with the full
-- ~300-row export before running.

CREATE TABLE IF NOT EXISTS public.legacy_user_map (
  email       text PRIMARY KEY,
  external_id text NOT NULL,
  first_name  text,
  last_name   text,
  loaded_at   timestamptz NOT NULL DEFAULT now()
);

-- UPSERT the dump. Safe to re-run whenever the source changes.
INSERT INTO public.legacy_user_map (email, external_id, first_name, last_name)
SELECT
  lower(r->>'email')  AS email,
  r->>'externalId'    AS external_id,
  r->>'firstName'     AS first_name,
  r->>'lastName'      AS last_name
FROM jsonb_array_elements(
$json$
[
  {"id":"1167b533-5cd4-42f2-88bd-85bda5fb5f0d","externalId":"auth0|6862bb137f9769c44dc77c64","email":"swilson@hancockhealth.org","firstName":"Stephanie","lastName":"Wilson"},
  {"id":"3ffda7cf-7f1a-461c-a708-5d916937cfc0","externalId":"auth0|67db725f9ee191b13df46f6e","email":"cloud.alex96@yahoo.com","firstName":"Alex","lastName":"Cloud"},
  {"id":"81416821-e582-42b4-91b4-b97f2fb4245f","externalId":"auth0|678ed2a98da87f46e6bc34f3","email":"ayelend@shepherdcommunity.org","firstName":"Ayelen","lastName":"Dominguez"},
  {"id":"8601cac7-c152-4871-9a09-772d04694100","externalId":"auth0|686323dde6ba3a35212cf101","email":"jwynn@hancockhealth.org","firstName":"Jonie","lastName":"Wynn"},
  {"id":"280e0964-30af-435a-bd5b-bb355aecb2f0","externalId":"auth0|678e859a2f514ace32cca650","email":"jennieg@shepherdcommunity.org","firstName":"Jennie","lastName":"Gibson"},
  {"id":"ae265c5d-5592-4bc8-879b-61d924d4b1fd","externalId":"auth0|63dd8971c6848b5e2fe17ab3","email":"john@healthflexxinc.com","firstName":"JR","lastName":"Gayman"},
  {"id":"bc675e86-0436-41e9-98fc-13340b3d206e","externalId":"auth0|67b0cbb660448f7726229021","email":"kandrad@shepherdcommunity.org","firstName":"Kandra","lastName":"Dees"},
  {"id":"60d51459-017a-4d16-902e-bf0fe3cc6537","externalId":"auth0|67c48d353b26fc4bbb392178","email":"epturnbaugh@yahoo.com","firstName":"Evangeline","lastName":"Turnbaugh"},
  {"id":"e7d40d0e-8f34-4fc4-a402-473d3ecedcc8","externalId":"auth0|66068716d25f1e3b83a34a94","email":"aliapple@gmail.com","firstName":"apple","lastName":"apple"},
  {"id":"9560ac35-fbec-4981-983d-9e207a521bf8","externalId":"auth0|6862c255ab2a08d0302a3aaf","email":"emilystoffel2@gmail.com","firstName":"Emily","lastName":"Stoffel"}
]
$json$::jsonb
) AS r
WHERE r->>'externalId' IS NOT NULL
ON CONFLICT (email) DO UPDATE
  SET external_id = EXCLUDED.external_id,
      first_name  = EXCLUDED.first_name,
      last_name   = EXCLUDED.last_name,
      loaded_at   = now();

-- Lock down — only the trigger and admins should read this.
-- (RLS on; no policies = no anon/auth access. Service role bypasses RLS.)
ALTER TABLE public.legacy_user_map ENABLE ROW LEVEL SECURITY;

SELECT count(*) AS staged_rows FROM public.legacy_user_map;

-- ============================================================
-- STEP 2 — Dry run: preview matches and misses
-- ============================================================

-- Persons that will be updated by step 3
SELECT m.email, m.external_id, p.id AS person_id
FROM public.legacy_user_map m
JOIN public.persons p ON lower(p.email) = m.email
ORDER BY m.email;

-- Legacy users with no matching persons row yet
-- (they will be auto-linked by the trigger when they sign up)
SELECT m.email, m.external_id, m.first_name, m.last_name
FROM public.legacy_user_map m
LEFT JOIN public.persons p ON lower(p.email) = m.email
WHERE p.id IS NULL
ORDER BY m.email;

-- Duplicate emails in persons (would cause multi-update per legacy row)
SELECT lower(email) AS email, count(*)
FROM public.persons
GROUP BY lower(email)
HAVING count(*) > 1;

-- ============================================================
-- STEP 3 — Backfill persons rows that already exist
-- ============================================================
BEGIN;

UPDATE public.persons p
SET external_id = m.external_id,
    resolved_id = m.external_id
FROM public.legacy_user_map m
WHERE lower(p.email) = m.email;

SELECT count(*) AS rows_now_with_external_id
FROM public.persons
WHERE external_id LIKE 'auth0|%';

-- COMMIT;
-- ROLLBACK;

-- ============================================================
-- STEP 4 — Smart BEFORE INSERT trigger for future persons
-- ============================================================
-- Logic:
--   * If external_id is not set, try to find it in legacy_user_map
--     by lower(email).
--   * resolved_id := external_id if we matched legacy; else id::text.
--
-- This covers every insert path (handle_new_user from auth.users,
-- admin imports, manual inserts), not just the auth trigger.

CREATE OR REPLACE FUNCTION public.set_resolved_id_default()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER  -- lets the trigger read legacy_user_map past RLS
SET search_path = public
AS $$
BEGIN
  IF NEW.external_id IS NULL AND NEW.email IS NOT NULL THEN
    SELECT external_id INTO NEW.external_id
    FROM public.legacy_user_map
    WHERE email = lower(NEW.email);
  END IF;

  IF NEW.resolved_id IS NULL THEN
    NEW.resolved_id := COALESCE(NEW.external_id, NEW.id::text);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS persons_set_resolved_id ON public.persons;
CREATE TRIGGER persons_set_resolved_id
BEFORE INSERT ON public.persons
FOR EACH ROW
EXECUTE FUNCTION public.set_resolved_id_default();

-- Safety net: patch any new-style persons that somehow still lack
-- resolved_id (shouldn't happen after the trigger is in place).
UPDATE public.persons
SET resolved_id = id::text
WHERE resolved_id IS NULL;
