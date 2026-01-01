-- ============================================================================
-- Migration 009: Notes
-- Class notes with sections and media
-- ============================================================================

-- Class Notes
CREATE TABLE IF NOT EXISTS class_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
  topic_id UUID REFERENCES class_topics(id) ON DELETE SET NULL,
  
  -- Content
  title TEXT NOT NULL,
  subtitle TEXT,
  
  -- Metadata
  estimated_minutes INTEGER,
  attached_quiz_id UUID REFERENCES quizzes(id) ON DELETE SET NULL,
  visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'class', 'private')),
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_class_notes_author ON class_notes(author_id);
CREATE INDEX IF NOT EXISTS idx_class_notes_class ON class_notes(class_id);
CREATE INDEX IF NOT EXISTS idx_class_notes_topic ON class_notes(topic_id);

CREATE TRIGGER update_class_notes_updated_at
  BEFORE UPDATE ON class_notes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Note Sections
CREATE TABLE IF NOT EXISTS note_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id UUID NOT NULL REFERENCES class_notes(id) ON DELETE CASCADE,
  
  -- Content
  title TEXT,
  subtitle TEXT,
  content_type TEXT NOT NULL DEFAULT 'bullets' CHECK (content_type IN ('bullets', 'paragraph', 'heading', 'code', 'quote')),
  bullets TEXT[] DEFAULT '{}',
  paragraph_text TEXT,
  
  -- Ordering
  order_index INTEGER NOT NULL DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_note_sections_note ON note_sections(note_id);
CREATE INDEX IF NOT EXISTS idx_note_sections_order ON note_sections(note_id, order_index);

-- Section Media
CREATE TABLE IF NOT EXISTS section_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID NOT NULL REFERENCES note_sections(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'diagram')),
  caption TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_section_media_section ON section_media(section_id);

-- Note Comments (for discussion)
CREATE TABLE IF NOT EXISTS note_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id UUID NOT NULL REFERENCES class_notes(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_note_comments_note ON note_comments(note_id);

-- RLS Policies
ALTER TABLE class_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE section_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_comments ENABLE ROW LEVEL SECURITY;

-- Notes policies
CREATE POLICY "Public notes are viewable" ON class_notes FOR SELECT
  USING (
    visibility = 'public' 
    OR author_id = auth.uid()
    OR (visibility = 'class' AND EXISTS(
      SELECT 1 FROM class_members WHERE class_id = class_notes.class_id AND user_id = auth.uid()
    ))
  );

CREATE POLICY "Authors can create notes" ON class_notes FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update notes" ON class_notes FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Authors can delete notes" ON class_notes FOR DELETE
  USING (auth.uid() = author_id);

-- Sections policies
CREATE POLICY "Sections viewable with note" ON note_sections FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM class_notes cn WHERE cn.id = note_id AND (
      cn.visibility = 'public' OR cn.author_id = auth.uid()
    )
  ));

CREATE POLICY "Authors can manage sections" ON note_sections FOR ALL
  USING (EXISTS(SELECT 1 FROM class_notes WHERE id = note_id AND author_id = auth.uid()));

-- Media policies
CREATE POLICY "Media viewable with section" ON section_media FOR SELECT USING (true);
CREATE POLICY "Authors can manage media" ON section_media FOR ALL
  USING (EXISTS(
    SELECT 1 FROM note_sections ns 
    JOIN class_notes cn ON ns.note_id = cn.id 
    WHERE ns.id = section_id AND cn.author_id = auth.uid()
  ));

-- Comments policies
CREATE POLICY "Comments viewable on accessible notes" ON note_comments FOR SELECT USING (true);
CREATE POLICY "Users can comment" ON note_comments FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Authors can delete own comments" ON note_comments FOR DELETE USING (auth.uid() = author_id);
