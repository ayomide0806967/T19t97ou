-- ============================================================================
-- Migration 016: Fix Handle Unique Constraint in User Creation
-- Updates handle_new_user() to handle duplicate handles and fix permissions
-- ============================================================================

-- Drop and recreate the function with proper security settings
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_handle TEXT;
  final_handle TEXT;
  suffix INT := 0;
BEGIN
  -- Generate base handle from email
  base_handle := '@' || LOWER(REPLACE(SPLIT_PART(NEW.email, '@', 1), '.', '_'));
  final_handle := base_handle;
  
  -- Keep trying until we find a unique handle
  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE handle = final_handle) LOOP
    suffix := suffix + 1;
    final_handle := base_handle || suffix::TEXT;
  END LOOP;
  
  -- Insert the profile with unique handle
  INSERT INTO public.profiles (id, handle, full_name)
  VALUES (
    NEW.id,
    final_handle,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User')
  );
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail user creation
  RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.profiles TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT ON public.profiles TO anon;
