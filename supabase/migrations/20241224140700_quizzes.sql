-- ============================================================================
-- Migration 007: Quizzes Refactor
-- Core quiz structure with enhanced features
-- ============================================================================

CREATE TABLE IF NOT EXISTS quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
  
  -- Basic info
  title TEXT NOT NULL,
  description TEXT,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'closed', 'archived')),
  
  -- Timing
  is_timed BOOLEAN NOT NULL DEFAULT false,
  timer_minutes INTEGER,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  
  -- Access control
  require_pin BOOLEAN NOT NULL DEFAULT false,
  pin TEXT,
  visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'class', 'invite')),
  
  -- Quiz settings
  shuffle_questions BOOLEAN NOT NULL DEFAULT false,
  shuffle_options BOOLEAN NOT NULL DEFAULT false,
  show_correct_answers BOOLEAN NOT NULL DEFAULT true,
  show_correct_answers_after TEXT DEFAULT 'immediately' CHECK (show_correct_answers_after IN ('immediately', 'after_submit', 'after_close', 'never')),
  allow_review BOOLEAN NOT NULL DEFAULT true,
  max_attempts INTEGER DEFAULT 1,
  passing_score_percentage INTEGER,
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_quizzes_author ON quizzes(author_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_class ON quizzes(class_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_status ON quizzes(status);
CREATE INDEX IF NOT EXISTS idx_quizzes_published ON quizzes(published_at DESC) WHERE status = 'published';

CREATE TRIGGER update_quizzes_updated_at
  BEFORE UPDATE ON quizzes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Quiz Questions
CREATE TABLE IF NOT EXISTS quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  
  -- Question content
  question_type TEXT NOT NULL DEFAULT 'multiple_choice' CHECK (question_type IN ('multiple_choice', 'true_false', 'short_answer', 'multi_select')),
  prompt TEXT NOT NULL,
  prompt_image_url TEXT,
  
  -- Options stored as JSONB array: [{text: "...", image_url: "...", is_correct: true/false}, ...]
  options JSONB NOT NULL DEFAULT '[]',
  
  -- For short answer questions
  correct_answer_text TEXT,
  
  -- Explanation shown after answering
  explanation TEXT,
  
  -- Scoring
  points INTEGER NOT NULL DEFAULT 1,
  
  -- Ordering
  order_index INTEGER NOT NULL DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quiz_questions_quiz ON quiz_questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_questions_order ON quiz_questions(quiz_id, order_index);

-- RLS Policies
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;

-- Quiz visibility policies
CREATE POLICY "Published quizzes are viewable" ON quizzes FOR SELECT
  USING (
    status = 'published' AND visibility = 'public'
    OR author_id = auth.uid()
    OR (visibility = 'class' AND EXISTS(
      SELECT 1 FROM class_members WHERE class_id = quizzes.class_id AND user_id = auth.uid()
    ))
  );

CREATE POLICY "Authors can manage quizzes" ON quizzes FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update quizzes" ON quizzes FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Authors can delete quizzes" ON quizzes FOR DELETE
  USING (auth.uid() = author_id);

-- Questions visible with quiz access
CREATE POLICY "Questions viewable with quiz access" ON quiz_questions FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM quizzes q 
    WHERE q.id = quiz_id AND (
      q.author_id = auth.uid()
      OR (q.status = 'published' AND (
        q.visibility = 'public'
        OR (q.visibility = 'class' AND EXISTS(
          SELECT 1 FROM class_members WHERE class_id = q.class_id AND user_id = auth.uid()
        ))
      ))
    )
  ));

CREATE POLICY "Authors can manage questions" ON quiz_questions FOR INSERT
  WITH CHECK (EXISTS(SELECT 1 FROM quizzes WHERE id = quiz_id AND author_id = auth.uid()));

CREATE POLICY "Authors can update questions" ON quiz_questions FOR UPDATE
  USING (EXISTS(SELECT 1 FROM quizzes WHERE id = quiz_id AND author_id = auth.uid()));

CREATE POLICY "Authors can delete questions" ON quiz_questions FOR DELETE
  USING (EXISTS(SELECT 1 FROM quizzes WHERE id = quiz_id AND author_id = auth.uid()));

-- Helper function to get question count
CREATE OR REPLACE FUNCTION get_quiz_question_count(p_quiz_id UUID)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER FROM quiz_questions WHERE quiz_id = p_quiz_id;
$$ LANGUAGE SQL STABLE;

-- Helper function to publish quiz
CREATE OR REPLACE FUNCTION publish_quiz(p_quiz_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE quizzes 
  SET status = 'published', published_at = NOW()
  WHERE id = p_quiz_id AND author_id = auth.uid() AND status = 'draft';
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
