-- Migrate legacy externalId -> persons.external_id + persons.resolved_id
-- Project: behavior_change_app (run in Supabase SQL editor)
-- Source : HEALTHFLEXX Medical project, public.users (<300 rows)
-- Join   : lower(email)

-- ============================================================
-- STEP 1 — Load the legacy dump into a staging table
-- ============================================================
-- Paste the FULL JSON array from the Medical project in the
-- jsonb literal below (between $json$ ... $json$). The sample
-- here holds the 10 records you shared; replace with the full
-- ~300-row export before running.

DROP TABLE IF EXISTS tmp_legacy_users;
CREATE TEMP TABLE tmp_legacy_users AS
SELECT
  (r->>'email')       AS email,
  (r->>'externalId')  AS external_id,
  (r->>'firstName')   AS first_name,
  (r->>'lastName')    AS last_name
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
) AS r;

-- Sanity check
SELECT count(*) AS staged_rows FROM tmp_legacy_users;

-- ============================================================
-- STEP 2 — Dry run: preview matches and misses
-- ============================================================
-- Shows which legacy rows will land, and which won't.

-- Will be updated
SELECT t.email, t.external_id, p.id AS person_id
FROM tmp_legacy_users t
JOIN public.persons p ON lower(p.email) = lower(t.email)
ORDER BY t.email;

-- Will NOT be updated (no matching person)
SELECT t.email, t.external_id, t.first_name, t.last_name
FROM tmp_legacy_users t
LEFT JOIN public.persons p ON lower(p.email) = lower(t.email)
WHERE p.id IS NULL
ORDER BY t.email;

-- Duplicate emails in persons (would cause multiple updates per legacy row)
SELECT lower(email) AS email, count(*)
FROM public.persons
GROUP BY lower(email)
HAVING count(*) > 1;

-- ============================================================
-- STEP 3 — Backfill (wrap in transaction so you can ROLLBACK)
-- ============================================================
BEGIN;

UPDATE public.persons p
SET external_id = t.external_id,
    resolved_id = t.external_id
FROM tmp_legacy_users t
WHERE lower(p.email) = lower(t.email)
  AND t.external_id IS NOT NULL;

-- Verify row count looks right, then COMMIT (or ROLLBACK to undo)
SELECT count(*) AS rows_now_with_external_id
FROM public.persons
WHERE external_id LIKE 'auth0|%';

-- COMMIT;
-- ROLLBACK;

-- ============================================================
-- STEP 4 — Default resolved_id := id for all future persons
-- ============================================================
-- Separate BEFORE INSERT trigger so it applies to every insert
-- path (handle_new_user, admin imports, manual inserts, etc.),
-- not just the auth.users trigger.

CREATE OR REPLACE FUNCTION public.set_resolved_id_default()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.resolved_id IS NULL THEN
    NEW.resolved_id := NEW.id::text;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS persons_set_resolved_id ON public.persons;
CREATE TRIGGER persons_set_resolved_id
BEFORE INSERT ON public.persons
FOR EACH ROW
EXECUTE FUNCTION public.set_resolved_id_default();

-- Optional: also backfill resolved_id for any NEW-style persons
-- already in the table that somehow missed it (post-migration safety).
UPDATE public.persons
SET resolved_id = id::text
WHERE resolved_id IS NULL;
