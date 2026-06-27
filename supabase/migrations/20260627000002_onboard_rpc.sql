-- RPC to securely onboard a new Organization and its Owner Admin
-- Bypasses public RLS on organizations and auth rate limits for email sending.
CREATE OR REPLACE FUNCTION public.onboard_organization_secure(
  org_name TEXT,
  org_subdomain TEXT,
  org_phone TEXT,
  owner_email TEXT,
  owner_password TEXT,
  owner_name TEXT
)
RETURNS UUID AS $$
DECLARE
  new_org_id UUID;
  new_user_id UUID;
BEGIN
  -- 1. Create Organization (bypasses RLS because SECURITY DEFINER)
  INSERT INTO public.organizations (name, subdomain, settings)
  VALUES (org_name, org_subdomain, jsonb_build_object('phone', org_phone))
  RETURNING id INTO new_org_id;

  -- 2. Create User in auth.users directly (bypasses email rate limit and confirmation requirement)
  INSERT INTO auth.users (
    id, 
    instance_id, 
    email, 
    encrypted_password, 
    email_confirmed_at, 
    raw_app_meta_data, 
    raw_user_meta_data, 
    is_super_admin, 
    role, 
    created_at, 
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    owner_email,
    crypt(owner_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('name', owner_name, 'role', 'admin', 'organization_id', new_org_id),
    false,
    'authenticated',
    now(),
    now()
  )
  RETURNING id INTO new_user_id;

  -- 3. Return the new organization ID
  RETURN new_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
