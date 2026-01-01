-- ============================================================================
-- Seed Data for Development
-- Sample data to test the application
-- ============================================================================

-- Note: Replace UUIDs with actual auth.users IDs after creating test accounts

-- ============================================================================
-- Sample Profiles (run after creating auth users)
-- ============================================================================

-- These will be auto-created by the trigger, but you can update them:
-- UPDATE profiles SET
--   full_name = 'Dr. Sarah Johnson',
--   bio = 'Clinical Educator | Nursing & Midwifery',
--   profession = 'Senior Lecturer',
--   handle = '@dr_sarah'
-- WHERE id = 'your-user-uuid-here';

-- ============================================================================
-- Sample Classes
-- ============================================================================

INSERT INTO classes (id, code, name, description, delivery_mode, is_public) VALUES
  ('11111111-1111-1111-1111-111111111111', 'NUR301', 'Advanced Nursing Practice', 'Third year nursing core module covering advanced clinical skills and patient care.', 'hybrid', true),
  ('22222222-2222-2222-2222-222222222222', 'MID201', 'Midwifery Fundamentals', 'Introduction to midwifery care and maternal health.', 'online', true),
  ('33333333-3333-3333-3333-333333333333', 'PHY101', 'Human Physiology', 'Foundation course in human body systems and functions.', 'in-person', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Sample Class Topics
-- ============================================================================

INSERT INTO class_topics (class_id, title, description, order_index) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Medication Administration', 'Safe practices for drug administration', 1),
  ('11111111-1111-1111-1111-111111111111', 'Patient Assessment', 'Comprehensive patient evaluation techniques', 2),
  ('11111111-1111-1111-1111-111111111111', 'Documentation Standards', 'Legal and ethical documentation practices', 3),
  ('22222222-2222-2222-2222-222222222222', 'Prenatal Care', 'Caring for expectant mothers', 1),
  ('22222222-2222-2222-2222-222222222222', 'Labor and Delivery', 'Supporting natural birth', 2);

-- ============================================================================
-- Sample Invite Codes
-- ============================================================================

INSERT INTO class_invites (class_code, invite_code) VALUES
  ('NUR301', 'NURSE2024'),
  ('MID201', 'MIDWIFE2024'),
  ('PHY101', 'PHYSIO2024')
ON CONFLICT (invite_code) DO NOTHING;

-- ============================================================================
-- Sample Quiz (without author_id - add yours)
-- ============================================================================

-- INSERT INTO quizzes (id, author_id, class_id, title, description, status, is_timed, timer_minutes, visibility) VALUES
--   ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'your-user-id', '11111111-1111-1111-1111-111111111111', 
--    'Medication Safety Quiz', 'Test your knowledge of safe medication practices', 'published', true, 15, 'class');

-- INSERT INTO quiz_questions (quiz_id, question_type, prompt, options, order_index, points) VALUES
--   ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'multiple_choice', 
--    'What is the correct procedure for verifying patient identity before medication administration?',
--    '[{"text": "Ask the patient their name", "is_correct": false}, 
--      {"text": "Check ID band and ask patient to state name and DOB", "is_correct": true},
--      {"text": "Check the room number", "is_correct": false},
--      {"text": "Ask a family member", "is_correct": false}]'::jsonb, 1, 1),
--   ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'true_false',
--    'Medications can be administered by any healthcare worker.',
--    '[{"text": "True", "is_correct": false}, {"text": "False", "is_correct": true}]'::jsonb, 2, 1);

-- ============================================================================
-- Utility: Clean up test data
-- ============================================================================

-- To reset test data:
-- DELETE FROM quiz_attempts;
-- DELETE FROM quiz_responses;
-- DELETE FROM quizzes WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
-- DELETE FROM classes WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');
