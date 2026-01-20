-- ============================================
-- SIMPLE, SAFE RLS POLICIES FOR PROFILES TABLE
-- These policies use ONLY auth.uid() - no table queries
-- This prevents infinite recursion
-- ============================================

-- Step 1: Drop ALL existing policies
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON profiles';
    END LOOP;
END $$;

-- Step 2: Make sure RLS is enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- MINIMAL POLICIES (No recursion possible)
-- These use ONLY auth.uid() - never query profiles table
-- ============================================

-- SELECT: Users can only see their own profile
CREATE POLICY "profiles_select"
ON profiles
FOR SELECT
USING (auth.uid() = id);

-- INSERT: Users can only insert their own profile (id must match auth.uid())
CREATE POLICY "profiles_insert"
ON profiles
FOR INSERT
WITH CHECK (auth.uid() = id);

-- UPDATE: Users can only update their own profile
CREATE POLICY "profiles_update"
ON profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- DELETE: Users can only delete their own profile
CREATE POLICY "profiles_delete"
ON profiles
FOR DELETE
USING (auth.uid() = id);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Check policies were created:
-- SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'profiles';

-- Test as current user:
-- SELECT * FROM profiles WHERE id = auth.uid();
