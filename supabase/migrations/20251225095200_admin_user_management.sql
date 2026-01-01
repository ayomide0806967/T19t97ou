-- Admin Panel Enhanced User Management
-- Migration: Add profile fields for verification, banning, and boosting
-- Also adds admin_user_notes table for internal notes

-- ========================================
-- Profile Enhancements
-- ========================================

-- Verification fields
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verified_type text DEFAULT 'none' 
  CHECK (verified_type IN ('none', 'verified', 'institution', 'creator'));
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verified_at timestamptz;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verified_by uuid REFERENCES auth.users(id);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verified_expires_at timestamptz;

-- Ban/Lock fields  
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_locked boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS locked_reason text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS locked_at timestamptz;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS locked_until timestamptz;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS locked_by uuid REFERENCES auth.users(id);

-- Boost fields
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS boost_multiplier numeric(3,1) DEFAULT 1.0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS boost_expires_at timestamptz;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS boosted_by uuid REFERENCES auth.users(id);

-- Create index for quick lookups
CREATE INDEX IF NOT EXISTS idx_profiles_verified_type ON profiles(verified_type) WHERE verified_type != 'none';
CREATE INDEX IF NOT EXISTS idx_profiles_is_locked ON profiles(is_locked) WHERE is_locked = true;
CREATE INDEX IF NOT EXISTS idx_profiles_boosted ON profiles(boost_multiplier) WHERE boost_multiplier > 1;

-- ========================================
-- Admin User Notes Table
-- ========================================

CREATE TABLE IF NOT EXISTS admin_user_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES auth.users(id),
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Index for quick lookup by user
CREATE INDEX IF NOT EXISTS idx_admin_user_notes_user ON admin_user_notes(user_id);

-- RLS Policies for admin_user_notes
ALTER TABLE admin_user_notes ENABLE ROW LEVEL SECURITY;

-- Only admins can view notes
CREATE POLICY "Admins can view user notes"
  ON admin_user_notes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = true
    )
  );

-- Only admins can insert notes
CREATE POLICY "Admins can add user notes"
  ON admin_user_notes FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = true
    )
  );

-- Only note author or super_admin can delete
CREATE POLICY "Admins can delete own notes"
  ON admin_user_notes FOR DELETE
  TO authenticated
  USING (
    author_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.role = 'super_admin'
      AND admin_users.is_active = true
    )
  );

-- ========================================
-- Helper Function: Check if user is banned
-- ========================================

CREATE OR REPLACE FUNCTION is_user_banned(user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  profile_record RECORD;
BEGIN
  SELECT is_locked, locked_until
  INTO profile_record
  FROM profiles
  WHERE id = user_uuid;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Not locked
  IF NOT profile_record.is_locked THEN
    RETURN false;
  END IF;
  
  -- Permanently locked
  IF profile_record.locked_until IS NULL THEN
    RETURN true;
  END IF;
  
  -- Check if temporary lock has expired
  IF profile_record.locked_until < now() THEN
    -- Auto-unban if lock expired
    UPDATE profiles 
    SET is_locked = false, locked_reason = NULL, locked_at = NULL, 
        locked_until = NULL, locked_by = NULL
    WHERE id = user_uuid;
    RETURN false;
  END IF;
  
  RETURN true;
END;
$$;

-- ========================================
-- Helper Function: Get effective boost multiplier
-- ========================================

CREATE OR REPLACE FUNCTION get_user_boost(user_uuid uuid)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  profile_record RECORD;
BEGIN
  SELECT boost_multiplier, boost_expires_at
  INTO profile_record
  FROM profiles
  WHERE id = user_uuid;
  
  IF NOT FOUND THEN
    RETURN 1.0;
  END IF;
  
  -- No boost
  IF profile_record.boost_multiplier IS NULL OR profile_record.boost_multiplier <= 1 THEN
    RETURN 1.0;
  END IF;
  
  -- Permanent boost
  IF profile_record.boost_expires_at IS NULL THEN
    RETURN profile_record.boost_multiplier;
  END IF;
  
  -- Check if boost expired
  IF profile_record.boost_expires_at < now() THEN
    -- Auto-remove expired boost
    UPDATE profiles 
    SET boost_multiplier = 1.0, boost_expires_at = NULL, boosted_by = NULL
    WHERE id = user_uuid;
    RETURN 1.0;
  END IF;
  
  RETURN profile_record.boost_multiplier;
END;
$$;

-- ========================================
-- Helper Function: Get effective verification type
-- ========================================

CREATE OR REPLACE FUNCTION get_user_verification(user_uuid uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  profile_record RECORD;
BEGIN
  SELECT verified_type, verified_expires_at
  INTO profile_record
  FROM profiles
  WHERE id = user_uuid;
  
  IF NOT FOUND THEN
    RETURN 'none';
  END IF;
  
  -- Not verified
  IF profile_record.verified_type IS NULL OR profile_record.verified_type = 'none' THEN
    RETURN 'none';
  END IF;
  
  -- Permanent verification
  IF profile_record.verified_expires_at IS NULL THEN
    RETURN profile_record.verified_type;
  END IF;
  
  -- Check if verification expired
  IF profile_record.verified_expires_at < now() THEN
    -- Auto-remove expired verification
    UPDATE profiles 
    SET verified_type = 'none', verified_at = NULL, verified_by = NULL, verified_expires_at = NULL
    WHERE id = user_uuid;
    RETURN 'none';
  END IF;
  
  RETURN profile_record.verified_type;
END;
$$;

-- ========================================
-- Comment for documentation
-- ========================================

COMMENT ON COLUMN profiles.verified_type IS 'User verification badge type: none, verified, institution, creator';
COMMENT ON COLUMN profiles.verified_expires_at IS 'When the verification expires (null = permanent)';
COMMENT ON COLUMN profiles.is_locked IS 'Whether user account is banned/locked';
COMMENT ON COLUMN profiles.boost_multiplier IS 'Feed visibility boost multiplier (1.0-5.0)';
COMMENT ON TABLE admin_user_notes IS 'Internal admin notes about users, not visible to the user';
