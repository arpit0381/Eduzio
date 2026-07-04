-- Create extension pgcrypto if not exists (required for crypt password hashing)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- RPC to create a new Student securely by an Admin
CREATE OR REPLACE FUNCTION public.create_new_student(
  student_email TEXT,
  student_password TEXT,
  student_name TEXT,
  student_phone TEXT,
  guardian_name TEXT,
  guardian_phone TEXT,
  guardian_relation TEXT
)
RETURNS UUID AS $$
DECLARE
  new_user_id UUID;
  org_id UUID;
BEGIN
  -- 1. Fetch caller's organization context
  org_id := public.get_auth_organization_id();
  
  -- 2. Verify authorization
  IF public.get_auth_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only administrators can create student accounts';
  END IF;

  -- 3. Create user in auth.users table
  INSERT INTO auth.users (
    id, 
    instance_id, 
    email, 
    encrypted_password, 
    email_confirmed_at, 
    raw_app_meta_data, 
    raw_user_meta_data, 
    is_super_admin, 
    aud,
    role, 
    created_at, 
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change_token_current,
    email_change
  )
  VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    student_email,
    crypt(student_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('name', student_name, 'role', 'student', 'organization_id', org_id),
    false,
    'authenticated',
    'authenticated',
    now(),
    now(),
    '',
    '',
    '',
    '',
    ''
  )
  RETURNING id INTO new_user_id;

  -- 3.5 Create Identity in auth.identities (Required by GoTrue)
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    new_user_id,
    new_user_id::text,
    jsonb_build_object('sub', new_user_id::text, 'email', student_email),
    'email',
    now(),
    now(),
    now()
  );

  -- 4. Create guardian row if details are provided
  IF guardian_name IS NOT NULL AND guardian_name != '' THEN
    INSERT INTO public.student_guardians (
      student_id, 
      guardian_name, 
      guardian_phone, 
      relation
    )
    VALUES (
      new_user_id, 
      guardian_name, 
      student_phone, -- we'll store the guardian's phone number
      guardian_relation
    );
  END IF;

  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC to create a new Teacher securely by an Admin
CREATE OR REPLACE FUNCTION public.create_new_teacher(
  teacher_email TEXT,
  teacher_password TEXT,
  teacher_name TEXT,
  teacher_phone TEXT
)
RETURNS UUID AS $$
DECLARE
  new_user_id UUID;
  org_id UUID;
BEGIN
  -- 1. Fetch caller's organization context
  org_id := public.get_auth_organization_id();
  
  -- 2. Verify authorization
  IF public.get_auth_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only administrators can create teacher accounts';
  END IF;

  -- 3. Create user in auth.users table
  INSERT INTO auth.users (
    id, 
    instance_id, 
    email, 
    encrypted_password, 
    email_confirmed_at, 
    raw_app_meta_data, 
    raw_user_meta_data, 
    is_super_admin, 
    aud,
    role, 
    created_at, 
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change_token_current,
    email_change
  )
  VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    teacher_email,
    crypt(teacher_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('name', teacher_name, 'role', 'teacher', 'organization_id', org_id),
    false,
    'authenticated',
    'authenticated',
    now(),
    now(),
    '',
    '',
    '',
    '',
    ''
  )
  RETURNING id INTO new_user_id;

  -- 3.5 Create Identity in auth.identities (Required by GoTrue)
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    new_user_id,
    new_user_id::text,
    jsonb_build_object('sub', new_user_id::text, 'email', teacher_email),
    'email',
    now(),
    now(),
    now()
  );

  -- 4. Update the profile phone number
  UPDATE public.profiles
  SET phone = teacher_phone
  WHERE id = new_user_id;

  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
