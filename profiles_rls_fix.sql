-- ============================================
-- FIXED RLS POLICIES FOR PROFILES TABLE
-- This fixes the infinite recursion issue
-- ============================================

-- First, drop existing policies to start fresh
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete their own profile" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable" ON profiles;

-- Enable RLS if not already enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- SELECT POLICY (Read)
-- ============================================
-- Users can view their own profile
CREATE POLICY "Users can view their own profile"
ON profiles
FOR SELECT
USING (auth.uid() = id);

-- Admins can view all profiles (optional)
-- Uncomment if you have an admin role system
-- CREATE POLICY "Admins can view all profiles"
-- ON profiles
-- FOR SELECT
-- USING (
--   EXISTS (
--     SELECT 1 FROM profiles
--     WHERE id = auth.uid()
--     AND role = 'admin'
--   )
-- );

-- ============================================
-- INSERT POLICY (Create)
-- ============================================
-- Users can insert their own profile during signup
-- IMPORTANT: Use auth.uid() directly, don't query profiles table
CREATE POLICY "Users can insert their own profile"
ON profiles
FOR INSERT
WITH CHECK (auth.uid() = id);

-- ============================================
-- UPDATE POLICY (Modify)
-- ============================================
-- Users can update their own profile
-- IMPORTANT: Use auth.uid() directly, don't query profiles table
CREATE POLICY "Users can update their own profile"
ON profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Admins can update any profile (optional)
-- Uncomment if you have an admin role system
-- CREATE POLICY "Admins can update any profile"
-- ON profiles
-- FOR UPDATE
-- USING (
--   EXISTS (
--     SELECT 1 FROM profiles p
--     WHERE p.id = auth.uid()
--     AND p.role = 'admin'
--   )
-- )
-- WITH CHECK (
--   EXISTS (
--     SELECT 1 FROM profiles p
--     WHERE p.id = auth.uid()
--     AND p.role = 'admin'
--   )
-- );

-- ============================================
-- DELETE POLICY (Remove)
-- ============================================
-- Users can delete their own profile
CREATE POLICY "Users can delete their own profile"
ON profiles
FOR DELETE
USING (auth.uid() = id);

-- ============================================
-- NOTES:
-- ============================================
-- 1. The key fix is using auth.uid() directly instead of
--    querying the profiles table within policies
-- 
-- 2. If you need admin policies, use a separate query that
--    doesn't create circular dependencies
-- 
-- 3. auth.uid() is available immediately after signup/login
--    and doesn't require querying the profiles table
