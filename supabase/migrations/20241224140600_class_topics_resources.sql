-- ============================================================================
-- Migration 006: Class Topics and Resources
-- Lecture topics and file resources for classes
-- ============================================================================

-- Class Topics (for lecture organization)
CREATE TABLE IF NOT EXISTS class_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  tutor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  is_private BOOLEAN NOT NULL DEFAULT false,
  require_pin BOOLEAN NOT NULL DEFAULT false,
  pin_code TEXT,
  auto_archive_at TIMESTAMPTZ,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_class_topics_class ON class_topics(class_id);
CREATE INDEX IF NOT EXISTS idx_class_topics_order ON class_topics(class_id, order_index);

CREATE TRIGGER update_class_topics_updated_at
  BEFORE UPDATE ON class_topics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Class Resources (files, documents, videos)
CREATE TABLE IF NOT EXISTS class_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  topic_id UUID REFERENCES class_topics(id) ON DELETE SET NULL,
  uploaded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL, -- Supabase Storage URL
  file_type TEXT NOT NULL, -- 'pdf', 'doc', 'docx', 'ppt', 'video', etc.
  file_size TEXT, -- Human-readable: "2.5 MB"
  file_size_bytes BIGINT, -- Exact size for sorting
  download_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_class_resources_class ON class_resources(class_id);
CREATE INDEX IF NOT EXISTS idx_class_resources_topic ON class_resources(topic_id);

-- RLS Policies
ALTER TABLE class_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_resources ENABLE ROW LEVEL SECURITY;

-- Topics viewable by class members
CREATE POLICY "Topics viewable by class members" ON class_topics FOR SELECT
  USING (
    EXISTS(SELECT 1 FROM class_members WHERE class_id = class_topics.class_id AND user_id = auth.uid())
    OR EXISTS(SELECT 1 FROM classes WHERE id = class_id AND facilitator_id = auth.uid())
  );

CREATE POLICY "Class admins can manage topics" ON class_topics FOR INSERT
  WITH CHECK (
    EXISTS(SELECT 1 FROM class_members WHERE class_id = class_topics.class_id AND user_id = auth.uid() AND role IN ('admin', 'facilitator', 'ta'))
    OR EXISTS(SELECT 1 FROM classes WHERE id = class_id AND facilitator_id = auth.uid())
  );

CREATE POLICY "Class admins can update topics" ON class_topics FOR UPDATE
  USING (
    EXISTS(SELECT 1 FROM class_members WHERE class_id = class_topics.class_id AND user_id = auth.uid() AND role IN ('admin', 'facilitator', 'ta'))
    OR tutor_id = auth.uid()
  );

CREATE POLICY "Class admins can delete topics" ON class_topics FOR DELETE
  USING (
    EXISTS(SELECT 1 FROM class_members WHERE class_id = class_topics.class_id AND user_id = auth.uid() AND role IN ('admin', 'facilitator'))
  );

-- Resources viewable by class members
CREATE POLICY "Resources viewable by class members" ON class_resources FOR SELECT
  USING (
    EXISTS(SELECT 1 FROM class_members WHERE class_id = class_resources.class_id AND user_id = auth.uid())
    OR EXISTS(SELECT 1 FROM classes WHERE id = class_id AND facilitator_id = auth.uid())
  );

CREATE POLICY "Class admins can upload resources" ON class_resources FOR INSERT
  WITH CHECK (
    auth.uid() = uploaded_by AND (
      EXISTS(SELECT 1 FROM class_members WHERE class_id = class_resources.class_id AND user_id = auth.uid() AND role IN ('admin', 'facilitator', 'ta'))
      OR EXISTS(SELECT 1 FROM classes WHERE id = class_id AND facilitator_id = auth.uid())
    )
  );

CREATE POLICY "Uploaders can update own resources" ON class_resources FOR UPDATE
  USING (uploaded_by = auth.uid());

CREATE POLICY "Uploaders can delete own resources" ON class_resources FOR DELETE
  USING (uploaded_by = auth.uid());
