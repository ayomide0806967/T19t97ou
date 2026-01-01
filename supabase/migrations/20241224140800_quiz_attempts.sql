-- ============================================================================
-- Migration 008: Quiz Attempts (Real-time + Offline Sync)
-- Live tracking of quiz progress and offline sync support
-- ============================================================================

-- Quiz Attempts - Real-time tracked for live monitoring
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Attempt tracking
  attempt_number INTEGER NOT NULL DEFAULT 1,
  
  -- Status for live monitoring
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted', 'timed_out', 'terminated', 'paused')),
  
  -- Progress (real-time updated)
  current_question_index INTEGER NOT NULL DEFAULT 0,
  answered_count INTEGER NOT NULL DEFAULT 0,
  
  -- Timing
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  time_remaining_seconds INTEGER,
  
  -- Results (calculated on submit)
  score DECIMAL(10,2),
  score_percentage DECIMAL(5,2),
  total_points INTEGER,
  earned_points DECIMAL(10,2),
  
  -- Anti-cheat / monitoring
  is_flagged BOOLEAN NOT NULL DEFAULT false,
  flag_reason TEXT,
  last_heartbeat TIMESTAMPTZ DEFAULT NOW(),
  
  -- Device info for debugging/security
  device_info JSONB DEFAULT '{}',
  
  -- Offline sync support
  sync_version INTEGER NOT NULL DEFAULT 1,
  last_synced_at TIMESTAMPTZ,
  local_attempt_id TEXT, -- For matching offline attempts
  
  CONSTRAINT unique_quiz_attempt UNIQUE (quiz_id, user_id, attempt_number)
);

CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz ON quiz_attempts(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user ON quiz_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_status ON quiz_attempts(status);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_heartbeat ON quiz_attempts(last_heartbeat) WHERE status = 'in_progress';

-- Quiz Responses - Individual question answers
CREATE TABLE IF NOT EXISTS quiz_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id UUID NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
  
  -- Response data
  selected_option_index INTEGER, -- For single select
  selected_options INTEGER[], -- For multi-select
  text_answer TEXT, -- For short answer
  
  -- Grading
  is_correct BOOLEAN,
  points_earned DECIMAL(5,2) NOT NULL DEFAULT 0,
  
  -- Timing
  answered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  time_spent_seconds INTEGER,
  
  -- Offline sync support
  local_response_id TEXT, -- For deduplication during sync
  synced_at TIMESTAMPTZ,
  
  CONSTRAINT unique_quiz_response UNIQUE (attempt_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_quiz_responses_attempt ON quiz_responses(attempt_id);
CREATE INDEX IF NOT EXISTS idx_quiz_responses_question ON quiz_responses(question_id);

-- RLS Policies
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_responses ENABLE ROW LEVEL SECURITY;

-- Users can see own attempts
CREATE POLICY "Users see own attempts" ON quiz_attempts FOR SELECT
  USING (user_id = auth.uid());

-- Quiz authors can monitor all attempts
CREATE POLICY "Authors can monitor attempts" ON quiz_attempts FOR SELECT
  USING (EXISTS(SELECT 1 FROM quizzes WHERE id = quiz_id AND author_id = auth.uid()));

-- Users can create attempts
CREATE POLICY "Users can start attempts" ON quiz_attempts FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update own in-progress attempts
CREATE POLICY "Users can update own attempts" ON quiz_attempts FOR UPDATE
  USING (user_id = auth.uid() AND status IN ('in_progress', 'paused'));

-- Response policies
CREATE POLICY "Users see own responses" ON quiz_responses FOR SELECT
  USING (EXISTS(SELECT 1 FROM quiz_attempts WHERE id = attempt_id AND user_id = auth.uid()));

CREATE POLICY "Authors see all responses" ON quiz_responses FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM quiz_attempts qa 
    JOIN quizzes q ON qa.quiz_id = q.id 
    WHERE qa.id = attempt_id AND q.author_id = auth.uid()
  ));

CREATE POLICY "Users can add responses" ON quiz_responses FOR INSERT
  WITH CHECK (EXISTS(
    SELECT 1 FROM quiz_attempts 
    WHERE id = attempt_id AND user_id = auth.uid() AND status = 'in_progress'
  ));

CREATE POLICY "Users can update responses" ON quiz_responses FOR UPDATE
  USING (EXISTS(
    SELECT 1 FROM quiz_attempts 
    WHERE id = attempt_id AND user_id = auth.uid() AND status = 'in_progress'
  ));

-- Function to update heartbeat (for live monitoring)
CREATE OR REPLACE FUNCTION update_attempt_heartbeat(p_attempt_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE quiz_attempts 
  SET last_heartbeat = NOW()
  WHERE id = p_attempt_id AND user_id = auth.uid() AND status = 'in_progress';
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to submit quiz attempt
CREATE OR REPLACE FUNCTION submit_quiz_attempt(p_attempt_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_total_points INTEGER;
  v_earned_points DECIMAL(10,2);
  v_correct_count INTEGER;
  v_question_count INTEGER;
BEGIN
  -- Calculate score
  SELECT 
    COALESCE(SUM(qq.points), 0),
    COALESCE(SUM(qr.points_earned), 0),
    COUNT(qr.id) FILTER (WHERE qr.is_correct = true),
    COUNT(DISTINCT qq.id)
  INTO v_total_points, v_earned_points, v_correct_count, v_question_count
  FROM quiz_attempts qa
  JOIN quizzes q ON qa.quiz_id = q.id
  JOIN quiz_questions qq ON qq.quiz_id = q.id
  LEFT JOIN quiz_responses qr ON qr.attempt_id = qa.id AND qr.question_id = qq.id
  WHERE qa.id = p_attempt_id AND qa.user_id = auth.uid();
  
  -- Update attempt
  UPDATE quiz_attempts SET
    status = 'submitted',
    submitted_at = NOW(),
    total_points = v_total_points,
    earned_points = v_earned_points,
    score = v_earned_points,
    score_percentage = CASE WHEN v_total_points > 0 THEN (v_earned_points / v_total_points * 100) ELSE 0 END,
    answered_count = v_question_count
  WHERE id = p_attempt_id AND user_id = auth.uid() AND status = 'in_progress';
  
  v_result := jsonb_build_object(
    'submitted', FOUND,
    'total_points', v_total_points,
    'earned_points', v_earned_points,
    'correct_count', v_correct_count,
    'question_count', v_question_count,
    'percentage', CASE WHEN v_total_points > 0 THEN ROUND(v_earned_points / v_total_points * 100, 2) ELSE 0 END
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to sync offline responses (batch upsert)
CREATE OR REPLACE FUNCTION sync_quiz_responses(
  p_attempt_id UUID,
  p_responses JSONB -- Array of {question_id, selected_option_index, selected_options, text_answer, answered_at, local_response_id, time_spent_seconds}
)
RETURNS JSONB AS $$
DECLARE
  v_response JSONB;
  v_synced_count INTEGER := 0;
  v_question_id UUID;
  v_is_correct BOOLEAN;
  v_points DECIMAL(5,2);
  v_options JSONB;
  v_correct_index INTEGER;
BEGIN
  -- Verify attempt belongs to user and is in progress
  IF NOT EXISTS(SELECT 1 FROM quiz_attempts WHERE id = p_attempt_id AND user_id = auth.uid() AND status = 'in_progress') THEN
    RETURN jsonb_build_object('error', 'Invalid or completed attempt');
  END IF;
  
  FOR v_response IN SELECT * FROM jsonb_array_elements(p_responses)
  LOOP
    v_question_id := (v_response->>'question_id')::UUID;
    
    -- Get correct answer for grading
    SELECT options, 
           (SELECT (elem->>'is_correct')::BOOLEAN FROM jsonb_array_elements(options) WITH ORDINALITY AS arr(elem, idx) WHERE (elem->>'is_correct')::BOOLEAN = true LIMIT 1) as is_any_correct,
           (SELECT idx - 1 FROM jsonb_array_elements(options) WITH ORDINALITY AS arr(elem, idx) WHERE (elem->>'is_correct')::BOOLEAN = true LIMIT 1) as correct_idx,
           points
    INTO v_options, v_is_correct, v_correct_index, v_points
    FROM quiz_questions WHERE id = v_question_id;
    
    -- Check if answer is correct
    v_is_correct := (v_response->>'selected_option_index')::INTEGER = v_correct_index;
    
    INSERT INTO quiz_responses (
      attempt_id, question_id, selected_option_index, selected_options, text_answer,
      is_correct, points_earned, answered_at, time_spent_seconds, local_response_id, synced_at
    )
    VALUES (
      p_attempt_id,
      v_question_id,
      (v_response->>'selected_option_index')::INTEGER,
      CASE WHEN v_response ? 'selected_options' THEN ARRAY(SELECT jsonb_array_elements_text(v_response->'selected_options')::INTEGER) ELSE NULL END,
      v_response->>'text_answer',
      v_is_correct,
      CASE WHEN v_is_correct THEN v_points ELSE 0 END,
      COALESCE((v_response->>'answered_at')::TIMESTAMPTZ, NOW()),
      (v_response->>'time_spent_seconds')::INTEGER,
      v_response->>'local_response_id',
      NOW()
    )
    ON CONFLICT (attempt_id, question_id) 
    DO UPDATE SET
      selected_option_index = EXCLUDED.selected_option_index,
      selected_options = EXCLUDED.selected_options,
      text_answer = EXCLUDED.text_answer,
      is_correct = EXCLUDED.is_correct,
      points_earned = EXCLUDED.points_earned,
      answered_at = EXCLUDED.answered_at,
      time_spent_seconds = EXCLUDED.time_spent_seconds,
      synced_at = NOW();
    
    v_synced_count := v_synced_count + 1;
  END LOOP;
  
  -- Update attempt sync version and answered count
  UPDATE quiz_attempts 
  SET 
    sync_version = sync_version + 1,
    last_synced_at = NOW(),
    answered_count = (SELECT COUNT(*) FROM quiz_responses WHERE attempt_id = p_attempt_id)
  WHERE id = p_attempt_id;
  
  RETURN jsonb_build_object('synced', v_synced_count, 'sync_version', (SELECT sync_version FROM quiz_attempts WHERE id = p_attempt_id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
