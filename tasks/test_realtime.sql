-- ============================================================
-- TEST: Bot-initiated message via Realtime
-- Run in Supabase SQL Editor (https://supabase.com/dashboard)
-- ============================================================

-- Step 1: Find your test user's conversation
-- (Replace the email with your test account)
SELECT c.id AS conversation_id, p.id AS person_id, p.email
FROM conversations c
JOIN person p ON p.id = c.person_id
WHERE p.email = 'YOUR_TEST_EMAIL_HERE'
LIMIT 1;

-- Step 2: Insert a fake bot message
-- Copy the conversation_id from Step 1 and paste below
INSERT INTO chat_messages (conversation_id, sender_type, content, status)
VALUES (
    'PASTE_CONVERSATION_ID_HERE',
    'bot',
    'Hey! Just checking in — how are your steps going today? 🚶',
    'sent'
);

-- Step 3: Verify it was inserted
SELECT id, sender_type, content, status, created_at
FROM chat_messages
WHERE conversation_id = 'PASTE_CONVERSATION_ID_HERE'
ORDER BY created_at DESC
LIMIT 3;

-- ============================================================
-- TEST: Verify unread count works
-- ============================================================
SELECT COUNT(*) AS unread_count
FROM chat_messages
WHERE conversation_id = 'PASTE_CONVERSATION_ID_HERE'
  AND sender_type = 'bot'
  AND status IN ('sent', 'delivered');

-- ============================================================
-- TEST: Mark as read (simulates what the app does)
-- ============================================================
-- UPDATE chat_messages
-- SET status = 'read', read_at = now()
-- WHERE conversation_id = 'PASTE_CONVERSATION_ID_HERE'
--   AND sender_type = 'bot'
--   AND status IN ('sent', 'delivered');
