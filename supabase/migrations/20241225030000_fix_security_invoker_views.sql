-- ============================================================================
-- Migration 015: Fix Security Definer Views
-- Changes views to use SECURITY INVOKER to respect RLS policies
-- ============================================================================

-- Fix feed_posts_view - should respect post visibility RLS
ALTER VIEW feed_posts_view SET (security_invoker = on);

-- Fix quiz_results_view - should respect quiz access RLS
ALTER VIEW quiz_results_view SET (security_invoker = on);

-- Fix quiz_live_participants - should respect quiz access RLS
ALTER VIEW quiz_live_participants SET (security_invoker = on);

-- Fix profile_stats - should respect profile visibility
ALTER VIEW profile_stats SET (security_invoker = on);

-- Fix class_overview - should respect class visibility RLS
ALTER VIEW class_overview SET (security_invoker = on);
