-- ============================================================================
-- Migration 005: Classes Refactor
-- Classes and membership management
-- ============================================================================

CREATE TABLE IF NOT EXISTS classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL, -- Enrollment code like "NUR301"
  name TEXT NOT NULL,
  description TEXT,
  facilitator_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  delivery_mode TEXT DEFAULT 'online' CHECK (delivery_mode IN ('online', 'hybrid', 'in-person')),
  is_public BOOLEAN NOT NULL DEFAULT true,
  settings JSONB DEFAULT '{}', -- Flexible settings storage
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ -- Soft archive
);

CREATE INDEX IF NOT EXISTS idx_classes_code ON classes(code);
CREATE INDEX IF NOT EXISTS idx_classes_facilitator ON classes(facilitator_id);
CREATE INDEX IF NOT EXISTS idx_classes_is_public ON classes(is_public) WHERE is_public = true;

CREATE TRIGGER update_classes_updated_at
  BEFORE UPDATE ON classes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add FK from posts to classes now that classes table exists
ALTER TABLE posts ADD CONSTRAINT fk_posts_class 
  FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL;

-- Class Members (normalized from class_memberships)
CREATE TABLE IF NOT EXISTS class_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin', 'facilitator', 'ta')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT unique_class_member UNIQUE (class_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_class_members_class ON class_members(class_id);
CREATE INDEX IF NOT EXISTS idx_class_members_user ON class_members(user_id);
CREATE INDEX IF NOT EXISTS idx_class_members_role ON class_members(role);

-- Class Invites (keep existing structure, ensure exists)
CREATE TABLE IF NOT EXISTS class_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_code TEXT NOT NULL REFERENCES classes(code) ON DELETE CASCADE,
  invite_code TEXT UNIQUE NOT NULL,
  created_by UUID REFERENCES profiles(id),
  expires_at TIMESTAMPTZ,
  max_uses INTEGER,
  use_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_class_invites_invite_code ON class_invites(invite_code);

-- RLS Policies
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_invites ENABLE ROW LEVEL SECURITY;

-- Classes policies
CREATE POLICY "Public classes are viewable" ON classes FOR SELECT
  USING (is_public = true OR facilitator_id = auth.uid() OR EXISTS(
    SELECT 1 FROM class_members WHERE class_id = id AND user_id = auth.uid()
  ));

CREATE POLICY "Facilitators can create classes" ON classes FOR INSERT
  WITH CHECK (auth.uid() = facilitator_id);

CREATE POLICY "Facilitators can update own classes" ON classes FOR UPDATE
  USING (auth.uid() = facilitator_id);

-- Class members policies
CREATE POLICY "Members viewable within class" ON class_members FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM class_members cm WHERE cm.class_id = class_id AND cm.user_id = auth.uid()
  ) OR EXISTS(
    SELECT 1 FROM classes c WHERE c.id = class_id AND c.facilitator_id = auth.uid()
  ));

CREATE POLICY "Admins can manage members" ON class_members FOR INSERT
  WITH CHECK (EXISTS(
    SELECT 1 FROM class_members WHERE class_id = class_members.class_id AND user_id = auth.uid() AND role IN ('admin', 'facilitator')
  ) OR EXISTS(
    SELECT 1 FROM classes WHERE id = class_id AND facilitator_id = auth.uid()
  ));

CREATE POLICY "Members can leave" ON class_members FOR DELETE
  USING (user_id = auth.uid());

-- Invite policies
CREATE POLICY "Invites viewable by class admins" ON class_invites FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM classes c 
    JOIN class_members cm ON c.id = cm.class_id
    WHERE c.code = class_code AND cm.user_id = auth.uid() AND cm.role IN ('admin', 'facilitator')
  ));

CREATE POLICY "Admins can create invites" ON class_invites FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Helper function to join class via invite code
CREATE OR REPLACE FUNCTION join_class_via_invite(p_invite_code TEXT)
RETURNS UUID AS $$
DECLARE
  v_class_code TEXT;
  v_class_id UUID;
BEGIN
  -- Get class from invite
  SELECT ci.class_code INTO v_class_code
  FROM class_invites ci
  WHERE ci.invite_code = p_invite_code
    AND (ci.expires_at IS NULL OR ci.expires_at > NOW())
    AND (ci.max_uses IS NULL OR ci.use_count < ci.max_uses);
  
  IF v_class_code IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired invite code';
  END IF;
  
  SELECT id INTO v_class_id FROM classes WHERE code = v_class_code;
  
  -- Add member
  INSERT INTO class_members (class_id, user_id, role)
  VALUES (v_class_id, auth.uid(), 'student')
  ON CONFLICT (class_id, user_id) DO NOTHING;
  
  -- Increment use count
  UPDATE class_invites SET use_count = use_count + 1 WHERE invite_code = p_invite_code;
  
  RETURN v_class_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
