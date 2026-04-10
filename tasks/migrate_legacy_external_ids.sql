-- Migrate legacy externalId -> persons.external_id + persons.resolved_id
-- Project: behavior_change_app (run in Supabase SQL editor)
-- Source : HEALTHFLEXX Medical project, public.users (270 rows)
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
-- 270 records embedded below, generated from
-- tasks/legacy_users.json (gitignored). Re-run this script to
-- refresh the map after a fresh dump.

CREATE TABLE IF NOT EXISTS public.legacy_user_map (
  email       text PRIMARY KEY,
  external_id text NOT NULL,
  first_name  text,
  last_name   text,
  loaded_at   timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.legacy_user_map (email, external_id, first_name, last_name)
SELECT
  lower(r->>'email')  AS email,
  r->>'externalId'    AS external_id,
  r->>'firstName'     AS first_name,
  r->>'lastName'      AS last_name
FROM jsonb_array_elements(
$legacy$[
  {"externalId": "auth0|6862bb137f9769c44dc77c64", "email": "swilson@hancockhealth.org", "firstName": "Stephanie", "lastName": "Wilson"},
  {"externalId": "auth0|67db725f9ee191b13df46f6e", "email": "cloud.alex96@yahoo.com", "firstName": "Alex", "lastName": "Cloud"},
  {"externalId": "auth0|678ed2a98da87f46e6bc34f3", "email": "ayelend@shepherdcommunity.org", "firstName": "Ayelen", "lastName": "Dominguez"},
  {"externalId": "auth0|686323dde6ba3a35212cf101", "email": "jwynn@hancockhealth.org", "firstName": "Jonie", "lastName": "Wynn"},
  {"externalId": "auth0|678e859a2f514ace32cca650", "email": "jennieg@shepherdcommunity.org", "firstName": "Jennie", "lastName": "Gibson"},
  {"externalId": "auth0|63dd8971c6848b5e2fe17ab3", "email": "john@healthflexxinc.com", "firstName": "JR", "lastName": "Gayman"},
  {"externalId": "auth0|67b0cbb660448f7726229021", "email": "kandrad@shepherdcommunity.org", "firstName": "Kandra", "lastName": "Dees"},
  {"externalId": "auth0|67c48d353b26fc4bbb392178", "email": "epturnbaugh@yahoo.com", "firstName": "Evangeline", "lastName": "Turnbaugh"},
  {"externalId": "auth0|66068716d25f1e3b83a34a94", "email": "aliapple@gmail.com", "firstName": "apple", "lastName": "apple"},
  {"externalId": "auth0|6862c255ab2a08d0302a3aaf", "email": "emilystoffel2@gmail.com", "firstName": "Emily", "lastName": "Stoffel"},
  {"externalId": "auth0|685191d817055a3327a7084f", "email": "slarge60@gmail.com", "firstName": "Stephen", "lastName": "Large"},
  {"externalId": "auth0|69411b31cf986b3650a10a9c", "email": "mbilalzamankpk575@gmail.com", "firstName": "Bilal", "lastName": ""},
  {"externalId": "auth0|6851a112a89c0bbe4540ed22", "email": "stanleylarge51@gmail.com", "firstName": "Stanley", "lastName": "Large"},
  {"externalId": "auth0|677ad6038b3a9e743d65fca5", "email": "chris@healthflexxinc.com", "firstName": "Chris", "lastName": "Watkins"},
  {"externalId": "auth0|64e6236f07a0c7e17eb00bfd", "email": "ben.park.md@gmail.com", "firstName": "Ben", "lastName": "Park"},
  {"externalId": "auth0|686424989fa081a5fd18edcf", "email": "gharter@hancockhealth.org", "firstName": "Garren", "lastName": "Harter"},
  {"externalId": "auth0|690c3ad7429935b35263ff1e", "email": "matif.uetp@gmail.com", "firstName": "Atif", "lastName": "Khan"},
  {"externalId": "auth0|679cc8f81ed6e01bc94c300c", "email": "bethb@shepherdcommunity.org", "firstName": "Beth", "lastName": "Brown"},
  {"externalId": "auth0|67a58bb2588ebba4e5b5c692", "email": "allens@shepherdcommunity.org", "firstName": "Allen", "lastName": "Southerland"},
  {"externalId": "auth0|679c61372e1a1ffa3af93b53", "email": "jennifera@shepherdcommunity.org", "firstName": "Jennifer", "lastName": "Agramonte"},
  {"externalId": "auth0|68547014e2f4aa3d49c268b5", "email": "jhungate@hancockhealth.org", "firstName": "Joel", "lastName": "Hungate"},
  {"externalId": "auth0|6876515a2f8aefbbafa3ee6e", "email": "davidm@shepherdcommunity.org", "firstName": "David", "lastName": "Martinez"},
  {"externalId": "auth0|6862c000e6ba3a35212c952f", "email": "jaiciw@yaboo.com", "firstName": "Jaici", "lastName": "Wright"},
  {"externalId": "auth0|679c2133d6293d4d1bd1e349", "email": "reneep@shepherdcommunity.org", "firstName": "Renee", "lastName": "Pitzulo"},
  {"externalId": "auth0|6837a52f56324d8b914a41a1", "email": "mollyc@shepherdcommunity.org", "firstName": "Molly", "lastName": "Molly"},
  {"externalId": "auth0|687a1fbcfaca3389251fd92c", "email": "hashimjann9@gmail.com", "firstName": "Hashim", "lastName": "Jan"},
  {"externalId": "auth0|6837966ce1f33633fd8f978b", "email": "camdenc@shepherdcommunity.org", "firstName": "Camden", "lastName": "Camden"},
  {"externalId": "auth0|679c017bd6293d4d1bd1cae4", "email": "cloud.kristen66@gmail.com", "firstName": "Kristie", "lastName": "Kristie"},
  {"externalId": "auth0|693bbb08f77a56c8601f0966", "email": "alikhan121@gmail.com", "firstName": "Ali", "lastName": ""},
  {"externalId": "auth0|6986153748d01e33548e0d25", "email": "khite538@gmail.com", "firstName": "Kevin", "lastName": "Hite"},
  {"externalId": "auth0|69b9ae7e2bf404eb625484a3", "email": "pamelaelaine5@gmail.com", "firstName": "Pam", "lastName": "Smith"},
  {"externalId": "auth0|685ad174e8505af951166d36", "email": "john@techinnovation.com", "firstName": "John", "lastName": "Gayman"},
  {"externalId": "auth0|678e9ac3867fe46be24946bb", "email": "westlakedennis@gmail.com", "firstName": "Dennis", "lastName": "Westlake"},
  {"externalId": "auth0|65c1d99483cbc9037e94d803", "email": "vanwyk.andre.c@gmail.com", "firstName": "Andre", "lastName": "van"},
  {"externalId": "auth0|6862c14dab2a08d0302a3991", "email": "cory.hisle@outlook.com", "firstName": "Cory", "lastName": "Hisle"},
  {"externalId": "auth0|683655c3883946bef81720ee", "email": "wheelwinner22@aol.com", "firstName": "Jana", "lastName": "Kindred"},
  {"externalId": "auth0|69163e9a9a70fef6fcced9a2", "email": "marlohubbard5@gmail.com", "firstName": "Marlo", "lastName": "Hubbard"},
  {"externalId": "auth0|67a106cc3cbf7b3e902de66c", "email": "mark@shepherdcommunity.org", "firstName": "Mark", "lastName": "Hiehle"},
  {"externalId": "auth0|679bde5bc34f1ed2f0e83a34", "email": "danielmu@shepherdcommunity.org", "firstName": "Daniel", "lastName": "Mutowa"},
  {"externalId": "auth0|6945da646eeaf1c88825499d", "email": "ssteinhu@purdue.edu", "firstName": "Steve", "lastName": "Steinhubl"},
  {"externalId": "auth0|69c1c171e356b82e90b27705", "email": "Michelle.kitsis@gmail.com", "firstName": "Michelle", "lastName": "Kitsis"},
  {"externalId": "auth0|67a01abc0a665648185fe89e", "email": "edsolares15@gmail.com", "firstName": "Edson", "lastName": "Solares"},
  {"externalId": "auth0|69861bcbfacc27867d4b756e", "email": "vleehughes75@aol.com", "firstName": "Lee", "lastName": "Hughes"},
  {"externalId": "auth0|67a0c8c32167e5581b4e35d5", "email": "rachels@shepherdcommunity.org", "firstName": "Rachel", "lastName": "Southerland"},
  {"externalId": "auth0|677a5b648b3a9e743d65c333", "email": "john1@healthflexxinc.com", "firstName": "tester", "lastName": "person2"},
  {"externalId": "auth0|669fde0775160b6da51131ae", "email": "jmmaly154@gmail.com", "firstName": "ali", "lastName": "ali"},
  {"externalId": "auth0|666068651c8ecded64125ee3", "email": "ksharma@omnimd.com", "firstName": "Kamal", "lastName": "Sharma"},
  {"externalId": "auth0|679bff3250e7086615a1ecaa", "email": "c2kurtz@yahoo.com", "firstName": "Cory", "lastName": "Kurtz"},
  {"externalId": "auth0|682e2c8b1cc1cdb602121318", "email": "phillipburrer@gmail.com", "firstName": "Phillip", "lastName": "Phillip"},
  {"externalId": "auth0|69c1c58e1eea7b92ccc97695", "email": "Landonshane2010@gmail.com", "firstName": "Kelsey", "lastName": "Flowers"},
  {"externalId": "auth0|679bdbddbceb28fe5bb37924", "email": "amyw@shepherdcommunity.org", "firstName": "Amy", "lastName": "Wallace"},
  {"externalId": "auth0|67a4ef2588067971c2ccae25", "email": "muhammad49ibrar@gmail.com", "firstName": "Muhammad", "lastName": "Ibrar"},
  {"externalId": "auth0|679c34cf50e7086615a21394", "email": "paigep@shepherdcommunity.org", "firstName": "Paige", "lastName": "Parks"},
  {"externalId": "auth0|691cce33bdf6ef601149fefb", "email": "afetti05@hotmail.com", "firstName": "Adam", "lastName": "Fettinger"},
  {"externalId": "auth0|695c0553419f44215e9a3b3f", "email": "bkphare@yahoo.com", "firstName": "Belinda", "lastName": "phares"},
  {"externalId": "auth0|6988bf5ffd6b2469c49d191a", "email": "steelersdj@gmail.com", "firstName": "Dena", "lastName": "Jacquay"},
  {"externalId": "auth0|647035f2ae9317825e48e456", "email": "demo@healthflexxinc.com", "firstName": "Demo", "lastName": "User"},
  {"externalId": "auth0|6863146ca4646de8bbdc1387", "email": "jhigbee@hancockhealth.org", "firstName": "Joy", "lastName": "Higbee"},
  {"externalId": "auth0|691cd0c1c6984f88d8b80c94", "email": "lferrara@hancockhealth.org", "firstName": "Lissa", "lastName": "Ferrara"},
  {"externalId": "auth0|67b244613ebf5ff2b94d2e69", "email": "karalee_white24@gmail.com", "firstName": "Karalee", "lastName": "White"},
  {"externalId": "auth0|679beb2c50e7086615a1dba1", "email": "alhood81689@gmil.com", "firstName": "Amber", "lastName": "Hood"},
  {"externalId": "auth0|67aca66c965b1f3a25dfa28d", "email": "adiagrindean@icloud.com", "firstName": "Adia", "lastName": "Adia"},
  {"externalId": "auth0|5e3276832485400edbb3f5ec", "email": "dan@danambrose.com", "firstName": "Dr", "lastName": "Ambrose"},
  {"externalId": "auth0|67931caad6a7b7a60028757d", "email": "alikhan21@gmail.com", "firstName": "Ali", "lastName": "Ali"},
  {"externalId": "auth0|678aee86cb9af3b04efa6ef9", "email": "indysmith69@gmail.com", "firstName": "Billy", "lastName": "Smith"},
  {"externalId": "auth0|670d31ba4b3dd541b70ed4b0", "email": "alexjoshi@yopmail.com", "firstName": "Dr.", "lastName": "Alex"},
  {"externalId": "auth0|69c40c8d4bb33120e64106da", "email": "phi4alpha@aol.om", "firstName": "Chris", "lastName": "Burns"},
  {"externalId": "auth0|6965116a88f37208240b8746", "email": "sarwatamin179@gmail.com", "firstName": "Sarwat", "lastName": ""},
  {"externalId": "auth0|698ba74ede623acaadd27982", "email": "jimjacobsen714@icloud.com", "firstName": "Jim", "lastName": ""},
  {"externalId": "auth0|6862c2587cf6eeaa1d5b3c6e", "email": "codywbaker@gmail.com", "firstName": "Cody", "lastName": "Baker"},
  {"externalId": "auth0|679e60c84b5fcf52553b89ce", "email": "andrewg@shepherdcommunity.org", "firstName": "Andrew", "lastName": "Green"},
  {"externalId": "auth0|691deb8aa8116f167a3630b9", "email": "miacarter4712@gmail.com", "firstName": "Mia", "lastName": "Carter"},
  {"externalId": "auth0|678e98612f514ace32ccb5d2", "email": "zarkydrew@gmail.com", "firstName": "Drew", "lastName": "Talleyrand"},
  {"externalId": "auth0|658616c38d750bdc3985e67d", "email": "mikejohn@test1234321.com", "firstName": "Mike", "lastName": "John"},
  {"externalId": "auth0|674edbedf762a2e2742bf682", "email": "sandraframe@yopmail.com", "firstName": "Sandra", "lastName": "Frame"},
  {"externalId": "auth0|67a021abd71602e637dbb8e1", "email": "tifanyo@shepherdcommunity.org", "firstName": "Tifany", "lastName": "Otis"},
  {"externalId": "auth0|69c87e04724f851d20d527d1", "email": "sidrajamil@9988gmail.com", "firstName": "Sidra", "lastName": "Jamil"},
  {"externalId": "auth0|69692fa0b55d062368d94eaa", "email": "pethessa@rose-hulman.edu", "firstName": "Sandor", "lastName": ""},
  {"externalId": "auth0|698cd5e162ef74bbab9d25b8", "email": "engr.hamzatakkar@gmail.com", "firstName": "Hazrat", "lastName": ""},
  {"externalId": "auth0|67b27c443ebf5ff2b94d4f3e", "email": "rbuckley@tecklinx.com", "firstName": "Robert", "lastName": "Buckley"},
  {"externalId": "auth0|679e552138a701c24c2c94ba", "email": "rachelr@shepherdcommunity.org", "firstName": "Rachel", "lastName": "Rhoad"},
  {"externalId": "auth0|67a70c51668f09e59055273d", "email": "alikhan123@gmail.com", "firstName": "ALI", "lastName": "ALI"},
  {"externalId": "auth0|676d53e1fb101a49a5194ce5", "email": "support@techinnovation.com", "firstName": "Tester", "lastName": "Person"},
  {"externalId": "auth0|67a10a040a6656481860866a", "email": "jbrunnemer26@gmail.com", "firstName": "Julia", "lastName": "Julia"},
  {"externalId": "auth0|69c88519476df28866d6ce99", "email": "kashifjan5651@gmail.com", "firstName": "Kashif", "lastName": ""},
  {"externalId": "auth0|68657e12b22e620ebb4c1ea4", "email": "shurst@hancockhealth.org", "firstName": "Sarah", "lastName": "Hurst"},
  {"externalId": "auth0|678e8af26f6eefac0b0daee4", "email": "dakota18373@gmail.com", "firstName": "Dakota", "lastName": "Boyle"},
  {"externalId": "auth0|691f1b8cb72dea59b16126e5", "email": "ericagentry@att.net", "firstName": "Erica", "lastName": "Gentry"},
  {"externalId": "auth0|698f9e036602233864a85d20", "email": "parker.deirdre@yahoo.com", "firstName": "Deirdre", "lastName": ""},
  {"externalId": "auth0|6973889270091c86b691eda5", "email": "riddle21@purdue.edu", "firstName": "Andrea", "lastName": "Riddle"},
  {"externalId": "auth0|678e9d437465b998692d6857", "email": "bethanyrmorfordphd@gmail.com", "firstName": "Bethany", "lastName": "Morford"},
  {"externalId": "auth0|65953d91ae9356a77307ff8a", "email": "sulaimanakhtar99888@gmail.com", "firstName": "Sulaiman", "lastName": "Akhtar"},
  {"externalId": "auth0|687915c1ad05437b8120a205", "email": "john@flexxxcorporation.com", "firstName": "Lang", "lastName": "Lang"},
  {"externalId": "auth0|652bf73f9befb209639c7cf0", "email": "bill@healthflexxinc.com", "firstName": "Bill", "lastName": "Smith"},
  {"externalId": "auth0|678e848798d8acb44b8d7093", "email": "kathyb@shepherdcommunity.org", "firstName": "Katherine", "lastName": "Bianco"},
  {"externalId": "auth0|69d002d1a9dba404eb55291d", "email": "joeonguitar@yahoo.com", "firstName": "Joseph", "lastName": ""},
  {"externalId": "auth0|698fc11c20bfe79a6b12cc0d", "email": "danielsegal07@gmail.com", "firstName": "Daniel", "lastName": "Segal"},
  {"externalId": "auth0|6973953eb490cf4e0ccbedeb", "email": "mnwatson@purdue.edu", "firstName": "Monique", "lastName": "Watson"},
  {"externalId": "auth0|6901140a9f3e506035962ca3", "email": "hashimjan033@gmail.com", "firstName": "Hashim", "lastName": "Jan"},
  {"externalId": "auth0|691f788af15e7b53e72df0c5", "email": "hlthomas2115@gmail.com", "firstName": "Heather", "lastName": "Thomas"},
  {"externalId": "auth0|685aa882df5efbd368218676", "email": "hashimjan@gmail.com", "firstName": "Hashim", "lastName": "Hashim"},
  {"externalId": "auth0|67f9251d947c2fddb22d3b94", "email": "latonia196@gmail.com", "firstName": "Latonia", "lastName": "Smith"},
  {"externalId": "auth0|679d3b3f93ecc6a49343fedb", "email": "koltonw@shepherdcommunity.org", "firstName": "Kolton", "lastName": "Williford"},
  {"externalId": "auth0|679bdd07b43abc00f74c3c64", "email": "kimg@shepherdcommunity.org", "firstName": "Kim", "lastName": "Grindean"},
  {"externalId": "auth0|678e9f553dba7fdcdc30b277", "email": "westlakecindy1279@gmail.com", "firstName": "Cindy", "lastName": "Westlake"},
  {"externalId": "auth0|6977caef0498a096ec37440e", "email": "amin43@purdue.edu", "firstName": "Sarwat", "lastName": "Amin"},
  {"externalId": "auth0|6862babf7354027de6141943", "email": "lori.hurst34@gmail.com", "firstName": "Lori", "lastName": "Deemer"},
  {"externalId": "auth0|6920878c930e66f21a8c5172", "email": "tbuckley@hancockhealth.org", "firstName": "Taylor", "lastName": "Buckley"},
  {"externalId": "auth0|6993639d007e1b713bb3d76e", "email": "itxshahid881@gmail.com", "firstName": "Shahid", "lastName": ""},
  {"externalId": "auth0|69d0617160fa802f05a95d24", "email": "cgeibel@hancockhealth.org", "firstName": "Tina", "lastName": "Geibel"},
  {"externalId": "auth0|67a5778c09aedf3a9cbe9bcc", "email": "karalee_white24@yahoo.com", "firstName": "Karalee", "lastName": "White"},
  {"externalId": "auth0|67eb08fea2002d34627826f5", "email": "johan@yoyomotion.com", "firstName": "johan", "lastName": "johan"},
  {"externalId": "auth0|679ce706f4e0dcdf67f5df10", "email": "airionnj@gmail.com", "firstName": "Airionn", "lastName": "Johnson"},
  {"externalId": "auth0|679cc52a92f51ce539c7bac9", "email": "emmal@shepherdcommunity.org", "firstName": "Emma", "lastName": "Lindsay"},
  {"externalId": "auth0|678d970e2f514ace32cc1771", "email": "nigarzeynalova@gmail.com", "firstName": "Zeynalova", "lastName": "Zeynalova"},
  {"externalId": "auth0|677c19d6b243c7ed0b92fe9f", "email": "bpark@healthflexxinc.com", "firstName": "Ben", "lastName": "Park"},
  {"externalId": "auth0|69938804132d1306146a14c9", "email": "mgrady@ecommunity.com", "firstName": "M", "lastName": ""},
  {"externalId": "auth0|692089c439a1f9c53ea67f93", "email": "jweidner@hancockhealth.org", "firstName": "Jenny", "lastName": "Weidner"},
  {"externalId": "auth0|67bb6c5ff79f9774ad574137", "email": "asadeee998@gmail.com", "firstName": "Asad", "lastName": "Asad"},
  {"externalId": "auth0|679bdb30c34f1ed2f0e83745", "email": "claires@shepherdcommunity.org", "firstName": "Claire", "lastName": "Schuerman"},
  {"externalId": "auth0|679cea0a1ed6e01bc94c4a97", "email": "montse.parga.az@gmail.com", "firstName": "Azeneth", "lastName": "Gonzalez"},
  {"externalId": "auth0|679ce1e9c8db8f6e8abf1c6a", "email": "gabes@shepherdcommunity.org", "firstName": "Gabe", "lastName": "Short"},
  {"externalId": "auth0|677d7bd86f2bfb1add5752ee", "email": "test4@healthflexxinc.com", "firstName": "test", "lastName": "person4"},
  {"externalId": "auth0|678d0513228755f0c53a34de", "email": "test6@healthflexxinc.com", "firstName": "Test", "lastName": "Person6"},
  {"externalId": "auth0|6995e78de5b03d2d369db887", "email": "rmreynolds9123@yahoo.com", "firstName": "Rachel", "lastName": "Downey"},
  {"externalId": "auth0|67a393432df06ab1db878435", "email": "mneel0@icloud.com", "firstName": "Mary", "lastName": "Neel"},
  {"externalId": "auth0|69208f9102e823560f58633e", "email": "Abraham.salazar3@gmail.com", "firstName": "Abe", "lastName": "Salazar"},
  {"externalId": "auth0|6862c3b77354027de6142212", "email": "mgraves086@gmail.com", "firstName": "Michelle", "lastName": "Graves"},
  {"externalId": "auth0|65df4194f761c4a0b0d9b7db", "email": "zubair1836@gmail.com", "firstName": "Zubair", "lastName": "Zubair"},
  {"externalId": "auth0|679c2c70bceb28fe5bb3b94e", "email": "kelseys@shepherdcommunity.org", "firstName": "Kelsey", "lastName": "Shaver"},
  {"externalId": "auth0|64dd665493376a40a98213e9", "email": "dan@danambrose.org", "firstName": "Dan", "lastName": "Ambrose"},
  {"externalId": "auth0|67ec4dbfad275302233bf04d", "email": "anastasiiatkachovas@gmail.com", "firstName": "Nastia", "lastName": "Tkachova"},
  {"externalId": "auth0|6920a806f83a947aac2631ab", "email": "vester505@gmail.com", "firstName": "Heather", "lastName": "Vester"},
  {"externalId": "auth0|66f6714e57dcf572ef7991bc", "email": "jpanchal@yopmail.com", "firstName": "Jigar", "lastName": "Panchal"},
  {"externalId": "auth0|67b280f2f638be604875dbd0", "email": "cindylpappin@gmail.com", "firstName": "Cindy", "lastName": "Pappin"},
  {"externalId": "auth0|679d8b81af054bdd43bc8358", "email": "jacinthesandra@yahoo.fr", "firstName": "Sandra", "lastName": "Talleyrand"},
  {"externalId": "auth0|6995f0f450a672ca389a0b38", "email": "jakers1972@yahoo.com", "firstName": "Jennifer", "lastName": "Robbins"},
  {"externalId": "auth0|65861bc0fada0de9e126131e", "email": "test1@test.com", "firstName": "Fred", "lastName": "Jones"},
  {"externalId": "auth0|667ad998b62992785b7fe51e", "email": "hallmark@yopmail.com", "firstName": "Dr", "lastName": "Hall"},
  {"externalId": "auth0|65fdd0181ab283bfb94ac4f6", "email": "test123456789@test12345678.com", "firstName": "John", "lastName": "friend2"},
  {"externalId": "auth0|6703bb7af5ec2a66bcbfb516", "email": "rellymark@yopmail.com", "firstName": "Dr.", "lastName": "Relly"},
  {"externalId": "auth0|65bd091e09afb150624cbdf1", "email": "andre@avw-p.com", "firstName": "Andre", "lastName": "van"},
  {"externalId": "auth0|6586365b34f1c95b45e344c5", "email": "jimkurt@test1234321.com", "firstName": "Jim", "lastName": "Kurt"},
  {"externalId": "auth0|670dff169eb3cd7d813192a3", "email": "johnford@yopmail.com", "firstName": "John", "lastName": "Ford"},
  {"externalId": "auth0|657b6b58338a535bfa24e468", "email": "john@flexxcorporation.com", "firstName": "Ben", "lastName": "H"},
  {"externalId": "auth0|67f3da6db071ff9e69df60c5", "email": "johnmartin@yopmail.com", "firstName": "John", "lastName": "Martin"},
  {"externalId": "auth0|678283b1f190b9bc399e87e8", "email": "tmacre@yahoo.com", "firstName": "Tom", "lastName": "Acre"},
  {"externalId": "auth0|648b80631a2bfb723ea66b6d", "email": "lot920@gmail.com", "firstName": "Susie", "lastName": "Susie"},
  {"externalId": "auth0|6877529144d55100dab049ea", "email": "kellystark@yopmail.com", "firstName": "Kelly", "lastName": "Stark"},
  {"externalId": "auth0|67f3db7139893b62fda25637", "email": "johncook@yopmail.com", "firstName": "John", "lastName": "Cook"},
  {"externalId": "auth0|6567e32fbd1b7fa874190735", "email": "healthflexx1@gmail.com", "firstName": "Elizabeth", "lastName": "Gannon"},
  {"externalId": "auth0|674f0a1bf762a2e2742c1377", "email": "kimberleychance@yopmail.com", "firstName": "Kimberley", "lastName": "Chance"},
  {"externalId": "auth0|64508f5f33202ea9bfadddc5", "email": "navjeet@vitaltelemetrics.com", "firstName": "Navjeet", "lastName": "Chabbewal"},
  {"externalId": "auth0|658634112f870e2d03ac72fa", "email": "willjay@test1234321.com", "firstName": "Will", "lastName": "Jay"},
  {"externalId": "auth0|67049c7948f7a1b19d4734b5", "email": "omnimd@danambrose.com", "firstName": "Dan", "lastName": "Ambrose"},
  {"externalId": "auth0|674d6c63228a0923a493582f", "email": "vickiesmith@yopmail.com", "firstName": "Vickie", "lastName": "Smith"},
  {"externalId": "auth0|65fdcfec49ddc30bde012631", "email": "test123456789@test1234567.com", "firstName": "John", "lastName": "friend"},
  {"externalId": "auth0|66be01367228f4e8298adec5", "email": "russ.mcdonough@continuumlink.com", "firstName": "Russ", "lastName": "McDonough"},
  {"externalId": "auth0|63fec85679cb86b9e47e9b99", "email": "emather@gmail.com", "firstName": "Eric", "lastName": "Mather"},
  {"externalId": "auth0|67052235f5ec2a66bcc0c071", "email": "harryjames@yopmail.com", "firstName": "Dr.", "lastName": "Harry"},
  {"externalId": "auth0|6920add04ac06e069970adb9", "email": "hammons1001@gmail.com", "firstName": "Laney", "lastName": "Hammons"},
  {"externalId": "auth0|69965acdf340a1e41185411c", "email": "rsinclair4861@hotmail.com", "firstName": "Rhonda", "lastName": "Sinclair"},
  {"externalId": "auth0|67ad9561e641b0a9b60c12c4", "email": "davisdavis@yopmail.com", "firstName": "Steven", "lastName": "Davis"},
  {"externalId": "auth0|670e65e270cc400761b2517c", "email": "frankgoyette@yopmail.com", "firstName": "Frank", "lastName": "Goyette"},
  {"externalId": "auth0|67053d3148f7a1b19d479461", "email": "johndoe@yopmail.com", "firstName": "Doe", "lastName": "Doe  John"},
  {"externalId": "auth0|66f52781fefa55d130d273cd", "email": "dellyrenolt@yopmail.com", "firstName": "Delly", "lastName": "Renolt"},
  {"externalId": "auth0|6660af37eeb87cae44b69342", "email": "todd.pedersen@authenticx.com", "firstName": "Todd", "lastName": "Pedersen"},
  {"externalId": "auth0|65c02e3604d52f5d708b30e6", "email": "ruth.large@whakarongorau.nz", "firstName": "Ruth", "lastName": "Large"},
  {"externalId": "auth0|699cffdbe95f37d5547a5f4c", "email": "davidsegal646@gmail.com", "firstName": "David", "lastName": "Segal"},
  {"externalId": "auth0|664767a620e66227901270cd", "email": "sales10@nanway.com.cn", "firstName": "Jeff", "lastName": "Meng"},
  {"externalId": "auth0|65aeb11940a8ae84c30f6f90", "email": "mike@biltsolutions.com", "firstName": "Mike", "lastName": "Miklozek"},
  {"externalId": "auth0|66fe62d0c01572273393c99e", "email": "juliscot@yopmail.com", "firstName": "Juli", "lastName": "Scot"},
  {"externalId": "auth0|667adc6689fcdbcb1e2fa434", "email": "denmark@yopmail.com", "firstName": "Dr", "lastName": "Den"},
  {"externalId": "auth0|6660840acf13c844e6677127", "email": "markdavid7@yopmail.com", "firstName": "Mark", "lastName": "David"},
  {"externalId": "auth0|657c9fc48fff00fdee442386", "email": "kkonstanzer@promedinnovations.com", "firstName": "Ken", "lastName": "Konstanzer"},
  {"externalId": "auth0|657b77953f3088fa201010d3", "email": "nm3@danambrose.com", "firstName": "Another", "lastName": "Test"},
  {"externalId": "auth0|69215807d365adb1c101f518", "email": "hashimtest123@gmail.com", "firstName": "Hashim", "lastName": ""},
  {"externalId": "auth0|657c9d7f49b0f00e167bebf4", "email": "jrgayman3@gmail.com", "firstName": "JR", "lastName": "Gayman"},
  {"externalId": "auth0|6921ef8f279cfeae172129dd", "email": "sariyakhan@gmail.com", "firstName": "Sariya", "lastName": ""},
  {"externalId": "auth0|699f823f4993018f2f06dda8", "email": "jrowmd@gmail.com", "firstName": "Jason", "lastName": "Row"},
  {"externalId": "auth0|67adc88353418c4e48707d25", "email": "edwardsedwards@yopmail.com", "firstName": "Thomas", "lastName": "Edwards"},
  {"externalId": "auth0|67ac9534b46c23efd6abe21d", "email": "campbellcampbell@yopmail.com", "firstName": "Jonathan", "lastName": "Campbell"},
  {"externalId": "auth0|67adf12de641b0a9b60c4257", "email": "steve@yopmail.com", "firstName": "STEVE", "lastName": "DOHORTHY"},
  {"externalId": "auth0|6607c98d6484e28b078b77fa", "email": "alikhan12@gmail.com", "firstName": "Alikhan", "lastName": "Alikhan"},
  {"externalId": "auth0|657ca012143847890e97bb00", "email": "pmorrissey@promedinnovations.com", "firstName": "Pete", "lastName": "Morrissey"},
  {"externalId": "auth0|670e800cb6d3c79dcdac4000", "email": "samayjaccob@yopmail.com", "firstName": "Samay", "lastName": "Jaccob"},
  {"externalId": "auth0|6607c30a4451a899ec16f712", "email": "hasimjan053@gmail.com", "firstName": "hjan", "lastName": "hjan"},
  {"externalId": "auth0|657b04b7a79a7db4eb588d5f", "email": "jrg@nexvooinc.com", "firstName": "JR", "lastName": "Gayman (Hancock Member)"},
  {"externalId": "auth0|69a0abfbd78c68a701dd9fbf", "email": "tisha.karnes@yahoo.com", "firstName": "Tisha", "lastName": "Bennett"},
  {"externalId": "auth0|69016c7d6def3cd6f9bbf096", "email": "mweidner@hancockhealth.org", "firstName": "Madelyn", "lastName": "Weidner"},
  {"externalId": "auth0|6586247b113de1c950dcddb9", "email": "jaymichael@test1234321.com", "firstName": "Jay", "lastName": "Micheal"},
  {"externalId": "auth0|658641322f870e2d03ac7394", "email": "darrenpaul@test1234321.com", "firstName": "Darren", "lastName": "Paul"},
  {"externalId": "auth0|666068d209df3e6e44d3fe54", "email": "asinghal@omnimd.com", "firstName": "Akhil", "lastName": "Singhal"},
  {"externalId": "auth0|661991cd07c9f19826dd119d", "email": "api@danambrose.com", "firstName": "API", "lastName": "User"},
  {"externalId": "auth0|65ba9b8a069b6866115ee0ea", "email": "chris@coffeymedical.com", "firstName": "Chris", "lastName": "Coffey"},
  {"externalId": "auth0|6924bc018b9b9bae29f66f5a", "email": "stephenla3@aol.com", "firstName": "Stephenie", "lastName": "Hoskins"},
  {"externalId": "auth0|6901c97aeac4e4f396e5fa00", "email": "hashimhealthflexx@gmail.com", "firstName": "Hashim", "lastName": ""},
  {"externalId": "auth0|657c69753f3088fa201020c1", "email": "jrg@techinnovation.com", "firstName": "JR", "lastName": "Gayman"},
  {"externalId": "auth0|6926536cab6ce5da5b9a1667", "email": "rchurch70@icloud.com", "firstName": "Richard", "lastName": ""},
  {"externalId": "auth0|6607c9ce52ae4fcaf88786b8", "email": "ali22222@gmail.com", "firstName": "ali", "lastName": "ali"},
  {"externalId": "auth0|673301ce74b748e8aead56ba", "email": "lpoul@yopmail.com", "firstName": "Loken", "lastName": "Poul"},
  {"externalId": "auth0|66265c53803705fa35a6fafa", "email": "bernard.bubanic@intsourceone.com", "firstName": "Dr.", "lastName": "Bernard"},
  {"externalId": "auth0|66ff95e0cb237667bbe97906", "email": "junemarry@yopmail.com", "firstName": "Dr", "lastName": "June"},
  {"externalId": "auth0|657a0b85d1cbd0437ef108df", "email": "doc_brown@danambrose.com", "firstName": "Doc", "lastName": "Brown"},
  {"externalId": "auth0|69a0b41a2d1f70d46300b92c", "email": "kathypeters23@icloud.com", "firstName": "Kathy", "lastName": "Peters"},
  {"externalId": "auth0|69078c7f8e59c5293ffbc12d", "email": "Uzair.Jan336@gmail.com", "firstName": "Uzair", "lastName": ""},
  {"externalId": "auth0|692dbbc1bbe0cce3a69c4dfe", "email": "Jnm-jlm@hotmail.com", "firstName": "Janet", "lastName": "Murphy"},
  {"externalId": "auth0|69aad7efa02bd10b358e1697", "email": "akqasim1999@gmail.com", "firstName": "Qasim", "lastName": "Jan"},
  {"externalId": "auth0|65862f0f033bf133ad35d94b", "email": "jimjeremy@test1234321.com", "firstName": "Jim", "lastName": "Jeremy"},
  {"externalId": "auth0|66f52806a56d052cc298152b", "email": "rukejohn@yopmail.com", "firstName": "Ruke", "lastName": "John"},
  {"externalId": "auth0|66fe56c8b1473eaf995bf863", "email": "johnmark@yopmail.com", "firstName": "John", "lastName": "Mark"},
  {"externalId": "auth0|66f6684de80120ce1497fe23", "email": "djoshi@yopmail.com", "firstName": "Dr", "lastName": "Deep"},
  {"externalId": "auth0|6731d6ededdc262bd0d5d7d3", "email": "andrewt@yopmail.com", "firstName": "Andrew", "lastName": "Teal"},
  {"externalId": "auth0|67add876bf10c47a8530ae7e", "email": "david@yopmail.com", "firstName": "DAVID ", "lastName": "DOHORTHY"},
  {"externalId": "auth0|6607c3a36484e28b078b75d0", "email": "alikhan@gmail.com", "firstName": "Alikhan", "lastName": "Alikhan"},
  {"externalId": "auth0|6908e946f90c498fc1e98cc6", "email": "uzairleo.337@gmail.com", "firstName": "Haleema", "lastName": ""},
  {"externalId": "auth0|657b75c38fff00fdee440e1d", "email": "nm2@danambrose.com", "firstName": "Nurse", "lastName": "User"},
  {"externalId": "auth0|659b042815ae22da4b89e386", "email": "support@healthflexxinc.com", "firstName": "Caroline", "lastName": "Smith"},
  {"externalId": "auth0|667ad83560e3c1f2ca770def", "email": "girirajpurohit@yopmail.com", "firstName": "Dr", "lastName": "Giriraj"},
  {"externalId": "auth0|657b1706c6746f7c0f3eb11c", "email": "nm11@danambrose.com", "firstName": "Test", "lastName": "User"},
  {"externalId": "auth0|672db5938f2f46888de66db9", "email": "roseforrest@yopmail.com", "firstName": "Rose", "lastName": "Forrest"},
  {"externalId": "auth0|692fc50ee2621e75d7585809", "email": "sammonme@gmail.com", "firstName": "Shahan", "lastName": ""},
  {"externalId": "auth0|69adf3ebc0d42a5958b48f01", "email": "ahinkle@hancockhealth.org", "firstName": "Amanda", "lastName": "Hinkle"},
  {"externalId": "auth0|6607c2010cd3786863248175", "email": "hasimjan03@gmail.com", "firstName": "hjan", "lastName": "hjan"},
  {"externalId": "auth0|6909a9a38ac1b98aa7404138", "email": "alias.uetp@gmail.com", "firstName": "Ali", "lastName": ""},
  {"externalId": "auth0|69aeb47d69058fd166f5d722", "email": "allisonturner1991@gmail.com", "firstName": "Allison", "lastName": "Turner"},
  {"externalId": "auth0|6586397b32bc99c4f9ef9f73", "email": "stevejones@test1234321.com", "firstName": "Steve", "lastName": "Jones"},
  {"externalId": "auth0|658637c18d750bdc3985e841", "email": "michaelkyle@test1234321.com", "firstName": "Michael", "lastName": "Kyle"},
  {"externalId": "auth0|66065fcf2f2e4a68b06173ed", "email": "string@gmail.com", "firstName": "string", "lastName": "string"},
  {"externalId": "auth0|657fbec6c6746f7c0f3ef79c", "email": "nm15@danambrose.com", "firstName": "Test", "lastName": "15"},
  {"externalId": "auth0|670e78f492e985469c7c54ae", "email": "jacksonford@yopmail.com", "firstName": "Jackson", "lastName": "Ford"},
  {"externalId": "auth0|6932278ed43690ee7c5b05f4", "email": "samebuck32@aol.com", "firstName": "Trevin", "lastName": ""},
  {"externalId": "auth0|657c9f13c9dc29d13719625e", "email": "rufford@promedinnovations.com", "firstName": "Rob", "lastName": "Ufford"},
  {"externalId": "auth0|657a62472aea778b0b76f9d0", "email": "nurse@danambrose.com", "firstName": "Nurse", "lastName": "Dan"},
  {"externalId": "auth0|6605d2ec4451a899ec15c263", "email": "kenkonstanzer@gmail.com", "firstName": "Ken", "lastName": "Konstanzer"},
  {"externalId": "auth0|64acaedf9e37434ddffdf8fc", "email": "mdrew@c24.health", "firstName": "Matthew", "lastName": "Drew"},
  {"externalId": "auth0|66be017649bcdc48b54a2def", "email": "cameron.badgley@continuumlink.com", "firstName": "Cameron", "lastName": "Badgley"},
  {"externalId": "auth0|657ca0fdc9dc29d13719628b", "email": "jmcgibbon@vypin.com", "firstName": "JT", "lastName": "Mcgibbon"},
  {"externalId": "auth0|69aeba80d3976f898ab7e5be", "email": "maybellemanalo@gmail.com", "firstName": "Maybelle", "lastName": ""},
  {"externalId": "auth0|690a1c735b7524fd53389023", "email": "Jeremy.wagner@intsourceone.com", "firstName": "Jeremy", "lastName": ""},
  {"externalId": "auth0|69323746d15b9011dcb788d1", "email": "nicole.mcginley.1978@gmail.com", "firstName": "Nicole", "lastName": ""},
  {"externalId": "auth0|6607ca964451a899ec16f9fb", "email": "awais@gmail.com", "firstName": "awais", "lastName": "awais"},
  {"externalId": "auth0|678ea74b2f514ace32ccc202", "email": "matteiler135@gmail.com", "firstName": "Matt", "lastName": "Eiler"},
  {"externalId": "auth0|679bd9e9c2f7f21d61022bdd", "email": "jasonc@shepherdcommunity.org", "firstName": "Jason", "lastName": "Courtney"},
  {"externalId": "auth0|68a63c20ecea844d6f2ac403", "email": "greysonpritch@gmail.com", "firstName": "Isaac", "lastName": "Isaac"},
  {"externalId": "auth0|68651bca7c92767c436b3cde", "email": "janette_haben@yahoo.com", "firstName": "Janette", "lastName": "Streveler"},
  {"externalId": "auth0|67b7abc44c049f11667a4932", "email": "samanthad@shepherdcommunity.org", "firstName": "Samantha", "lastName": "Dyachenko"},
  {"externalId": "auth0|68e162104c09217b1ae8ce6c", "email": "sigmanc@uindy.edu", "firstName": "Coran", "lastName": "Sigman"},
  {"externalId": "auth0|690bb17a5ec8c832f602cc52", "email": "pmueller@hancockhealth.org", "firstName": "Paul", "lastName": "Mueller"},
  {"externalId": "auth0|68f6a396a7d0f1b4f9fc8873", "email": "cgibson3@hancockhealth.org", "firstName": "Caroline", "lastName": "Gibson"},
  {"externalId": "auth0|68f1ff2e003c6ffc70cb44d1", "email": "hashimjan123@gmail.com", "firstName": "Hashim", "lastName": "Hashim"},
  {"externalId": "auth0|69b43e9da897a65eea36dff5", "email": "melissacozatt@gmail.com", "firstName": "Melissa", "lastName": "Cozatt"},
  {"externalId": "auth0|68f141b26d40bf8fa170c6aa", "email": "slong3@hancockhealth.org", "firstName": "Steve", "lastName": "Long"},
  {"externalId": "auth0|63b662a7913b53a4ee9d66ea", "email": "dan@danambrose.net", "firstName": "Dan", "lastName": "Ambrose"},
  {"externalId": "auth0|68b9820373a5d0d9f9a2007d", "email": "aliislamian123@gmail.com", "firstName": "Ali", "lastName": "Ali"},
  {"externalId": "auth0|67a5c8fb295d7628750d5019", "email": "mdanishzahid01@gmail.com", "firstName": "Muhammad", "lastName": "Muhammad"},
  {"externalId": "auth0|679009556ce1546a578f24b2", "email": "joannabeckett1@gmail.com", "firstName": "Joanna", "lastName": "Beckett"},
  {"externalId": "auth0|65fca710c673febf0f6ca9a5", "email": "jamesron@test1234.com", "firstName": "James", "lastName": "Ron"},
  {"externalId": "auth0|68f1e35fe78b745000321f5c", "email": "hashim@gmail.com", "firstName": "Hashim", "lastName": "Hashim"},
  {"externalId": "auth0|68f51c0788f26846f7c171e8", "email": "tneal@hancockhealth.org", "firstName": "Tyler", "lastName": "Neal"},
  {"externalId": "auth0|6933d8289bf26544ad2bb4e7", "email": "ahmadalik525@gmail.com", "firstName": "Ahmad", "lastName": ""},
  {"externalId": "auth0|68c1306b88648c8ab3d878fc", "email": "jonas@vanhastel.com", "firstName": "Jonas", "lastName": "Jonas"},
  {"externalId": "auth0|68f1e09f25b5f3a4f98ca286", "email": "hashimtest@gmail.com", "firstName": "Hashim", "lastName": "Test"},
  {"externalId": "auth0|68e034a135714b64e419082d", "email": "zhardley77@gmail.com", "firstName": "Zakiya", "lastName": "Hardley"},
  {"externalId": "auth0|68eefaddc95f78256ab2c405", "email": "meghannholmes@gmail.com", "firstName": "Meg", "lastName": "Holmes"},
  {"externalId": "auth0|67adc4dabf10c47a8530a408", "email": "arthurarthur@yopmail.com", "firstName": "Arthur", "lastName": "John"},
  {"externalId": "auth0|67ac91616cfb32cfcb264cf7", "email": "lanelane@yopmail.com", "firstName": "Jeffrey", "lastName": "Lane"},
  {"externalId": "auth0|670d32d7377ab5a2210f3f82", "email": "jackjoshi@yopmail.com", "firstName": "Dr.", "lastName": "Jack"},
  {"externalId": "auth0|67adcd3b1167fa238813cea5", "email": "sdohorthy@yopmail.com", "firstName": "STUART", "lastName": "DOHORTHY"},
  {"externalId": "auth0|68f149713b5219ae91d5f22e", "email": "alikhan988810@gmail.com", "firstName": "Hashim", "lastName": "Test"}
]$legacy$::jsonb
) AS r
WHERE r->>'externalId' IS NOT NULL
ON CONFLICT (email) DO UPDATE
  SET external_id = EXCLUDED.external_id,
      first_name  = EXCLUDED.first_name,
      last_name   = EXCLUDED.last_name,
      loaded_at   = now();

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
-- Covers every insert path (handle_new_user from auth.users,
-- admin imports, manual inserts), not just the auth trigger.

CREATE OR REPLACE FUNCTION public.set_resolved_id_default()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
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
$func$;

DROP TRIGGER IF EXISTS persons_set_resolved_id ON public.persons;
CREATE TRIGGER persons_set_resolved_id
BEFORE INSERT ON public.persons
FOR EACH ROW
EXECUTE FUNCTION public.set_resolved_id_default();

-- Safety net: patch any new-style persons that still lack resolved_id
UPDATE public.persons
SET resolved_id = id::text
WHERE resolved_id IS NULL;
