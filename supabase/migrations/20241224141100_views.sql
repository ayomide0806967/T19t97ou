-- ============================================================================
-- Migration 011: Database Views
-- Denormalized views for efficient queries
-- ============================================================================

-- Feed Posts View (denormalized for efficient feed queries)
CREATE OR REPLACE VIEW feed_posts_view AS
SELECT 
  p.id,
  p.author_id,
  pr.handle,
  pr.full_name as author,
  pr.avatar_url,
  p.body,
  p.tags,
  p.visibility,
  p.class_id,
  p.quote_id,
  p.reply_to_id,
  p.created_at,
  p.updated_at,
  
  -- Engagement counts
  (SELECT COUNT(*) FROM post_comments WHERE post_id = p.id) as reply_count,
  (SELECT COUNT(*) FROM post_reposts WHERE post_id = p.id) as repost_count,
  (SELECT COUNT(*) FROM post_likes WHERE post_id = p.id) as like_count,
  (SELECT COUNT(*) FROM post_bookmarks WHERE post_id = p.id) as bookmark_count,
  
  -- Media
  COALESCE(
    ARRAY(SELECT media_url FROM post_media WHERE post_id = p.id ORDER BY order_index),
    '{}'::TEXT[]
  ) as media_urls,
  
  -- Quoted post info (if quote tweet)
  (
    SELECT jsonb_build_object(
      'id', qp.id,
      'author', qpr.full_name,
      'handle', qpr.handle,
      'body', qp.body,
      'created_at', qp.created_at
    )
    FROM posts qp
    JOIN profiles qpr ON qp.author_id = qpr.id
    WHERE qp.id = p.quote_id
  ) as quoted_post
  
FROM posts p
JOIN profiles pr ON p.author_id = pr.id
WHERE p.deleted_at IS NULL
ORDER BY p.created_at DESC;

-- Quiz Results Summary View
CREATE OR REPLACE VIEW quiz_results_view AS
SELECT 
  q.id as quiz_id,
  q.author_id,
  q.title,
  q.status,
  q.class_id,
  
  -- Question count
  (SELECT COUNT(*) FROM quiz_questions WHERE quiz_id = q.id) as question_count,
  
  -- Attempt statistics
  COUNT(DISTINCT qa.id) as total_attempts,
  COUNT(DISTINCT qa.id) FILTER (WHERE qa.status = 'submitted') as completed_count,
  COUNT(DISTINCT qa.id) FILTER (WHERE qa.status = 'in_progress') as in_progress_count,
  
  -- Score statistics
  ROUND(AVG(qa.score_percentage) FILTER (WHERE qa.status = 'submitted'), 2) as average_score,
  ROUND(MIN(qa.score_percentage) FILTER (WHERE qa.status = 'submitted'), 2) as min_score,
  ROUND(MAX(qa.score_percentage) FILTER (WHERE qa.status = 'submitted'), 2) as max_score,
  
  -- Timing
  q.created_at,
  q.published_at,
  MAX(qa.submitted_at) as last_submission
  
FROM quizzes q
LEFT JOIN quiz_attempts qa ON q.id = qa.quiz_id
GROUP BY q.id;

-- Live Quiz Participants View (for real-time monitoring)
CREATE OR REPLACE VIEW quiz_live_participants AS
SELECT 
  qa.id as attempt_id,
  qa.quiz_id,
  qa.user_id,
  pr.full_name as participant_name,
  pr.handle,
  pr.avatar_url,
  qa.status,
  qa.current_question_index,
  qa.answered_count,
  (SELECT COUNT(*) FROM quiz_questions WHERE quiz_id = qa.quiz_id) as total_questions,
  qa.started_at,
  qa.last_heartbeat,
  qa.is_flagged,
  qa.flag_reason,
  
  -- Online status (heartbeat within last 30 seconds)
  CASE 
    WHEN qa.status = 'submitted' THEN 'submitted'
    WHEN qa.status = 'terminated' THEN 'terminated'
    WHEN qa.last_heartbeat > NOW() - INTERVAL '30 seconds' THEN 'online'
    WHEN qa.last_heartbeat > NOW() - INTERVAL '2 minutes' THEN 'away'
    ELSE 'offline'
  END as online_status
  
FROM quiz_attempts qa
JOIN profiles pr ON qa.user_id = pr.id;

-- User Profile Stats View
CREATE OR REPLACE VIEW profile_stats AS
SELECT 
  p.id as user_id,
  p.handle,
  p.full_name,
  
  -- Social stats
  (SELECT COUNT(*) FROM follows WHERE following_id = p.id) as follower_count,
  (SELECT COUNT(*) FROM follows WHERE follower_id = p.id) as following_count,
  
  -- Content stats
  (SELECT COUNT(*) FROM posts WHERE author_id = p.id AND deleted_at IS NULL) as post_count,
  (SELECT COUNT(*) FROM post_likes pl JOIN posts po ON pl.post_id = po.id WHERE po.author_id = p.id) as total_likes_received,
  
  -- Quiz stats
  (SELECT COUNT(*) FROM quizzes WHERE author_id = p.id) as quizzes_created,
  (SELECT COUNT(*) FROM quiz_attempts WHERE user_id = p.id AND status = 'submitted') as quizzes_completed,
  
  -- Class stats
  (SELECT COUNT(*) FROM class_members WHERE user_id = p.id) as classes_joined
  
FROM profiles p;

-- Class Overview View
CREATE OR REPLACE VIEW class_overview AS
SELECT 
  c.id,
  c.code,
  c.name,
  c.description,
  c.delivery_mode,
  c.is_public,
  c.facilitator_id,
  fac.full_name as facilitator_name,
  fac.avatar_url as facilitator_avatar,
  
  -- Member count
  (SELECT COUNT(*) FROM class_members WHERE class_id = c.id) as member_count,
  
  -- Content counts
  (SELECT COUNT(*) FROM class_topics WHERE class_id = c.id) as topic_count,
  (SELECT COUNT(*) FROM class_resources WHERE class_id = c.id) as resource_count,
  (SELECT COUNT(*) FROM class_notes WHERE class_id = c.id) as note_count,
  (SELECT COUNT(*) FROM quizzes WHERE class_id = c.id AND status = 'published') as quiz_count,
  
  c.created_at
  
FROM classes c
LEFT JOIN profiles fac ON c.facilitator_id = fac.id
WHERE c.archived_at IS NULL;
