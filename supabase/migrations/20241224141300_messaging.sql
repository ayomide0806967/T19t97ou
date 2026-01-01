-- ============================================================================
-- Migration 013: Direct Messaging
-- User-to-user private messaging
-- ============================================================================

-- Conversations (one-on-one or group)
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
  
  -- For group conversations
  name TEXT,
  avatar_url TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE TRIGGER update_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Conversation Participants
CREATE TABLE IF NOT EXISTS conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Participant state
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  last_read_at TIMESTAMPTZ,
  is_muted BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  
  CONSTRAINT unique_conversation_participant UNIQUE (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_conversation_participants_user ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation ON conversation_participants(conversation_id);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Content
  body TEXT NOT NULL,
  
  -- Reply to another message
  reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  
  -- Media attachments (stored as array of URLs)
  media_urls TEXT[] DEFAULT '{}',
  
  -- Status
  is_edited BOOLEAN NOT NULL DEFAULT false,
  edited_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(conversation_id, created_at DESC);

-- Message Read Receipts
CREATE TABLE IF NOT EXISTS message_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT unique_message_read UNIQUE (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_message_reads_message ON message_reads(message_id);

-- RLS Policies
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;

-- Conversations: Only participants can see
CREATE POLICY "Participants can view conversations" ON conversations FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM conversation_participants 
    WHERE conversation_id = id AND user_id = auth.uid() AND left_at IS NULL
  ));

CREATE POLICY "Users can create conversations" ON conversations FOR INSERT
  WITH CHECK (auth.uid() = created_by OR created_by IS NULL);

-- Participants policies
CREATE POLICY "Participants visible to conversation members" ON conversation_participants FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM conversation_participants cp
    WHERE cp.conversation_id = conversation_participants.conversation_id 
    AND cp.user_id = auth.uid() AND cp.left_at IS NULL
  ));

CREATE POLICY "Users can join conversations" ON conversation_participants FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own participation" ON conversation_participants FOR UPDATE
  USING (user_id = auth.uid());

-- Messages visible to conversation participants
CREATE POLICY "Messages visible to participants" ON messages FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM conversation_participants 
    WHERE conversation_id = messages.conversation_id 
    AND user_id = auth.uid() AND left_at IS NULL
  ));

CREATE POLICY "Participants can send messages" ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS(
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = messages.conversation_id 
      AND user_id = auth.uid() AND left_at IS NULL
    )
  );

CREATE POLICY "Senders can edit own messages" ON messages FOR UPDATE
  USING (sender_id = auth.uid());

-- Read receipts
CREATE POLICY "Participants can see read receipts" ON message_reads FOR SELECT
  USING (EXISTS(
    SELECT 1 FROM messages m
    JOIN conversation_participants cp ON m.conversation_id = cp.conversation_id
    WHERE m.id = message_reads.message_id AND cp.user_id = auth.uid()
  ));

CREATE POLICY "Users can mark messages as read" ON message_reads FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Enable realtime for messages
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reads;

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Find or create direct conversation between two users
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(p_other_user_id UUID)
RETURNS UUID AS $$
DECLARE
  v_conversation_id UUID;
BEGIN
  -- Find existing direct conversation
  SELECT cp1.conversation_id INTO v_conversation_id
  FROM conversation_participants cp1
  JOIN conversation_participants cp2 ON cp1.conversation_id = cp2.conversation_id
  JOIN conversations c ON c.id = cp1.conversation_id
  WHERE cp1.user_id = auth.uid() 
    AND cp2.user_id = p_other_user_id
    AND c.type = 'direct'
    AND cp1.left_at IS NULL 
    AND cp2.left_at IS NULL;
  
  IF v_conversation_id IS NOT NULL THEN
    RETURN v_conversation_id;
  END IF;
  
  -- Create new conversation
  INSERT INTO conversations (type, created_by)
  VALUES ('direct', auth.uid())
  RETURNING id INTO v_conversation_id;
  
  -- Add both participants
  INSERT INTO conversation_participants (conversation_id, user_id)
  VALUES 
    (v_conversation_id, auth.uid()),
    (v_conversation_id, p_other_user_id);
  
  RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get unread message count for a user
CREATE OR REPLACE FUNCTION get_unread_message_count(p_user_id UUID DEFAULT NULL)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER
  FROM messages m
  JOIN conversation_participants cp ON m.conversation_id = cp.conversation_id
  WHERE cp.user_id = COALESCE(p_user_id, auth.uid())
    AND cp.left_at IS NULL
    AND m.sender_id != COALESCE(p_user_id, auth.uid())
    AND m.created_at > COALESCE(cp.last_read_at, '1970-01-01'::timestamptz)
    AND m.deleted_at IS NULL;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Create notification on new message
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  v_participant RECORD;
  v_sender_name TEXT;
BEGIN
  SELECT full_name INTO v_sender_name FROM profiles WHERE id = NEW.sender_id;
  
  -- Notify all other participants
  FOR v_participant IN 
    SELECT user_id FROM conversation_participants 
    WHERE conversation_id = NEW.conversation_id 
    AND user_id != NEW.sender_id 
    AND left_at IS NULL
  LOOP
    INSERT INTO notifications (user_id, type, actor_id, target_type, target_id, title, body)
    VALUES (
      v_participant.user_id, 
      'message', 
      NEW.sender_id, 
      'conversation', 
      NEW.conversation_id,
      'New message from ' || v_sender_name,
      LEFT(NEW.body, 100)
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_message();
