-- RPC to securely create a new Organization without authentication
-- Bypasses public RLS on organizations for onboarding purposes.
CREATE OR REPLACE FUNCTION public.create_organization_unauthenticated(
  org_name TEXT,
  org_subdomain TEXT,
  org_phone TEXT
)
RETURNS UUID AS $$
DECLARE
  new_org_id UUID;
BEGIN
  -- 1. Create Organization (bypasses RLS because SECURITY DEFINER)
  INSERT INTO public.organizations (name, subdomain, settings)
  VALUES (org_name, org_subdomain, jsonb_build_object('phone', org_phone))
  RETURNING id INTO new_org_id;

  -- 2. Return the new organization ID
  RETURN new_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
