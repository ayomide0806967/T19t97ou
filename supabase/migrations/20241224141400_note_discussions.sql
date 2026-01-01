-- ============================================================================
-- Migration 014: Note Discussions
-- Class discussions under each note
-- ============================================================================

-- Note Discussions (threaded discussions under notes)
-- Unlike note_comments (simple comments), discussions support threads
CREATE TABLE IF NOT EXISTS note_discussions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id UUID NOT NULL REFERENCES class_notes(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- For threaded replies
  parent_id UUID REFERENCES note_discussions(id) ON DELETE CASCADE,
  
  -- Content
  body TEXT NOT NULL,
  
  -- Attachments (images, diagrams)
  attachment_urls TEXT[] DEFAULT '{}',
  
  -- Engagement
  like_count INTEGER NOT NULL DEFAULT 0,
  reply_count INTEGER NOT NULL DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  
  -- Moderation
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  is_resolved BOOLEAN NOT NULL DEFAULT false,
  resolved_by UUID REFERENCES profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_note_discussions_note ON note_discussions(note_id);
CREATE INDEX IF NOT EXISTS idx_note_discussions_parent ON note_discussions(parent_id);
CREATE INDEX IF NOT EXISTS idx_note_discussions_author ON note_discussions(author_id);
CREATE INDEX IF NOT EXISTS idx_note_discussions_pinned ON note_discussions(note_id) WHERE is_pinned = true;

CREATE TRIGGER update_note_discussions_updated_at
  BEFORE UPDATE ON note_discussions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Discussion Likes
CREATE TABLE IF NOT EXISTS note_discussion_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID NOT NULL REFERENCES note_discussions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT unique_discussion_like UNIQUE (discussion_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_note_discussion_likes_discussion ON note_discussion_likes(discussion_id);

-- RLS Policies
ALTER TABLE note_discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_discussion_likes ENABLE ROW LEVEL SECURITY;

-- Discussions viewable by people who can view the note
CREATE POLICY "Discussions viewable with note access" ON note_discussions FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM class_notes cn 
    WHERE cn.id = note_id AND (
      cn.visibility = 'public' 
      OR cn.author_id = auth.uid()
      OR (cn.visibility = 'class' AND EXISTS(
        SELECT 1 FROM class_members WHERE class_id = cn.class_id AND user_id = auth.uid()
      ))
    )
  ));

CREATE POLICY "Note viewers can discuss" ON note_discussions FOR INSERT
  WITH CHECK (
    author_id = auth.uid() AND
    EXISTS(
      SELECT 1 FROM class_notes cn 
      WHERE cn.id = note_id AND (
        cn.visibility = 'public' 
        OR cn.author_id = auth.uid()
        OR (cn.visibility = 'class' AND EXISTS(
          SELECT 1 FROM class_members WHERE class_id = cn.class_id AND user_id = auth.uid()
        ))
      )
    )
  );

CREATE POLICY "Authors can edit own discussions" ON note_discussions FOR UPDATE
  USING (author_id = auth.uid());

CREATE POLICY "Authors can delete own discussions" ON note_discussions FOR DELETE
  USING (author_id = auth.uid());

-- Like policies
CREATE POLICY "Likes visible" ON note_discussion_likes FOR SELECT USING (true);
CREATE POLICY "Users can like" ON note_discussion_likes FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can unlike" ON note_discussion_likes FOR DELETE USING (user_id = auth.uid());

-- Update like count trigger
CREATE OR REPLACE FUNCTION update_discussion_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE note_discussions SET like_count = like_count + 1 WHERE id = NEW.discussion_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE note_discussions SET like_count = like_count - 1 WHERE id = OLD.discussion_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_discussion_like_change
  AFTER INSERT OR DELETE ON note_discussion_likes
  FOR EACH ROW
  EXECUTE FUNCTION update_discussion_like_count();

-- Update reply count trigger
CREATE OR REPLACE FUNCTION update_discussion_reply_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.parent_id IS NOT NULL THEN
    UPDATE note_discussions SET reply_count = reply_count + 1 WHERE id = NEW.parent_id;
  ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NOT NULL THEN
    UPDATE note_discussions SET reply_count = reply_count - 1 WHERE id = OLD.parent_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_discussion_reply_change
  AFTER INSERT OR DELETE ON note_discussions
  FOR EACH ROW
  EXECUTE FUNCTION update_discussion_reply_count();

-- Enable realtime for discussions
ALTER PUBLICATION supabase_realtime ADD TABLE note_discussions;

-- Add 'message' to notifications type if not exists
-- (Already added in migration 010, but ensure it's there)
DO $$
BEGIN
  -- The check constraint was already created with 'message' type in mind
  NULL;
END $$;
