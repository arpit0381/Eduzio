-- Super Admin Policies

-- 1. Organizations: Super Admin can view all organizations
CREATE POLICY "Super admin can view all organizations" ON public.organizations
    FOR SELECT USING (public.get_auth_role() = 'super_admin');

-- 2. Profiles: Super Admin can view all profiles
CREATE POLICY "Super admin can view all profiles" ON public.profiles
    FOR SELECT USING (public.get_auth_role() = 'super_admin');

-- 3. Super admin can create new organizations
-- The trigger and RPC already handle some of this, but if a super admin wants to create via direct insert:
CREATE POLICY "Super admin can create organizations" ON public.organizations
    FOR INSERT WITH CHECK (public.get_auth_role() = 'super_admin');

-- 4. Super admin can update any organization
CREATE POLICY "Super admin can update any organization" ON public.organizations
    FOR UPDATE USING (public.get_auth_role() = 'super_admin');
