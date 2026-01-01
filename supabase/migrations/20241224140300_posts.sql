-- ============================================================================
-- Migration 003: Posts Refactor
-- Core posts table with proper relationships
-- ============================================================================

CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  
  -- Post relationships
  quote_id UUID REFERENCES posts(id) ON DELETE SET NULL, -- For quote tweets
  reply_to_id UUID REFERENCES posts(id) ON DELETE SET NULL, -- For threads/replies
  
  -- Visibility and scoping
  visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'followers', 'class')),
  class_id UUID, -- FK added after classes table exists
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ -- Soft delete
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_reply_to ON posts(reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_posts_quote ON posts(quote_id) WHERE quote_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_posts_visibility ON posts(visibility);

-- Trigger for updated_at
CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public posts are viewable by everyone"
  ON posts FOR SELECT
  USING (
    deleted_at IS NULL AND (
      visibility = 'public' 
      OR author_id = auth.uid()
      OR (visibility = 'followers' AND EXISTS(
        SELECT 1 FROM follows WHERE follower_id = auth.uid() AND following_id = author_id
      ))
    )
  );

CREATE POLICY "Users can create posts"
  ON posts FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Users can soft-delete own posts"
  ON posts FOR DELETE
  USING (auth.uid() = author_id);
