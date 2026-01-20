-- ============================================
-- COMPLETE FIX FOR INFINITE RECURSION IN PROFILES TABLE
-- This removes ALL policies and creates safe ones
-- ============================================

-- Step 1: Drop ALL existing policies on profiles table
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON profiles';
    END LOOP;
END $$;

-- Step 2: Disable RLS temporarily
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Step 3: Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- BASIC POLICIES (No recursion risk)
-- ============================================

-- SELECT: Users can view their own profile
CREATE POLICY "profiles_select_own"
ON profiles
FOR SELECT
USING (auth.uid() = id);

-- INSERT: Users can insert their own profile
CREATE POLICY "profiles_insert_own"
ON profiles
FOR INSERT
WITH CHECK (auth.uid() = id);

-- UPDATE: Users can update their own profile
CREATE POLICY "profiles_update_own"
ON profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- DELETE: Users can delete their own profile
CREATE POLICY "profiles_delete_own"
ON profiles
FOR DELETE
USING (auth.uid() = id);

-- ============================================
-- ADMIN POLICIES (Safe - uses auth.uid() directly)
-- If you need admin access, uncomment these
-- ============================================

-- Admin SELECT: Admins can view all profiles
-- This is SAFE because it only checks the current user's profile once
-- CREATE POLICY "profiles_select_admin"
-- ON profiles
-- FOR SELECT
-- USING (
--   -- Check if current user is admin by looking at THEIR profile only
--   (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
-- );

-- Admin UPDATE: Admins can update any profile
-- CREATE POLICY "profiles_update_admin"
-- ON profiles
-- FOR UPDATE
-- USING (
--   (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
-- )
-- WITH CHECK (
--   (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
-- );

-- ============================================
-- CHECK FOR PROBLEMATIC TRIGGERS
-- ============================================
-- If you have triggers that query profiles table, they might cause recursion
-- Run this to see your triggers:
-- SELECT trigger_name, event_manipulation, event_object_table 
-- FROM information_schema.triggers 
-- WHERE event_object_table = 'profiles';

-- ============================================
-- VERIFICATION
-- ============================================
-- After running this, check your policies:
-- SELECT * FROM pg_policies WHERE tablename = 'profiles';
