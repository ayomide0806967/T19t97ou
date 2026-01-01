-- ============================================================================
-- Migration 010: Notifications
-- User notifications for various events
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Notification type
  type TEXT NOT NULL CHECK (type IN (
    'like', 'comment', 'follow', 'mention', 'repost', 'quote',
    'quiz_invite', 'quiz_result', 'class_invite', 'class_update',
    'note_comment', 'resource_added', 'system'
  )),
  
  -- Content
  title TEXT,
  body TEXT,
  
  -- Actor (who caused this notification)
  actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  
  -- Target reference (what the notification is about)
  target_type TEXT CHECK (target_type IN ('post', 'comment', 'quiz', 'class', 'note', 'resource', 'profile')),
  target_id UUID,
  
  -- Metadata (flexible additional data)
  metadata JSONB DEFAULT '{}',
  
  -- Status
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, created_at DESC) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- RLS Policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own notifications" ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications" ON notifications FOR INSERT
  WITH CHECK (true); -- Typically created by triggers/functions

CREATE POLICY "Users can mark own as read" ON notifications FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own notifications" ON notifications FOR DELETE
  USING (user_id = auth.uid());

-- Helper function to mark notifications as read
CREATE OR REPLACE FUNCTION mark_notifications_read(p_notification_ids UUID[])
RETURNS INTEGER AS $$
  UPDATE notifications 
  SET is_read = true, read_at = NOW() 
  WHERE id = ANY(p_notification_ids) AND user_id = auth.uid()
  RETURNING 1;
$$ LANGUAGE SQL SECURITY DEFINER;

-- Helper function to mark all as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS INTEGER AS $$
  WITH updated AS (
    UPDATE notifications 
    SET is_read = true, read_at = NOW() 
    WHERE user_id = auth.uid() AND is_read = false
    RETURNING 1
  )
  SELECT COUNT(*)::INTEGER FROM updated;
$$ LANGUAGE SQL SECURITY DEFINER;

-- Trigger function to create notification on post like
CREATE OR REPLACE FUNCTION create_like_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_post_author_id UUID;
  v_actor_name TEXT;
BEGIN
  SELECT author_id INTO v_post_author_id FROM posts WHERE id = NEW.post_id;
  SELECT full_name INTO v_actor_name FROM profiles WHERE id = NEW.user_id;
  
  -- Don't notify yourself
  IF v_post_author_id != NEW.user_id THEN
    INSERT INTO notifications (user_id, type, actor_id, target_type, target_id, title)
    VALUES (v_post_author_id, 'like', NEW.user_id, 'post', NEW.post_id, v_actor_name || ' liked your post');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_post_liked
  AFTER INSERT ON post_likes
  FOR EACH ROW
  EXECUTE FUNCTION create_like_notification();

-- Trigger for follow notification
CREATE OR REPLACE FUNCTION create_follow_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_actor_name TEXT;
BEGIN
  SELECT full_name INTO v_actor_name FROM profiles WHERE id = NEW.follower_id;
  
  INSERT INTO notifications (user_id, type, actor_id, target_type, target_id, title)
  VALUES (NEW.following_id, 'follow', NEW.follower_id, 'profile', NEW.follower_id, v_actor_name || ' started following you');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_follow
  AFTER INSERT ON follows
  FOR EACH ROW
  EXECUTE FUNCTION create_follow_notification();

-- Trigger for comment notification
CREATE OR REPLACE FUNCTION create_comment_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_post_author_id UUID;
  v_actor_name TEXT;
BEGIN
  SELECT author_id INTO v_post_author_id FROM posts WHERE id = NEW.post_id;
  SELECT full_name INTO v_actor_name FROM profiles WHERE id = NEW.author_id;
  
  -- Don't notify yourself
  IF v_post_author_id != NEW.author_id THEN
    INSERT INTO notifications (user_id, type, actor_id, target_type, target_id, title)
    VALUES (v_post_author_id, 'comment', NEW.author_id, 'post', NEW.post_id, v_actor_name || ' commented on your post');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_post_commented
  AFTER INSERT ON post_comments
  FOR EACH ROW
  EXECUTE FUNCTION create_comment_notification();
