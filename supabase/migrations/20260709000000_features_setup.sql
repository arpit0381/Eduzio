-- Migration: Setup User Avatars, Notification Tokens, and Notes System

-- 1. Alter profiles table to add avatar_url if not exists
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Create notification_tokens table
CREATE TABLE IF NOT EXISTS public.notification_tokens (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role VARCHAR NOT NULL,
    institute_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    device_name VARCHAR,
    platform VARCHAR,
    fcm_token VARCHAR UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS on notification_tokens
ALTER TABLE public.notification_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policies for notification_tokens
CREATE POLICY "Users can manage their own notification tokens"
    ON public.notification_tokens
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Tenant isolation for notification_tokens"
    ON public.notification_tokens
    FOR SELECT
    TO authenticated
    USING (institute_id = public.get_auth_organization_id());

-- 3. Create notes table
CREATE TABLE IF NOT EXISTS public.notes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES public.batches(id) ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_name VARCHAR NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS on notes
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- Note RLS Policies
CREATE POLICY "Tenant isolation for notes"
    ON public.notes
    FOR ALL
    TO authenticated
    USING (organization_id = public.get_auth_organization_id())
    WITH CHECK (organization_id = public.get_auth_organization_id());

-- 4. Create indexes for optimization
CREATE INDEX IF NOT EXISTS idx_notification_tokens_user ON public.notification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_tokens_token ON public.notification_tokens(fcm_token);
CREATE INDEX IF NOT EXISTS idx_notes_org ON public.notes(organization_id);
CREATE INDEX IF NOT EXISTS idx_notes_batch ON public.notes(batch_id);
