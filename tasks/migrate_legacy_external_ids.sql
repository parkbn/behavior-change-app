-- Migrate legacy HEALTHFLEXX Medical users into public.person
-- Project: behavior_change_app (run in Supabase SQL editor)
-- Source : HEALTHFLEXX Medical public.users (270 rows)
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
$legacy$[
  {"externalId": "auth0|6862bb137f9769c44dc77c64", "email": "swilson@hancockhealth.org", "firstName": "Stephanie", "lastName": "Wilson", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-08-03 22:25:15.836", "loginCount": 2},
  {"externalId": "auth0|67db725f9ee191b13df46f6e", "email": "cloud.alex96@yahoo.com", "firstName": "Alex", "lastName": "Cloud", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-04-20 15:14:48.762", "loginCount": 3},
  {"externalId": "auth0|678ed2a98da87f46e6bc34f3", "email": "ayelend@shepherdcommunity.org", "firstName": "Ayelen", "lastName": "Dominguez", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-03-09 23:35:54.281", "loginCount": 14},
  {"externalId": "auth0|686323dde6ba3a35212cf101", "email": "jwynn@hancockhealth.org", "firstName": "Jonie", "lastName": "Wynn", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-06-30 23:55:10.379", "loginCount": 1},
  {"externalId": "auth0|678e859a2f514ace32cca650", "email": "jennieg@shepherdcommunity.org", "firstName": "Jennie", "lastName": "Gibson", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-08-07 15:02:15.917", "loginCount": 4},
  {"externalId": "auth0|63dd8971c6848b5e2fe17ab3", "email": "john@healthflexxinc.com", "firstName": "JR", "lastName": "Gayman", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2026-04-09 17:02:31.793", "loginCount": 550},
  {"externalId": "auth0|67b0cbb660448f7726229021", "email": "kandrad@shepherdcommunity.org", "firstName": "Kandra", "lastName": "Dees", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-03-03 21:31:06.216", "loginCount": 2},
  {"externalId": "auth0|67c48d353b26fc4bbb392178", "email": "epturnbaugh@yahoo.com", "firstName": "Evangeline", "lastName": "Turnbaugh", "timezone": "America/Indianapolis", "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-10-20 22:23:18.806", "loginCount": 7},
  {"externalId": "auth0|66068716d25f1e3b83a34a94", "email": "aliapple@gmail.com", "firstName": "apple", "lastName": "apple", "timezone": null, "accountId": "6606871651d8ab3677de8373", "lastLogin": "2024-03-29 11:19:23.358", "loginCount": 4},
  {"externalId": "auth0|6862c255ab2a08d0302a3aaf", "email": "emilystoffel2@gmail.com", "firstName": "Emily", "lastName": "Stoffel", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-06-30 16:59:04.275", "loginCount": 1},
  {"externalId": "auth0|685191d817055a3327a7084f", "email": "slarge60@gmail.com", "firstName": "Stephen", "lastName": "Large", "timezone": null, "accountId": "adc98fb9-e0af-4a5b-81b5-d8b4fe54ffd1", "lastLogin": "2025-06-17 16:03:37.54", "loginCount": 1},
  {"externalId": "auth0|69411b31cf986b3650a10a9c", "email": "mbilalzamankpk575@gmail.com", "firstName": "Bilal", "lastName": "", "timezone": null, "accountId": "12edf26b-9c7d-4833-8345-1500bb5b4740", "lastLogin": "2025-12-16 08:41:23.182", "loginCount": 1},
  {"externalId": "auth0|6851a112a89c0bbe4540ed22", "email": "stanleylarge51@gmail.com", "firstName": "Stanley", "lastName": "Large", "timezone": null, "accountId": "7c6cb767-b3d9-4b27-9b96-bdbb811d4c39", "lastLogin": "2026-02-18 02:43:14.713", "loginCount": 3},
  {"externalId": "auth0|677ad6038b3a9e743d65fca5", "email": "chris@healthflexxinc.com", "firstName": "Chris", "lastName": "Watkins", "timezone": null, "accountId": "11fb4089-4ba9-4ed4-8740-16aa297bf6bf", "lastLogin": "2025-10-11 19:54:13.283", "loginCount": 10},
  {"externalId": "auth0|64e6236f07a0c7e17eb00bfd", "email": "ben.park.md@gmail.com", "firstName": "Ben", "lastName": "Park", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2026-04-08 11:21:45.561", "loginCount": 46},
  {"externalId": "auth0|686424989fa081a5fd18edcf", "email": "gharter@hancockhealth.org", "firstName": "Garren", "lastName": "Harter", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-07-01 18:10:32.631", "loginCount": 1},
  {"externalId": "auth0|690c3ad7429935b35263ff1e", "email": "matif.uetp@gmail.com", "firstName": "Atif", "lastName": "Khan", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2025-11-06 06:06:17.669", "loginCount": 1},
  {"externalId": "auth0|679cc8f81ed6e01bc94c300c", "email": "bethb@shepherdcommunity.org", "firstName": "Beth", "lastName": "Brown", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-01-19 19:08:08.566", "loginCount": 10},
  {"externalId": "auth0|67a58bb2588ebba4e5b5c692", "email": "allens@shepherdcommunity.org", "firstName": "Allen", "lastName": "Southerland", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-07-17 12:11:42.304", "loginCount": 7},
  {"externalId": "auth0|679c61372e1a1ffa3af93b53", "email": "jennifera@shepherdcommunity.org", "firstName": "Jennifer", "lastName": "Agramonte", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-09-01 04:31:39.261", "loginCount": 5},
  {"externalId": "auth0|68547014e2f4aa3d49c268b5", "email": "jhungate@hancockhealth.org", "firstName": "Joel", "lastName": "Hungate", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2026-03-17 12:09:47.876", "loginCount": 10},
  {"externalId": "auth0|6876515a2f8aefbbafa3ee6e", "email": "davidm@shepherdcommunity.org", "firstName": "David", "lastName": "Martinez", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-07-15 13:02:18.822", "loginCount": 1},
  {"externalId": "auth0|6862c000e6ba3a35212c952f", "email": "jaiciw@yaboo.com", "firstName": "Jaici", "lastName": "Wright", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-06-30 16:49:04.805", "loginCount": 1},
  {"externalId": "auth0|679c2133d6293d4d1bd1e349", "email": "reneep@shepherdcommunity.org", "firstName": "Renee", "lastName": "Pitzulo", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-09-15 13:13:13.354", "loginCount": 4},
  {"externalId": "auth0|6837a52f56324d8b914a41a1", "email": "mollyc@shepherdcommunity.org", "firstName": "Molly", "lastName": "Molly", "timezone": null, "accountId": "49350d5b-3432-4a81-94c7-746de7a7658d", "lastLogin": "2025-05-29 00:07:12.133", "loginCount": 1},
  {"externalId": "auth0|687a1fbcfaca3389251fd92c", "email": "hashimjann9@gmail.com", "firstName": "Hashim", "lastName": "Jan", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2026-04-09 08:37:46.325", "loginCount": 51},
  {"externalId": "auth0|6837966ce1f33633fd8f978b", "email": "camdenc@shepherdcommunity.org", "firstName": "Camden", "lastName": "Camden", "timezone": null, "accountId": "620e39ac-03f8-4217-96de-6022e87c295e", "lastLogin": "2025-08-20 00:15:19.929", "loginCount": 3},
  {"externalId": "auth0|679c017bd6293d4d1bd1cae4", "email": "cloud.kristen66@gmail.com", "firstName": "Kristie", "lastName": "Kristie", "timezone": null, "accountId": "e984f6c9-6476-48ae-be73-02677344495d", "lastLogin": "2026-03-10 11:05:36.164", "loginCount": 13},
  {"externalId": "auth0|693bbb08f77a56c8601f0966", "email": "alikhan121@gmail.com", "firstName": "Ali", "lastName": "", "timezone": null, "accountId": "866d34c2-8f6d-498c-97da-64347a35b9bf", "lastLogin": "2025-12-21 09:19:53.733", "loginCount": 2},
  {"externalId": "auth0|6986153748d01e33548e0d25", "email": "khite538@gmail.com", "firstName": "Kevin", "lastName": "Hite", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-04-08 09:52:11.644", "loginCount": 3},
  {"externalId": "auth0|69b9ae7e2bf404eb625484a3", "email": "pamelaelaine5@gmail.com", "firstName": "Pam", "lastName": "Smith", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-18 14:41:16.759", "loginCount": 2},
  {"externalId": "auth0|685ad174e8505af951166d36", "email": "john@techinnovation.com", "firstName": "John", "lastName": "Gayman", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-10-28 09:23:09.151", "loginCount": 2},
  {"externalId": "auth0|678e9ac3867fe46be24946bb", "email": "westlakedennis@gmail.com", "firstName": "Dennis", "lastName": "Westlake", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-20 18:49:40.502", "loginCount": 1},
  {"externalId": "auth0|65c1d99483cbc9037e94d803", "email": "vanwyk.andre.c@gmail.com", "firstName": "Andre", "lastName": "van", "timezone": null, "accountId": "65c1d9938c05d1dacfde7254", "lastLogin": "2024-02-06 09:24:40.655", "loginCount": 2},
  {"externalId": "auth0|6862c14dab2a08d0302a3991", "email": "cory.hisle@outlook.com", "firstName": "Cory", "lastName": "Hisle", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-06-30 16:54:38.188", "loginCount": 1},
  {"externalId": "auth0|683655c3883946bef81720ee", "email": "wheelwinner22@aol.com", "firstName": "Jana", "lastName": "Kindred", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-07-03 03:57:13.283", "loginCount": 2},
  {"externalId": "auth0|69163e9a9a70fef6fcced9a2", "email": "marlohubbard5@gmail.com", "firstName": "Marlo", "lastName": "Hubbard", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-17 11:07:11.555", "loginCount": 3},
  {"externalId": "auth0|67a106cc3cbf7b3e902de66c", "email": "mark@shepherdcommunity.org", "firstName": "Mark", "lastName": "Hiehle", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-02-03 18:11:25", "loginCount": 1},
  {"externalId": "auth0|679bde5bc34f1ed2f0e83a34", "email": "danielmu@shepherdcommunity.org", "firstName": "Daniel", "lastName": "Mutowa", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-30 20:17:31.569", "loginCount": 1},
  {"externalId": "auth0|6945da646eeaf1c88825499d", "email": "ssteinhu@purdue.edu", "firstName": "Steve", "lastName": "Steinhubl", "timezone": null, "accountId": "b302231a-3f3f-4181-a418-ca46c2c12108", "lastLogin": "2025-12-19 23:06:13.419", "loginCount": 1},
  {"externalId": "auth0|69c1c171e356b82e90b27705", "email": "Michelle.kitsis@gmail.com", "firstName": "Michelle", "lastName": "Kitsis", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-23 22:40:51.171", "loginCount": 1},
  {"externalId": "auth0|67a01abc0a665648185fe89e", "email": "edsolares15@gmail.com", "firstName": "Edson", "lastName": "Solares", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-03-31 01:11:06.75", "loginCount": 14},
  {"externalId": "auth0|69861bcbfacc27867d4b756e", "email": "vleehughes75@aol.com", "firstName": "Lee", "lastName": "Hughes", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-04-08 15:33:20.907", "loginCount": 4},
  {"externalId": "auth0|67a0c8c32167e5581b4e35d5", "email": "rachels@shepherdcommunity.org", "firstName": "Rachel", "lastName": "Southerland", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-03-11 01:23:28.33", "loginCount": 17},
  {"externalId": "auth0|677a5b648b3a9e743d65c333", "email": "john1@healthflexxinc.com", "firstName": "tester", "lastName": "person2", "timezone": null, "accountId": null, "lastLogin": "2025-01-05 10:21:47.745", "loginCount": 2},
  {"externalId": "auth0|669fde0775160b6da51131ae", "email": "jmmaly154@gmail.com", "firstName": "ali", "lastName": "ali", "timezone": null, "accountId": "669fde072fbc27432ba66122", "lastLogin": "2024-07-23 16:52:02.552", "loginCount": 1},
  {"externalId": "auth0|666068651c8ecded64125ee3", "email": "ksharma@omnimd.com", "firstName": "Kamal", "lastName": "Sharma", "timezone": "Asia/Calcutta", "accountId": "666065de371f27ce24a37f00", "lastLogin": "2025-07-16 07:26:41.294", "loginCount": 589},
  {"externalId": "auth0|679bff3250e7086615a1ecaa", "email": "c2kurtz@yahoo.com", "firstName": "Cory", "lastName": "Kurtz", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-05-17 02:15:58.59", "loginCount": 4},
  {"externalId": "auth0|682e2c8b1cc1cdb602121318", "email": "phillipburrer@gmail.com", "firstName": "Phillip", "lastName": "Phillip", "timezone": null, "accountId": "569614e0-e490-4e4c-8614-a3218bf0d686", "lastLogin": "2025-05-21 19:42:04.389", "loginCount": 1},
  {"externalId": "auth0|69c1c58e1eea7b92ccc97695", "email": "Landonshane2010@gmail.com", "firstName": "Kelsey", "lastName": "Flowers", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-23 22:58:23.928", "loginCount": 1},
  {"externalId": "auth0|679bdbddbceb28fe5bb37924", "email": "amyw@shepherdcommunity.org", "firstName": "Amy", "lastName": "Wallace", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-04-24 04:27:25.059", "loginCount": 5},
  {"externalId": "auth0|67a4ef2588067971c2ccae25", "email": "muhammad49ibrar@gmail.com", "firstName": "Muhammad", "lastName": "Ibrar", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2025-02-06 17:19:37.851", "loginCount": 1},
  {"externalId": "auth0|679c34cf50e7086615a21394", "email": "paigep@shepherdcommunity.org", "firstName": "Paige", "lastName": "Parks", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-31 02:26:23.649", "loginCount": 1},
  {"externalId": "auth0|691cce33bdf6ef601149fefb", "email": "afetti05@hotmail.com", "firstName": "Adam", "lastName": "Fettinger", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-11-18 19:51:17.072", "loginCount": 1},
  {"externalId": "auth0|695c0553419f44215e9a3b3f", "email": "bkphare@yahoo.com", "firstName": "Belinda", "lastName": "phares", "timezone": null, "accountId": "91dd1d8c-418a-40bc-8b63-d4e59cf0dfd7", "lastLogin": "2026-01-14 17:49:59.334", "loginCount": 3},
  {"externalId": "auth0|6988bf5ffd6b2469c49d191a", "email": "steelersdj@gmail.com", "firstName": "Dena", "lastName": "Jacquay", "timezone": null, "accountId": "a5ca4dd2-2c3c-4b77-987f-136ca621cd2a", "lastLogin": "2026-02-08 16:52:49.035", "loginCount": 1},
  {"externalId": "auth0|647035f2ae9317825e48e456", "email": "demo@healthflexxinc.com", "firstName": "Demo", "lastName": "User", "timezone": null, "accountId": "647035aeabe32f4a51cc910f", "lastLogin": "2026-03-17 01:32:27.995", "loginCount": 281},
  {"externalId": "auth0|6863146ca4646de8bbdc1387", "email": "jhigbee@hancockhealth.org", "firstName": "Joy", "lastName": "Higbee", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-10-04 12:58:23.894", "loginCount": 2},
  {"externalId": "auth0|691cd0c1c6984f88d8b80c94", "email": "lferrara@hancockhealth.org", "firstName": "Lissa", "lastName": "Ferrara", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-20 00:50:56.819", "loginCount": 9},
  {"externalId": "auth0|67b244613ebf5ff2b94d2e69", "email": "karalee_white24@gmail.com", "firstName": "Karalee", "lastName": "White", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-02-16 20:02:41.815", "loginCount": 1},
  {"externalId": "auth0|679beb2c50e7086615a1dba1", "email": "alhood81689@gmil.com", "firstName": "Amber", "lastName": "Hood", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-30 21:12:13.562", "loginCount": 1},
  {"externalId": "auth0|67aca66c965b1f3a25dfa28d", "email": "adiagrindean@icloud.com", "firstName": "Adia", "lastName": "Adia", "timezone": null, "accountId": "d3e7083d-9a92-49c3-b6a5-bf8870b157e2", "lastLogin": "2025-02-12 13:47:25.272", "loginCount": 1},
  {"externalId": "auth0|5e3276832485400edbb3f5ec", "email": "dan@danambrose.com", "firstName": "Dr", "lastName": "Ambrose", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2025-10-23 23:21:16.244", "loginCount": 12},
  {"externalId": "auth0|67931caad6a7b7a60028757d", "email": "alikhan21@gmail.com", "firstName": "Ali", "lastName": "Ali", "timezone": null, "accountId": "052984e0-fb8d-4306-9b73-aff584a82600", "lastLogin": "2025-01-24 04:52:59.441", "loginCount": 1},
  {"externalId": "auth0|678aee86cb9af3b04efa6ef9", "email": "indysmith69@gmail.com", "firstName": "Billy", "lastName": "Smith", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2025-01-17 23:57:58.964", "loginCount": 1},
  {"externalId": "auth0|670d31ba4b3dd541b70ed4b0", "email": "alexjoshi@yopmail.com", "firstName": "Dr.", "lastName": "Alex", "timezone": null, "accountId": "670d30a359e3348521d39929", "lastLogin": "2024-10-14 15:01:01.866", "loginCount": 1},
  {"externalId": "auth0|69c40c8d4bb33120e64106da", "email": "phi4alpha@aol.om", "firstName": "Chris", "lastName": "Burns", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-25 16:25:51.236", "loginCount": 1},
  {"externalId": "auth0|6965116a88f37208240b8746", "email": "sarwatamin179@gmail.com", "firstName": "Sarwat", "lastName": "", "timezone": null, "accountId": "2a7bcb2d-cb34-4106-b471-9a904dd1b91b", "lastLogin": "2026-01-12 15:21:16.077", "loginCount": 1},
  {"externalId": "auth0|698ba74ede623acaadd27982", "email": "jimjacobsen714@icloud.com", "firstName": "Jim", "lastName": "", "timezone": null, "accountId": "8814ee55-d5f9-4586-81d9-4893b2e8a145", "lastLogin": "2026-02-10 21:46:56.023", "loginCount": 1},
  {"externalId": "auth0|6862c2587cf6eeaa1d5b3c6e", "email": "codywbaker@gmail.com", "firstName": "Cody", "lastName": "Baker", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2026-03-15 19:28:19.435", "loginCount": 5},
  {"externalId": "auth0|679e60c84b5fcf52553b89ce", "email": "andrewg@shepherdcommunity.org", "firstName": "Andrew", "lastName": "Green", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-03-24 11:31:06.669", "loginCount": 14},
  {"externalId": "auth0|691deb8aa8116f167a3630b9", "email": "miacarter4712@gmail.com", "firstName": "Mia", "lastName": "Carter", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-26 00:28:22.78", "loginCount": 5},
  {"externalId": "auth0|678e98612f514ace32ccb5d2", "email": "zarkydrew@gmail.com", "firstName": "Drew", "lastName": "Talleyrand", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-20 18:39:30.389", "loginCount": 1},
  {"externalId": "auth0|658616c38d750bdc3985e67d", "email": "mikejohn@test1234321.com", "firstName": "Mike", "lastName": "John", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2023-12-22 23:58:59.682", "loginCount": 3},
  {"externalId": "auth0|674edbedf762a2e2742bf682", "email": "sandraframe@yopmail.com", "firstName": "Sandra", "lastName": "Frame", "timezone": null, "accountId": "395d1e08-6d48-4bb0-8e68-df786bb70619", "lastLogin": "2024-12-03 10:43:41.234", "loginCount": 2},
  {"externalId": "auth0|67a021abd71602e637dbb8e1", "email": "tifanyo@shepherdcommunity.org", "firstName": "Tifany", "lastName": "Otis", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-11-24 04:04:31.795", "loginCount": 10},
  {"externalId": "auth0|69c87e04724f851d20d527d1", "email": "sidrajamil@9988gmail.com", "firstName": "Sidra", "lastName": "Jamil", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2026-03-29 01:19:02.89", "loginCount": 1},
  {"externalId": "auth0|69692fa0b55d062368d94eaa", "email": "pethessa@rose-hulman.edu", "firstName": "Sandor", "lastName": "", "timezone": null, "accountId": "f2fed8fb-e8c0-4f94-9cc8-bebb37aa8da2", "lastLogin": "2026-01-15 18:19:14.037", "loginCount": 1},
  {"externalId": "auth0|698cd5e162ef74bbab9d25b8", "email": "engr.hamzatakkar@gmail.com", "firstName": "Hazrat", "lastName": "", "timezone": null, "accountId": "cf02e35f-e1da-476a-aece-813adb5755f7", "lastLogin": "2026-02-11 19:17:55.382", "loginCount": 1},
  {"externalId": "auth0|67b27c443ebf5ff2b94d4f3e", "email": "rbuckley@tecklinx.com", "firstName": "Robert", "lastName": "Buckley", "timezone": null, "accountId": "e2f05f8f-e300-4046-89ae-bd960fdf6d4e", "lastLogin": "2025-02-17 00:38:10.564", "loginCount": 2},
  {"externalId": "auth0|679e552138a701c24c2c94ba", "email": "rachelr@shepherdcommunity.org", "firstName": "Rachel", "lastName": "Rhoad", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-02-01 17:08:50.555", "loginCount": 1},
  {"externalId": "auth0|67a70c51668f09e59055273d", "email": "alikhan123@gmail.com", "firstName": "ALI", "lastName": "ALI", "timezone": null, "accountId": "91930b02-2a39-4d94-8522-58b2d0802de6", "lastLogin": "2025-02-08 07:48:35.653", "loginCount": 1},
  {"externalId": "auth0|676d53e1fb101a49a5194ce5", "email": "support@techinnovation.com", "firstName": "Tester", "lastName": "Person", "timezone": null, "accountId": null, "lastLogin": "2024-12-26 13:02:26.282", "loginCount": 1},
  {"externalId": "auth0|67a10a040a6656481860866a", "email": "jbrunnemer26@gmail.com", "firstName": "Julia", "lastName": "Julia", "timezone": null, "accountId": "73011f92-f2fb-4511-8b32-f333524d5420", "lastLogin": "2025-02-03 18:25:09.559", "loginCount": 1},
  {"externalId": "auth0|69c88519476df28866d6ce99", "email": "kashifjan5651@gmail.com", "firstName": "Kashif", "lastName": "", "timezone": null, "accountId": "d4490deb-e268-422f-a3ba-24ae96dcf2dd", "lastLogin": "2026-03-29 01:49:16.086", "loginCount": 1},
  {"externalId": "auth0|68657e12b22e620ebb4c1ea4", "email": "shurst@hancockhealth.org", "firstName": "Sarah", "lastName": "Hurst", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2026-04-07 11:50:19.702", "loginCount": 11},
  {"externalId": "auth0|678e8af26f6eefac0b0daee4", "email": "dakota18373@gmail.com", "firstName": "Dakota", "lastName": "Boyle", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-20 17:42:11.741", "loginCount": 1},
  {"externalId": "auth0|691f1b8cb72dea59b16126e5", "email": "ericagentry@att.net", "firstName": "Erica", "lastName": "Gentry", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-01-24 20:06:51.785", "loginCount": 3},
  {"externalId": "auth0|698f9e036602233864a85d20", "email": "parker.deirdre@yahoo.com", "firstName": "Deirdre", "lastName": "", "timezone": null, "accountId": "d2f39c89-cc52-41c4-99a2-52a4347e11af", "lastLogin": "2026-02-13 21:56:21.203", "loginCount": 1},
  {"externalId": "auth0|6973889270091c86b691eda5", "email": "riddle21@purdue.edu", "firstName": "Andrea", "lastName": "Riddle", "timezone": null, "accountId": "b302231a-3f3f-4181-a418-ca46c2c12108", "lastLogin": "2026-02-23 17:08:09.337", "loginCount": 3},
  {"externalId": "auth0|678e9d437465b998692d6857", "email": "bethanyrmorfordphd@gmail.com", "firstName": "Bethany", "lastName": "Morford", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-03-02 00:15:28.378", "loginCount": 22},
  {"externalId": "auth0|65953d91ae9356a77307ff8a", "email": "sulaimanakhtar99888@gmail.com", "firstName": "Sulaiman", "lastName": "Akhtar", "timezone": null, "accountId": "65953d9190d055048e93d0fa", "lastLogin": "2025-04-11 14:20:17.33", "loginCount": 3},
  {"externalId": "auth0|687915c1ad05437b8120a205", "email": "john@flexxxcorporation.com", "firstName": "Lang", "lastName": "Lang", "timezone": null, "accountId": "0d87b81e-0c19-440e-9bcb-3571bc38da21", "lastLogin": "2025-07-17 15:24:50.458", "loginCount": 1},
  {"externalId": "auth0|652bf73f9befb209639c7cf0", "email": "bill@healthflexxinc.com", "firstName": "Bill", "lastName": "Smith", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2026-03-29 13:53:07.186", "loginCount": 59},
  {"externalId": "auth0|678e848798d8acb44b8d7093", "email": "kathyb@shepherdcommunity.org", "firstName": "Katherine", "lastName": "Bianco", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-20 17:14:48.009", "loginCount": 1},
  {"externalId": "auth0|69d002d1a9dba404eb55291d", "email": "joeonguitar@yahoo.com", "firstName": "Joseph", "lastName": "", "timezone": null, "accountId": "6d9f1c25-de99-4b81-a117-3fbe2690da4a", "lastLogin": "2026-04-03 18:11:30.872", "loginCount": 1},
  {"externalId": "auth0|698fc11c20bfe79a6b12cc0d", "email": "danielsegal07@gmail.com", "firstName": "Daniel", "lastName": "Segal", "timezone": null, "accountId": "a5ca4dd2-2c3c-4b77-987f-136ca621cd2a", "lastLogin": "2026-02-14 00:26:06.525", "loginCount": 1},
  {"externalId": "auth0|6973953eb490cf4e0ccbedeb", "email": "mnwatson@purdue.edu", "firstName": "Monique", "lastName": "Watson", "timezone": null, "accountId": "b302231a-3f3f-4181-a418-ca46c2c12108", "lastLogin": "2026-02-23 17:06:19.425", "loginCount": 3},
  {"externalId": "auth0|6901140a9f3e506035962ca3", "email": "hashimjan033@gmail.com", "firstName": "Hashim", "lastName": "Jan", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|691f788af15e7b53e72df0c5", "email": "hlthomas2115@gmail.com", "firstName": "Heather", "lastName": "Thomas", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-12 12:29:59.648", "loginCount": 5},
  {"externalId": "auth0|685aa882df5efbd368218676", "email": "hashimjan@gmail.com", "firstName": "Hashim", "lastName": "Hashim", "timezone": null, "accountId": "faa7ce1c-50ea-40c0-b3d8-ef7a46d58bde", "lastLogin": "2025-06-24 15:34:38.319", "loginCount": 4},
  {"externalId": "auth0|67f9251d947c2fddb22d3b94", "email": "latonia196@gmail.com", "firstName": "Latonia", "lastName": "Smith", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-07-09 13:48:14.385", "loginCount": 3},
  {"externalId": "auth0|679d3b3f93ecc6a49343fedb", "email": "koltonw@shepherdcommunity.org", "firstName": "Kolton", "lastName": "Williford", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-03-03 20:34:39.478", "loginCount": 2},
  {"externalId": "auth0|679bdd07b43abc00f74c3c64", "email": "kimg@shepherdcommunity.org", "firstName": "Kim", "lastName": "Grindean", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-30 20:18:26.04", "loginCount": 2},
  {"externalId": "auth0|678e9f553dba7fdcdc30b277", "email": "westlakecindy1279@gmail.com", "firstName": "Cindy", "lastName": "Westlake", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-20 19:09:10.233", "loginCount": 1},
  {"externalId": "auth0|6977caef0498a096ec37440e", "email": "amin43@purdue.edu", "firstName": "Sarwat", "lastName": "Amin", "timezone": null, "accountId": "b302231a-3f3f-4181-a418-ca46c2c12108", "lastLogin": "2026-01-26 20:13:36.674", "loginCount": 1},
  {"externalId": "auth0|6862babf7354027de6141943", "email": "lori.hurst34@gmail.com", "firstName": "Lori", "lastName": "Deemer", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-11-17 21:24:23.268", "loginCount": 5},
  {"externalId": "auth0|6920878c930e66f21a8c5172", "email": "tbuckley@hancockhealth.org", "firstName": "Taylor", "lastName": "Buckley", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-11-21 15:38:53.446", "loginCount": 1},
  {"externalId": "auth0|6993639d007e1b713bb3d76e", "email": "itxshahid881@gmail.com", "firstName": "Shahid", "lastName": "", "timezone": null, "accountId": "be353c59-c296-4ace-aeb3-60a7b7a32116", "lastLogin": "2026-02-16 18:36:15.458", "loginCount": 1},
  {"externalId": "auth0|69d0617160fa802f05a95d24", "email": "cgeibel@hancockhealth.org", "firstName": "Tina", "lastName": "Geibel", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2026-04-04 00:55:15.456", "loginCount": 1},
  {"externalId": "auth0|67a5778c09aedf3a9cbe9bcc", "email": "karalee_white24@yahoo.com", "firstName": "Karalee", "lastName": "White", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-05-13 00:04:31.023", "loginCount": 6},
  {"externalId": "auth0|67eb08fea2002d34627826f5", "email": "johan@yoyomotion.com", "firstName": "johan", "lastName": "johan", "timezone": null, "accountId": "04483dd7-4209-4605-8a7f-31619a4e4c92", "lastLogin": "2025-03-31 21:28:30.523", "loginCount": 1},
  {"externalId": "auth0|679ce706f4e0dcdf67f5df10", "email": "airionnj@gmail.com", "firstName": "Airionn", "lastName": "Johnson", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-03-28 14:31:32.588", "loginCount": 3},
  {"externalId": "auth0|679cc52a92f51ce539c7bac9", "email": "emmal@shepherdcommunity.org", "firstName": "Emma", "lastName": "Lindsay", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-31 12:42:19.452", "loginCount": 1},
  {"externalId": "auth0|678d970e2f514ace32cc1771", "email": "nigarzeynalova@gmail.com", "firstName": "Zeynalova", "lastName": "Zeynalova", "timezone": null, "accountId": "7acc7adc-7309-4985-bd2e-f3a6270a7cc3", "lastLogin": "2025-01-20 00:21:35.873", "loginCount": 1},
  {"externalId": "auth0|677c19d6b243c7ed0b92fe9f", "email": "bpark@healthflexxinc.com", "firstName": "Ben", "lastName": "Park", "timezone": null, "accountId": null, "lastLogin": "2025-12-13 13:40:04.97", "loginCount": 12},
  {"externalId": "auth0|69938804132d1306146a14c9", "email": "mgrady@ecommunity.com", "firstName": "M", "lastName": "", "timezone": null, "accountId": "7f2b3951-e5c8-419b-87a6-63f7cbd8947a", "lastLogin": "2026-02-16 21:11:34.537", "loginCount": 1},
  {"externalId": "auth0|692089c439a1f9c53ea67f93", "email": "jweidner@hancockhealth.org", "firstName": "Jenny", "lastName": "Weidner", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-11 05:33:23.602", "loginCount": 4},
  {"externalId": "auth0|67bb6c5ff79f9774ad574137", "email": "asadeee998@gmail.com", "firstName": "Asad", "lastName": "Asad", "timezone": null, "accountId": "f5235ce4-5cbc-4a17-8206-80f8982ec9d4", "lastLogin": "2025-02-23 18:43:44.771", "loginCount": 1},
  {"externalId": "auth0|679bdb30c34f1ed2f0e83745", "email": "claires@shepherdcommunity.org", "firstName": "Claire", "lastName": "Schuerman", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-02-20 19:47:42.57", "loginCount": 3},
  {"externalId": "auth0|679cea0a1ed6e01bc94c4a97", "email": "montse.parga.az@gmail.com", "firstName": "Azeneth", "lastName": "Gonzalez", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-31 15:19:38.96", "loginCount": 1},
  {"externalId": "auth0|679ce1e9c8db8f6e8abf1c6a", "email": "gabes@shepherdcommunity.org", "firstName": "Gabe", "lastName": "Short", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-31 14:44:58.139", "loginCount": 1},
  {"externalId": "auth0|677d7bd86f2bfb1add5752ee", "email": "test4@healthflexxinc.com", "firstName": "test", "lastName": "person4", "timezone": null, "accountId": null, "lastLogin": "2025-01-07 19:09:13.267", "loginCount": 1},
  {"externalId": "auth0|678d0513228755f0c53a34de", "email": "test6@healthflexxinc.com", "firstName": "Test", "lastName": "Person6", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2025-01-19 13:58:44.239", "loginCount": 1},
  {"externalId": "auth0|6995e78de5b03d2d369db887", "email": "rmreynolds9123@yahoo.com", "firstName": "Rachel", "lastName": "Downey", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-23 12:54:03.775", "loginCount": 4},
  {"externalId": "auth0|67a393432df06ab1db878435", "email": "mneel0@icloud.com", "firstName": "Mary", "lastName": "Neel", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-03-25 19:35:36.898", "loginCount": 8},
  {"externalId": "auth0|69208f9102e823560f58633e", "email": "Abraham.salazar3@gmail.com", "firstName": "Abe", "lastName": "Salazar", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-04-05 02:12:13.04", "loginCount": 10},
  {"externalId": "auth0|6862c3b77354027de6142212", "email": "mgraves086@gmail.com", "firstName": "Michelle", "lastName": "Graves", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-06-30 17:04:56.271", "loginCount": 1},
  {"externalId": "auth0|65df4194f761c4a0b0d9b7db", "email": "zubair1836@gmail.com", "firstName": "Zubair", "lastName": "Zubair", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2025-04-29 22:37:07.199", "loginCount": 103},
  {"externalId": "auth0|679c2c70bceb28fe5bb3b94e", "email": "kelseys@shepherdcommunity.org", "firstName": "Kelsey", "lastName": "Shaver", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-01-31 01:50:41.351", "loginCount": 1},
  {"externalId": "auth0|64dd665493376a40a98213e9", "email": "dan@danambrose.org", "firstName": "Dan", "lastName": "Ambrose", "timezone": null, "accountId": "64dd6656b36cde55c09deadf", "lastLogin": "2025-10-24 14:32:29.848", "loginCount": 89},
  {"externalId": "auth0|67ec4dbfad275302233bf04d", "email": "anastasiiatkachovas@gmail.com", "firstName": "Nastia", "lastName": "Tkachova", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-03-10 02:04:43.723", "loginCount": 3},
  {"externalId": "auth0|6920a806f83a947aac2631ab", "email": "vester505@gmail.com", "firstName": "Heather", "lastName": "Vester", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-02-03 13:55:28.672", "loginCount": 3},
  {"externalId": "auth0|66f6714e57dcf572ef7991bc", "email": "jpanchal@yopmail.com", "firstName": "Jigar", "lastName": "Panchal", "timezone": "America/Jamaica", "accountId": "666065de371f27ce24a37f00", "lastLogin": "2024-10-14 15:00:53.039", "loginCount": 28},
  {"externalId": "auth0|67b280f2f638be604875dbd0", "email": "cindylpappin@gmail.com", "firstName": "Cindy", "lastName": "Pappin", "timezone": null, "accountId": "e2f05f8f-e300-4046-89ae-bd960fdf6d4e", "lastLogin": "2025-02-17 00:21:07.35", "loginCount": 1},
  {"externalId": "auth0|679d8b81af054bdd43bc8358", "email": "jacinthesandra@yahoo.fr", "firstName": "Sandra", "lastName": "Talleyrand", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-02-01 02:48:34.37", "loginCount": 1},
  {"externalId": "auth0|6995f0f450a672ca389a0b38", "email": "jakers1972@yahoo.com", "firstName": "Jennifer", "lastName": "Robbins", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-21 12:40:27.52", "loginCount": 2},
  {"externalId": "auth0|65861bc0fada0de9e126131e", "email": "test1@test.com", "firstName": "Fred", "lastName": "Jones", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2023-12-22 23:29:04.428", "loginCount": 1},
  {"externalId": "auth0|667ad998b62992785b7fe51e", "email": "hallmark@yopmail.com", "firstName": "Dr", "lastName": "Hall", "timezone": null, "accountId": "666065de371f27ce24a37f00", "lastLogin": "2024-10-08 12:05:11.462", "loginCount": 5},
  {"externalId": "auth0|65fdd0181ab283bfb94ac4f6", "email": "test123456789@test12345678.com", "firstName": "John", "lastName": "friend2", "timezone": null, "accountId": "65fdd017410e4fa8a3ad82ff", "lastLogin": "2024-03-22 18:38:16.703", "loginCount": 1},
  {"externalId": "auth0|6703bb7af5ec2a66bcbfb516", "email": "rellymark@yopmail.com", "firstName": "Dr.", "lastName": "Relly", "timezone": null, "accountId": "66f526ecd6646e7cb7842e40", "lastLogin": "2024-10-08 12:12:50.325", "loginCount": 4},
  {"externalId": "auth0|65bd091e09afb150624cbdf1", "email": "andre@avw-p.com", "firstName": "Andre", "lastName": "van", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2024-02-14 07:44:05.358", "loginCount": 3},
  {"externalId": "auth0|6586365b34f1c95b45e344c5", "email": "jimkurt@test1234321.com", "firstName": "Jim", "lastName": "Kurt", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2023-12-23 01:22:46.238", "loginCount": 2},
  {"externalId": "auth0|670dff169eb3cd7d813192a3", "email": "johnford@yopmail.com", "firstName": "John", "lastName": "Ford", "timezone": null, "accountId": "670d30a359e3348521d39929", "lastLogin": "2024-10-15 05:36:44.371", "loginCount": 1},
  {"externalId": "auth0|657b6b58338a535bfa24e468", "email": "john@flexxcorporation.com", "firstName": "Ben", "lastName": "H", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2024-04-04 17:00:34.759", "loginCount": 8},
  {"externalId": "auth0|67f3da6db071ff9e69df60c5", "email": "johnmartin@yopmail.com", "firstName": "John", "lastName": "Martin", "timezone": null, "accountId": "66fd5ea4d92c9bb92ce3636c", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|678283b1f190b9bc399e87e8", "email": "tmacre@yahoo.com", "firstName": "Tom", "lastName": "Acre", "timezone": null, "accountId": "dba358c7-3b14-4081-b2a3-6b386825a10d", "lastLogin": "2025-01-11 14:46:25.53", "loginCount": 2},
  {"externalId": "auth0|648b80631a2bfb723ea66b6d", "email": "lot920@gmail.com", "firstName": "Susie", "lastName": "Susie", "timezone": null, "accountId": "648b80638e0cd14eb585ef67", "lastLogin": "2023-06-23 23:36:20.102", "loginCount": 8},
  {"externalId": "auth0|6877529144d55100dab049ea", "email": "kellystark@yopmail.com", "firstName": "Kelly", "lastName": "Stark", "timezone": null, "accountId": "a1803a2a-158f-4221-9432-557c0ba5cb47", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|67f3db7139893b62fda25637", "email": "johncook@yopmail.com", "firstName": "John", "lastName": "Cook", "timezone": null, "accountId": "a1803a2a-158f-4221-9432-557c0ba5cb47", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6567e32fbd1b7fa874190735", "email": "healthflexx1@gmail.com", "firstName": "Elizabeth", "lastName": "Gannon", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2024-08-15 13:20:07.061", "loginCount": 32},
  {"externalId": "auth0|674f0a1bf762a2e2742c1377", "email": "kimberleychance@yopmail.com", "firstName": "Kimberley", "lastName": "Chance", "timezone": null, "accountId": "2db94d1e-2639-49c8-8f7d-1b5874f41e0f", "lastLogin": "2024-12-03 13:42:38.231", "loginCount": 1},
  {"externalId": "auth0|64508f5f33202ea9bfadddc5", "email": "navjeet@vitaltelemetrics.com", "firstName": "Navjeet", "lastName": "Chabbewal", "timezone": null, "accountId": "64508e4dc9b4d0847fa58c0f", "lastLogin": "2023-07-22 22:12:31.501", "loginCount": 41},
  {"externalId": "auth0|658634112f870e2d03ac72fa", "email": "willjay@test1234321.com", "firstName": "Will", "lastName": "Jay", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2023-12-23 01:12:49.575", "loginCount": 1},
  {"externalId": "auth0|67049c7948f7a1b19d4734b5", "email": "omnimd@danambrose.com", "firstName": "Dan", "lastName": "Ambrose", "timezone": null, "accountId": "666065de371f27ce24a37f00", "lastLogin": "2024-12-02 16:16:04.451", "loginCount": 41},
  {"externalId": "auth0|674d6c63228a0923a493582f", "email": "vickiesmith@yopmail.com", "firstName": "Vickie", "lastName": "Smith", "timezone": "Africa/Cairo", "accountId": "395d1e08-6d48-4bb0-8e68-df786bb70619", "lastLogin": "2024-12-02 08:16:21.74", "loginCount": 1},
  {"externalId": "auth0|65fdcfec49ddc30bde012631", "email": "test123456789@test1234567.com", "firstName": "John", "lastName": "friend", "timezone": null, "accountId": "65fdcfec410e4fa8a3ad82fc", "lastLogin": "2024-03-22 18:37:32.879", "loginCount": 1},
  {"externalId": "auth0|66be01367228f4e8298adec5", "email": "russ.mcdonough@continuumlink.com", "firstName": "Russ", "lastName": "McDonough", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2024-08-15 13:37:09.079", "loginCount": 1},
  {"externalId": "auth0|63fec85679cb86b9e47e9b99", "email": "emather@gmail.com", "firstName": "Eric", "lastName": "Mather", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2024-11-12 21:46:38.796", "loginCount": 568},
  {"externalId": "auth0|67052235f5ec2a66bcc0c071", "email": "harryjames@yopmail.com", "firstName": "Dr.", "lastName": "Harry", "timezone": null, "accountId": "66f526ecd6646e7cb7842e40", "lastLogin": "2025-10-23 23:21:26.112", "loginCount": 5},
  {"externalId": "auth0|6920add04ac06e069970adb9", "email": "hammons1001@gmail.com", "firstName": "Laney", "lastName": "Hammons", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-11-21 18:22:09.917", "loginCount": 1},
  {"externalId": "auth0|69965acdf340a1e41185411c", "email": "rsinclair4861@hotmail.com", "firstName": "Rhonda", "lastName": "Sinclair", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-23 01:53:52.331", "loginCount": 2},
  {"externalId": "auth0|67ad9561e641b0a9b60c12c4", "email": "davisdavis@yopmail.com", "firstName": "Steven", "lastName": "Davis", "timezone": null, "accountId": "6a6a9be3-790e-443d-b5db-93402f6aa141", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|670e65e270cc400761b2517c", "email": "frankgoyette@yopmail.com", "firstName": "Frank", "lastName": "Goyette", "timezone": null, "accountId": "670e632bc1fbf879b999097d", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|67053d3148f7a1b19d479461", "email": "johndoe@yopmail.com", "firstName": "Doe", "lastName": "Doe  John", "timezone": null, "accountId": "66fdba93d900b6b11f23a1bf", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|66f52781fefa55d130d273cd", "email": "dellyrenolt@yopmail.com", "firstName": "Delly", "lastName": "Renolt", "timezone": null, "accountId": "66f526ecd6646e7cb7842e40", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6660af37eeb87cae44b69342", "email": "todd.pedersen@authenticx.com", "firstName": "Todd", "lastName": "Pedersen", "timezone": null, "accountId": "6660a673371f27ce24a37f62", "lastLogin": "2024-06-05 18:38:47.042", "loginCount": 3},
  {"externalId": "auth0|65c02e3604d52f5d708b30e6", "email": "ruth.large@whakarongorau.nz", "firstName": "Ruth", "lastName": "Large", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|699cffdbe95f37d5547a5f4c", "email": "davidsegal646@gmail.com", "firstName": "David", "lastName": "Segal", "timezone": null, "accountId": "a5ca4dd2-2c3c-4b77-987f-136ca621cd2a", "lastLogin": "2026-02-24 01:33:17.123", "loginCount": 1},
  {"externalId": "auth0|664767a620e66227901270cd", "email": "sales10@nanway.com.cn", "firstName": "Jeff", "lastName": "Meng", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2024-05-20 02:07:50.447", "loginCount": 1},
  {"externalId": "auth0|65aeb11940a8ae84c30f6f90", "email": "mike@biltsolutions.com", "firstName": "Mike", "lastName": "Miklozek", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2024-01-22 18:27:43.901", "loginCount": 2},
  {"externalId": "auth0|66fe62d0c01572273393c99e", "email": "juliscot@yopmail.com", "firstName": "Juli", "lastName": "Scot", "timezone": null, "accountId": "66f526ecd6646e7cb7842e40", "lastLogin": "2024-10-03 09:26:49.208", "loginCount": 1},
  {"externalId": "auth0|667adc6689fcdbcb1e2fa434", "email": "denmark@yopmail.com", "firstName": "Dr", "lastName": "Den", "timezone": null, "accountId": "666065de371f27ce24a37f00", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6660840acf13c844e6677127", "email": "markdavid7@yopmail.com", "firstName": "Mark", "lastName": "David", "timezone": null, "accountId": "66608409371f27ce24a37f58", "lastLogin": "2024-06-05 15:28:10.618", "loginCount": 1},
  {"externalId": "auth0|657c9fc48fff00fdee442386", "email": "kkonstanzer@promedinnovations.com", "firstName": "Ken", "lastName": "Konstanzer", "timezone": null, "accountId": "6575d96ed112ab559d3fc0f9", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|657b77953f3088fa201010d3", "email": "nm3@danambrose.com", "firstName": "Another", "lastName": "Test", "timezone": null, "accountId": "64dd6656b36cde55c09deadf", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|69215807d365adb1c101f518", "email": "hashimtest123@gmail.com", "firstName": "Hashim", "lastName": "", "timezone": null, "accountId": "26ce685d-d826-4ac2-853a-54a2ef769b57", "lastLogin": "2025-11-22 06:28:26.041", "loginCount": 1},
  {"externalId": "auth0|657c9d7f49b0f00e167bebf4", "email": "jrgayman3@gmail.com", "firstName": "JR", "lastName": "Gayman", "timezone": null, "accountId": "b302231a-3f3f-4181-a418-ca46c2c12108", "lastLogin": "2025-12-22 15:57:15.631", "loginCount": 4},
  {"externalId": "auth0|6921ef8f279cfeae172129dd", "email": "sariyakhan@gmail.com", "firstName": "Sariya", "lastName": "", "timezone": null, "accountId": "5bd06b00-8129-45bf-9b8d-7b09c96ee371", "lastLogin": "2025-11-23 04:51:19.03", "loginCount": 2},
  {"externalId": "auth0|699f823f4993018f2f06dda8", "email": "jrowmd@gmail.com", "firstName": "Jason", "lastName": "Row", "timezone": null, "accountId": "a5ca4dd2-2c3c-4b77-987f-136ca621cd2a", "lastLogin": "2026-02-25 23:14:09.626", "loginCount": 1},
  {"externalId": "auth0|67adc88353418c4e48707d25", "email": "edwardsedwards@yopmail.com", "firstName": "Thomas", "lastName": "Edwards", "timezone": null, "accountId": "4748d430-06cf-45f2-b040-7eede85d81dd", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|67ac9534b46c23efd6abe21d", "email": "campbellcampbell@yopmail.com", "firstName": "Jonathan", "lastName": "Campbell", "timezone": null, "accountId": "2a094949-8230-477d-9fc9-8ebb2afe09e1", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|67adf12de641b0a9b60c4257", "email": "steve@yopmail.com", "firstName": "STEVE", "lastName": "DOHORTHY", "timezone": null, "accountId": "261a4336-ff44-4d34-b1af-8f08e572cd69", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6607c98d6484e28b078b77fa", "email": "alikhan12@gmail.com", "firstName": "Alikhan", "lastName": "Alikhan", "timezone": null, "accountId": "6607c98d7ff77d7f4fc8fb96", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|657ca012143847890e97bb00", "email": "pmorrissey@promedinnovations.com", "firstName": "Pete", "lastName": "Morrissey", "timezone": null, "accountId": "6575d96ed112ab559d3fc0f9", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|670e800cb6d3c79dcdac4000", "email": "samayjaccob@yopmail.com", "firstName": "Samay", "lastName": "Jaccob", "timezone": null, "accountId": "670e632bc1fbf879b999097d", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6607c30a4451a899ec16f712", "email": "hasimjan053@gmail.com", "firstName": "hjan", "lastName": "hjan", "timezone": null, "accountId": null, "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|657b04b7a79a7db4eb588d5f", "email": "jrg@nexvooinc.com", "firstName": "JR", "lastName": "Gayman (Hancock Member)", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-10-28 09:34:35.219", "loginCount": 3},
  {"externalId": "auth0|69a0abfbd78c68a701dd9fbf", "email": "tisha.karnes@yahoo.com", "firstName": "Tisha", "lastName": "Bennett", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-04-07 22:12:45.285", "loginCount": 2},
  {"externalId": "auth0|69016c7d6def3cd6f9bbf096", "email": "mweidner@hancockhealth.org", "firstName": "Madelyn", "lastName": "Weidner", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-10-29 11:59:07.881", "loginCount": 2},
  {"externalId": "auth0|6586247b113de1c950dcddb9", "email": "jaymichael@test1234321.com", "firstName": "Jay", "lastName": "Micheal", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2023-12-23 00:06:19.724", "loginCount": 1},
  {"externalId": "auth0|658641322f870e2d03ac7394", "email": "darrenpaul@test1234321.com", "firstName": "Darren", "lastName": "Paul", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2024-03-01 23:43:48.244", "loginCount": 10},
  {"externalId": "auth0|666068d209df3e6e44d3fe54", "email": "asinghal@omnimd.com", "firstName": "Akhil", "lastName": "Singhal", "timezone": null, "accountId": "666065de371f27ce24a37f00", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|661991cd07c9f19826dd119d", "email": "api@danambrose.com", "firstName": "API", "lastName": "User", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|65ba9b8a069b6866115ee0ea", "email": "chris@coffeymedical.com", "firstName": "Chris", "lastName": "Coffey", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6924bc018b9b9bae29f66f5a", "email": "stephenla3@aol.com", "firstName": "Stephenie", "lastName": "Hoskins", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-06 00:08:17.957", "loginCount": 4},
  {"externalId": "auth0|6901c97aeac4e4f396e5fa00", "email": "hashimhealthflexx@gmail.com", "firstName": "Hashim", "lastName": "", "timezone": null, "accountId": "59f02370-e1f9-4bbf-969c-2ab115cec31d", "lastLogin": "2025-10-29 07:59:56.5", "loginCount": 1},
  {"externalId": "auth0|657c69753f3088fa201020c1", "email": "jrg@techinnovation.com", "firstName": "JR", "lastName": "Gayman", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2025-10-17 08:03:20.51", "loginCount": 9},
  {"externalId": "auth0|6926536cab6ce5da5b9a1667", "email": "rchurch70@icloud.com", "firstName": "Richard", "lastName": "", "timezone": null, "accountId": "9524b634-fc46-4478-b453-dd1add841ec9", "lastLogin": "2026-01-08 00:38:19.236", "loginCount": 2},
  {"externalId": "auth0|6607c9ce52ae4fcaf88786b8", "email": "ali22222@gmail.com", "firstName": "ali", "lastName": "ali", "timezone": null, "accountId": "6607c9ce7ff77d7f4fc8fb98", "lastLogin": "2024-03-30 08:14:08.465", "loginCount": 1},
  {"externalId": "auth0|673301ce74b748e8aead56ba", "email": "lpoul@yopmail.com", "firstName": "Loken", "lastName": "Poul", "timezone": null, "accountId": "15424411-e5f0-4fab-93c8-ec18827ad1b0", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|66265c53803705fa35a6fafa", "email": "bernard.bubanic@intsourceone.com", "firstName": "Dr.", "lastName": "Bernard", "timezone": null, "accountId": "66265b4be39a29f4a9d855d0", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|66ff95e0cb237667bbe97906", "email": "junemarry@yopmail.com", "firstName": "Dr", "lastName": "June", "timezone": null, "accountId": "666065de371f27ce24a37f00", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|657a0b85d1cbd0437ef108df", "email": "doc_brown@danambrose.com", "firstName": "Doc", "lastName": "Brown", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|69a0b41a2d1f70d46300b92c", "email": "kathypeters23@icloud.com", "firstName": "Kathy", "lastName": "Peters", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-04-08 22:33:53.192", "loginCount": 5},
  {"externalId": "auth0|69078c7f8e59c5293ffbc12d", "email": "Uzair.Jan336@gmail.com", "firstName": "Uzair", "lastName": "", "timezone": null, "accountId": "ef75ae12-8d42-4348-99d1-5be137c8b5dd", "lastLogin": "2025-11-06 18:48:25.53", "loginCount": 2},
  {"externalId": "auth0|692dbbc1bbe0cce3a69c4dfe", "email": "Jnm-jlm@hotmail.com", "firstName": "Janet", "lastName": "Murphy", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-12-01 16:01:07.216", "loginCount": 1},
  {"externalId": "auth0|69aad7efa02bd10b358e1697", "email": "akqasim1999@gmail.com", "firstName": "Qasim", "lastName": "Jan", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2026-03-06 13:34:41.834", "loginCount": 1},
  {"externalId": "auth0|65862f0f033bf133ad35d94b", "email": "jimjeremy@test1234321.com", "firstName": "Jim", "lastName": "Jeremy", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2023-12-23 00:51:28.383", "loginCount": 1},
  {"externalId": "auth0|66f52806a56d052cc298152b", "email": "rukejohn@yopmail.com", "firstName": "Ruke", "lastName": "John", "timezone": null, "accountId": "66f526ecd6646e7cb7842e40", "lastLogin": "2024-09-26 09:25:55.082", "loginCount": 1},
  {"externalId": "auth0|66fe56c8b1473eaf995bf863", "email": "johnmark@yopmail.com", "firstName": "John", "lastName": "Mark", "timezone": null, "accountId": "66f526ecd6646e7cb7842e40", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|66f6684de80120ce1497fe23", "email": "djoshi@yopmail.com", "firstName": "Dr", "lastName": "Deep", "timezone": null, "accountId": "666065de371f27ce24a37f00", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6731d6ededdc262bd0d5d7d3", "email": "andrewt@yopmail.com", "firstName": "Andrew", "lastName": "Teal", "timezone": null, "accountId": "15424411-e5f0-4fab-93c8-ec18827ad1b0", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|67add876bf10c47a8530ae7e", "email": "david@yopmail.com", "firstName": "DAVID ", "lastName": "DOHORTHY", "timezone": null, "accountId": "66d66923-25e3-4ddc-8e15-7d3055764167", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6607c3a36484e28b078b75d0", "email": "alikhan@gmail.com", "firstName": "Alikhan", "lastName": "Alikhan", "timezone": null, "accountId": null, "lastLogin": "2024-03-30 07:47:57.407", "loginCount": 1},
  {"externalId": "auth0|6908e946f90c498fc1e98cc6", "email": "uzairleo.337@gmail.com", "firstName": "Haleema", "lastName": "", "timezone": null, "accountId": "e504bbe9-7478-4297-bc5d-af8f78656653", "lastLogin": "2025-12-21 19:07:59.908", "loginCount": 4},
  {"externalId": "auth0|657b75c38fff00fdee440e1d", "email": "nm2@danambrose.com", "firstName": "Nurse", "lastName": "User", "timezone": null, "accountId": "64dd6656b36cde55c09deadf", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|659b042815ae22da4b89e386", "email": "support@healthflexxinc.com", "firstName": "Caroline", "lastName": "Smith", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2024-10-08 13:31:49.675", "loginCount": 26},
  {"externalId": "auth0|667ad83560e3c1f2ca770def", "email": "girirajpurohit@yopmail.com", "firstName": "Dr", "lastName": "Giriraj", "timezone": null, "accountId": "666065de371f27ce24a37f00", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|657b1706c6746f7c0f3eb11c", "email": "nm11@danambrose.com", "firstName": "Test", "lastName": "User", "timezone": null, "accountId": "64dd6656b36cde55c09deadf", "lastLogin": "2024-08-22 20:27:35.833", "loginCount": 16},
  {"externalId": "auth0|672db5938f2f46888de66db9", "email": "roseforrest@yopmail.com", "firstName": "Rose", "lastName": "Forrest", "timezone": null, "accountId": "666065de371f27ce24a37f00", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|692fc50ee2621e75d7585809", "email": "sammonme@gmail.com", "firstName": "Shahan", "lastName": "", "timezone": null, "accountId": "7e1c7b89-8c56-4830-b9c3-12e66abab7e9", "lastLogin": "2025-12-03 05:05:20.112", "loginCount": 1},
  {"externalId": "auth0|69adf3ebc0d42a5958b48f01", "email": "ahinkle@hancockhealth.org", "firstName": "Amanda", "lastName": "Hinkle", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-11 00:46:07.811", "loginCount": 3},
  {"externalId": "auth0|6607c2010cd3786863248175", "email": "hasimjan03@gmail.com", "firstName": "hjan", "lastName": "hjan", "timezone": null, "accountId": null, "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6909a9a38ac1b98aa7404138", "email": "alias.uetp@gmail.com", "firstName": "Ali", "lastName": "", "timezone": null, "accountId": "d2129100-43e0-4f1a-87c1-4037dd806812", "lastLogin": "2026-04-06 06:27:16.169", "loginCount": 6},
  {"externalId": "auth0|69aeb47d69058fd166f5d722", "email": "allisonturner1991@gmail.com", "firstName": "Allison", "lastName": "Turner", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-04-08 16:36:32.804", "loginCount": 2},
  {"externalId": "auth0|6586397b32bc99c4f9ef9f73", "email": "stevejones@test1234321.com", "firstName": "Steve", "lastName": "Jones", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2023-12-23 01:50:30.86", "loginCount": 3},
  {"externalId": "auth0|658637c18d750bdc3985e841", "email": "michaelkyle@test1234321.com", "firstName": "Michael", "lastName": "Kyle", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2023-12-23 01:28:35.102", "loginCount": 2},
  {"externalId": "auth0|66065fcf2f2e4a68b06173ed", "email": "string@gmail.com", "firstName": "string", "lastName": "string", "timezone": null, "accountId": "66065fce51d8ab3677de836d", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|657fbec6c6746f7c0f3ef79c", "email": "nm15@danambrose.com", "firstName": "Test", "lastName": "15", "timezone": null, "accountId": "64dd6656b36cde55c09deadf", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|670e78f492e985469c7c54ae", "email": "jacksonford@yopmail.com", "firstName": "Jackson", "lastName": "Ford", "timezone": null, "accountId": "670e632bc1fbf879b999097d", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|6932278ed43690ee7c5b05f4", "email": "samebuck32@aol.com", "firstName": "Trevin", "lastName": "", "timezone": null, "accountId": "5b873d76-430b-4438-914f-680605167a31", "lastLogin": "2025-12-05 00:30:07.479", "loginCount": 1},
  {"externalId": "auth0|657c9f13c9dc29d13719625e", "email": "rufford@promedinnovations.com", "firstName": "Rob", "lastName": "Ufford", "timezone": null, "accountId": "6575d96ed112ab559d3fc0f9", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|657a62472aea778b0b76f9d0", "email": "nurse@danambrose.com", "firstName": "Nurse", "lastName": "Dan", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2024-06-14 21:17:16.83", "loginCount": 14},
  {"externalId": "auth0|6605d2ec4451a899ec15c263", "email": "kenkonstanzer@gmail.com", "firstName": "Ken", "lastName": "Konstanzer", "timezone": null, "accountId": "6605d2eb03320afa5b1ae82f", "lastLogin": "2024-03-29 18:13:12.329", "loginCount": 2},
  {"externalId": "auth0|64acaedf9e37434ddffdf8fc", "email": "mdrew@c24.health", "firstName": "Matthew", "lastName": "Drew", "timezone": null, "accountId": "64acaedec55db442e1adbe78", "lastLogin": "2023-08-05 03:32:09.679", "loginCount": 8},
  {"externalId": "auth0|66be017649bcdc48b54a2def", "email": "cameron.badgley@continuumlink.com", "firstName": "Cameron", "lastName": "Badgley", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|657ca0fdc9dc29d13719628b", "email": "jmcgibbon@vypin.com", "firstName": "JT", "lastName": "Mcgibbon", "timezone": null, "accountId": "6575d96ed112ab559d3fc0f9", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|69aeba80d3976f898ab7e5be", "email": "maybellemanalo@gmail.com", "firstName": "Maybelle", "lastName": "", "timezone": null, "accountId": "95f7f088-5de4-4054-8877-c442b5616777", "lastLogin": "2026-04-09 23:49:20.65", "loginCount": 3},
  {"externalId": "auth0|690a1c735b7524fd53389023", "email": "Jeremy.wagner@intsourceone.com", "firstName": "Jeremy", "lastName": "", "timezone": null, "accountId": "1fe8e939-17c4-470f-aabc-13357561a3e8", "lastLogin": "2025-11-04 15:37:16.317", "loginCount": 2},
  {"externalId": "auth0|69323746d15b9011dcb788d1", "email": "nicole.mcginley.1978@gmail.com", "firstName": "Nicole", "lastName": "", "timezone": null, "accountId": "f628ab67-5b69-4f09-b7d6-9baa831f2413", "lastLogin": "2025-12-05 01:37:11.636", "loginCount": 1},
  {"externalId": "auth0|6607ca964451a899ec16f9fb", "email": "awais@gmail.com", "firstName": "awais", "lastName": "awais", "timezone": null, "accountId": null, "lastLogin": "2024-03-30 08:17:28.346", "loginCount": 1},
  {"externalId": "auth0|678ea74b2f514ace32ccc202", "email": "matteiler135@gmail.com", "firstName": "Matt", "lastName": "Eiler", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2026-01-25 16:49:14.279", "loginCount": 12},
  {"externalId": "auth0|679bd9e9c2f7f21d61022bdd", "email": "jasonc@shepherdcommunity.org", "firstName": "Jason", "lastName": "Courtney", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-06-28 13:38:58.89", "loginCount": 5},
  {"externalId": "auth0|68a63c20ecea844d6f2ac403", "email": "greysonpritch@gmail.com", "firstName": "Isaac", "lastName": "Isaac", "timezone": null, "accountId": "0280c452-7de0-4c02-8d9b-f710d29822ce", "lastLogin": "2025-08-22 01:45:23.887", "loginCount": 2},
  {"externalId": "auth0|68651bca7c92767c436b3cde", "email": "janette_haben@yahoo.com", "firstName": "Janette", "lastName": "Streveler", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-07-02 11:45:14.646", "loginCount": 1},
  {"externalId": "auth0|67b7abc44c049f11667a4932", "email": "samanthad@shepherdcommunity.org", "firstName": "Samantha", "lastName": "Dyachenko", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-02-20 22:25:09.117", "loginCount": 1},
  {"externalId": "auth0|68e162104c09217b1ae8ce6c", "email": "sigmanc@uindy.edu", "firstName": "Coran", "lastName": "Sigman", "timezone": null, "accountId": "41b5ec7a-cda8-4788-be75-d2981f37ecee", "lastLogin": "2025-10-04 18:06:08.782", "loginCount": 1},
  {"externalId": "auth0|690bb17a5ec8c832f602cc52", "email": "pmueller@hancockhealth.org", "firstName": "Paul", "lastName": "Mueller", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-11-05 20:20:12.731", "loginCount": 1},
  {"externalId": "auth0|68f6a396a7d0f1b4f9fc8873", "email": "cgibson3@hancockhealth.org", "firstName": "Caroline", "lastName": "Gibson", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-10-20 21:03:19.526", "loginCount": 1},
  {"externalId": "auth0|68f1ff2e003c6ffc70cb44d1", "email": "hashimjan123@gmail.com", "firstName": "Hashim", "lastName": "Hashim", "timezone": null, "accountId": "c6efa07a-a444-41dd-ba22-48b0aaacf060", "lastLogin": "2025-10-17 08:32:48.23", "loginCount": 1},
  {"externalId": "auth0|69b43e9da897a65eea36dff5", "email": "melissacozatt@gmail.com", "firstName": "Melissa", "lastName": "Cozatt", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-03-13 16:43:11.665", "loginCount": 1},
  {"externalId": "auth0|68f141b26d40bf8fa170c6aa", "email": "slong3@hancockhealth.org", "firstName": "Steve", "lastName": "Long", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2026-02-02 12:28:06.14", "loginCount": 4},
  {"externalId": "auth0|63b662a7913b53a4ee9d66ea", "email": "dan@danambrose.net", "firstName": "Dan", "lastName": "Ambrose", "timezone": "America/Indianapolis", "accountId": "63be43abedf5877276d96d82", "lastLogin": "2026-03-24 03:36:01.976", "loginCount": 737},
  {"externalId": "auth0|68b9820373a5d0d9f9a2007d", "email": "aliislamian123@gmail.com", "firstName": "Ali", "lastName": "Ali", "timezone": null, "accountId": "182671a9-0603-4211-b57e-ebd2e565e26d", "lastLogin": "2025-09-04 12:11:47.983", "loginCount": 1},
  {"externalId": "auth0|67a5c8fb295d7628750d5019", "email": "mdanishzahid01@gmail.com", "firstName": "Muhammad", "lastName": "Muhammad", "timezone": null, "accountId": "2682281f-2c30-4a70-8639-ff259de2ed0c", "lastLogin": "2025-02-07 08:49:01.381", "loginCount": 1},
  {"externalId": "auth0|679009556ce1546a578f24b2", "email": "joannabeckett1@gmail.com", "firstName": "Joanna", "lastName": "Beckett", "timezone": null, "accountId": "67224cfab490d7f2f6cf7dc9", "lastLogin": "2025-06-03 02:15:47.011", "loginCount": 5},
  {"externalId": "auth0|65fca710c673febf0f6ca9a5", "email": "jamesron@test1234.com", "firstName": "James", "lastName": "Ron", "timezone": null, "accountId": "63be43abedf5877276d96d82", "lastLogin": "2024-03-21 21:31:18.563", "loginCount": 3},
  {"externalId": "auth0|68f1e35fe78b745000321f5c", "email": "hashim@gmail.com", "firstName": "Hashim", "lastName": "Hashim", "timezone": null, "accountId": "14dcac66-7b6c-4fe0-be30-7f00797ec007", "lastLogin": "2025-10-17 06:34:08.906", "loginCount": 1},
  {"externalId": "auth0|68f51c0788f26846f7c171e8", "email": "tneal@hancockhealth.org", "firstName": "Tyler", "lastName": "Neal", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-10-20 20:40:26.674", "loginCount": 4},
  {"externalId": "auth0|6933d8289bf26544ad2bb4e7", "email": "ahmadalik525@gmail.com", "firstName": "Ahmad", "lastName": "", "timezone": null, "accountId": "9321ae99-1a93-455e-952a-52e539fc946e", "lastLogin": "2025-12-06 07:15:54.224", "loginCount": 1},
  {"externalId": "auth0|68c1306b88648c8ab3d878fc", "email": "jonas@vanhastel.com", "firstName": "Jonas", "lastName": "Jonas", "timezone": null, "accountId": "62667fda-29ca-4fd0-8c5b-00f57734a9f2", "lastLogin": "2025-09-10 08:01:48.657", "loginCount": 1},
  {"externalId": "auth0|68f1e09f25b5f3a4f98ca286", "email": "hashimtest@gmail.com", "firstName": "Hashim", "lastName": "Test", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2025-10-17 06:22:24.752", "loginCount": 1},
  {"externalId": "auth0|68e034a135714b64e419082d", "email": "zhardley77@gmail.com", "firstName": "Zakiya", "lastName": "Hardley", "timezone": null, "accountId": "a7252c06-f1fe-4a94-822f-d38c121c1b59", "lastLogin": "2025-10-03 20:40:02.56", "loginCount": 1},
  {"externalId": "auth0|68eefaddc95f78256ab2c405", "email": "meghannholmes@gmail.com", "firstName": "Meg", "lastName": "Holmes", "timezone": null, "accountId": "618e4552-159c-421d-951e-693c0bc3af5a", "lastLogin": "2025-10-15 01:37:34.128", "loginCount": 1},
  {"externalId": "auth0|67adc4dabf10c47a8530a408", "email": "arthurarthur@yopmail.com", "firstName": "Arthur", "lastName": "John", "timezone": null, "accountId": "2a094949-8230-477d-9fc9-8ebb2afe09e1", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|67ac91616cfb32cfcb264cf7", "email": "lanelane@yopmail.com", "firstName": "Jeffrey", "lastName": "Lane", "timezone": null, "accountId": "2a094949-8230-477d-9fc9-8ebb2afe09e1", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|670d32d7377ab5a2210f3f82", "email": "jackjoshi@yopmail.com", "firstName": "Dr.", "lastName": "Jack", "timezone": null, "accountId": "670d30a359e3348521d39929", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|67adcd3b1167fa238813cea5", "email": "sdohorthy@yopmail.com", "firstName": "STUART", "lastName": "DOHORTHY", "timezone": null, "accountId": "fa4a06a6-36d0-4d69-af75-3b4ab96da5ef", "lastLogin": null, "loginCount": 0},
  {"externalId": "auth0|68f149713b5219ae91d5f22e", "email": "alikhan988810@gmail.com", "firstName": "Hashim", "lastName": "Test", "timezone": null, "accountId": "657b1147f5f35c5efcd7e7ff", "lastLogin": "2025-11-10 08:30:09.23", "loginCount": 4}
]$legacy$::jsonb
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
