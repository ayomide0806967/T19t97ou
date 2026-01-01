-- ============================================================================
-- Migration 012: Realtime Configuration
-- Enable Supabase Realtime for specific tables
-- ============================================================================

-- Note: This must be run after all tables are created
-- Supabase Realtime allows clients to subscribe to database changes

-- Enable realtime for feed/posts (live feed updates)
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE post_likes;
ALTER PUBLICATION supabase_realtime ADD TABLE post_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE post_reposts;

-- Enable realtime for quiz monitoring (live exam tracking)
ALTER PUBLICATION supabase_realtime ADD TABLE quiz_attempts;
ALTER PUBLICATION supabase_realtime ADD TABLE quiz_responses;

-- Enable realtime for notifications (instant notifications)
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Enable realtime for class members (live member updates)
ALTER PUBLICATION supabase_realtime ADD TABLE class_members;

-- ============================================================================
-- Realtime Broadcast Channels (for custom events)
-- ============================================================================

-- These are configured in the client, but here's documentation:
-- 
-- 1. quiz:${quiz_id} - Broadcast channel for quiz events
--    - participant_joined
--    - participant_progress
--    - participant_submitted
--    - quiz_ended
--
-- 2. class:${class_id} - Broadcast channel for class events
--    - new_resource
--    - new_announcement
--    - member_joined
--
-- 3. feed:global - Broadcast channel for trending/global events
--    - trending_post
--    - system_announcement

-- ============================================================================
-- Supabase Edge Function Hints
-- ============================================================================

-- For complex real-time scenarios, consider these Edge Functions:
-- 
-- 1. quiz-heartbeat
--    - Called every 10 seconds during quiz
--    - Updates last_heartbeat in quiz_attempts
--    - Broadcasts participant status changes
--
-- 2. quiz-auto-submit
--    - Scheduled function that checks for timed-out quizzes
--    - Automatically submits attempts past their time limit
--
-- 3. notification-push
--    - Listens to notification inserts
--    - Sends push notifications via FCM/APNs
