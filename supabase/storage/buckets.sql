-- ============================================================================
-- Storage Bucket Configuration
-- Run this in Supabase Dashboard > Storage > Create Bucket
-- Or via SQL API
-- ============================================================================

-- Note: Storage buckets are typically created via Dashboard or API
-- This file documents the bucket configuration

-- ============================================================================
-- Bucket: avatars
-- Purpose: User profile avatars and header images
-- ============================================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

-- RLS Policies for avatars bucket:
-- CREATE POLICY "Avatar images are publicly accessible"
--   ON storage.objects FOR SELECT
--   USING (bucket_id = 'avatars');

-- CREATE POLICY "Users can upload their own avatar"
--   ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- CREATE POLICY "Users can update their own avatar"
--   ON storage.objects FOR UPDATE
--   USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- CREATE POLICY "Users can delete their own avatar"
--   ON storage.objects FOR DELETE
--   USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ============================================================================
-- Bucket: post-media
-- Purpose: Images, videos, GIFs attached to posts
-- ============================================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('post-media', 'post-media', true);

-- RLS Policies for post-media bucket:
-- CREATE POLICY "Post media is publicly accessible"
--   ON storage.objects FOR SELECT
--   USING (bucket_id = 'post-media');

-- CREATE POLICY "Authenticated users can upload post media"
--   ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'post-media' AND auth.role() = 'authenticated');

-- CREATE POLICY "Users can delete their own media"
--   ON storage.objects FOR DELETE
--   USING (bucket_id = 'post-media' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ============================================================================
-- Bucket: class-resources
-- Purpose: PDFs, documents, videos for class resources
-- ============================================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('class-resources', 'class-resources', false);

-- RLS Policies for class-resources bucket (private, requires auth):
-- CREATE POLICY "Class members can view resources"
--   ON storage.objects FOR SELECT
--   USING (
--     bucket_id = 'class-resources' 
--     AND EXISTS(
--       SELECT 1 FROM class_members cm
--       WHERE cm.user_id = auth.uid()
--       AND cm.class_id::text = (storage.foldername(name))[1]
--     )
--   );

-- CREATE POLICY "Class admins can upload resources"
--   ON storage.objects FOR INSERT
--   WITH CHECK (
--     bucket_id = 'class-resources'
--     AND EXISTS(
--       SELECT 1 FROM class_members cm
--       WHERE cm.user_id = auth.uid()
--       AND cm.class_id::text = (storage.foldername(name))[1]
--       AND cm.role IN ('admin', 'facilitator', 'ta')
--     )
--   );

-- ============================================================================
-- Bucket: quiz-media
-- Purpose: Images for quiz questions and options
-- ============================================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('quiz-media', 'quiz-media', true);

-- RLS Policies for quiz-media:
-- CREATE POLICY "Quiz media is publicly accessible"
--   ON storage.objects FOR SELECT
--   USING (bucket_id = 'quiz-media');

-- CREATE POLICY "Quiz authors can upload media"
--   ON storage.objects FOR INSERT
--   WITH CHECK (
--     bucket_id = 'quiz-media'
--     AND auth.role() = 'authenticated'
--   );

-- ============================================================================
-- Bucket: note-media
-- Purpose: Images and diagrams for class notes
-- ============================================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('note-media', 'note-media', true);

-- Similar policies as quiz-media
