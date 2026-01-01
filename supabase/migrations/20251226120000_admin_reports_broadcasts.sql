-- ============================================================================
-- Migration: Reports Table for Content Moderation
-- ============================================================================

-- Reports table for user-submitted content reports
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Reporter
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- What is being reported
  content_type TEXT NOT NULL CHECK (content_type IN ('post', 'comment', 'user', 'message', 'class', 'note')),
  content_id UUID NOT NULL,
  
  -- Report details
  reason TEXT NOT NULL CHECK (reason IN (
    'spam', 'harassment', 'hate_speech', 'violence', 'nudity', 
    'misinformation', 'copyright', 'impersonation', 'other'
  )),
  description TEXT,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed', 'actioned')),
  
  -- Resolution
  reviewed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  resolution_notes TEXT,
  action_taken TEXT CHECK (action_taken IN ('none', 'warning_issued', 'content_removed', 'user_suspended', 'user_banned')),
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Prevent duplicate reports
  CONSTRAINT unique_report UNIQUE (reporter_id, content_type, content_id)
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_content ON reports(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_reports_created ON reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_pending ON reports(created_at DESC) WHERE status = 'pending';

-- RLS Policies
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports
CREATE POLICY "Users can create reports" ON reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

-- Users can view their own reports
CREATE POLICY "Users can view own reports" ON reports FOR SELECT
  USING (reporter_id = auth.uid());

-- ============================================================================
-- Admin Broadcasts table for admin-sent notifications
-- ============================================================================

CREATE TABLE IF NOT EXISTS admin_broadcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Content
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  
  -- Target audience
  target_type TEXT NOT NULL DEFAULT 'all' CHECK (target_type IN ('all', 'class', 'segment', 'user')),
  target_id UUID, -- class_id, user_id, or null for all/segment
  target_name TEXT, -- human-readable target name
  
  -- Scheduling
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sent', 'failed')),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  
  -- Metadata
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
  recipient_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_broadcasts_status ON admin_broadcasts(status);
CREATE INDEX IF NOT EXISTS idx_admin_broadcasts_created ON admin_broadcasts(created_at DESC);

-- RLS - Only admins can access (enforced via edge function)
ALTER TABLE admin_broadcasts ENABLE ROW LEVEL SECURITY;

-- No direct access policies - all access through edge functions with service role
