-- Migration: Add user_id to announcements for targeted private notifications

-- 1. Add user_id column
ALTER TABLE public.announcements 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 2. Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_announcements_user_id ON public.announcements(user_id);

-- 3. Update RLS policies to restrict personal notifications
DROP POLICY IF EXISTS "Tenant isolation for announcements" ON public.announcements;

CREATE POLICY "Tenant isolation for announcements" ON public.announcements
    FOR ALL 
    TO authenticated
    USING (
        organization_id = public.get_auth_organization_id()
        AND (user_id IS NULL OR user_id = auth.uid())
    )
    WITH CHECK (
        organization_id = public.get_auth_organization_id()
        AND (user_id IS NULL OR user_id = auth.uid())
    );
