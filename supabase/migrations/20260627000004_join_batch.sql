-- RPC to join a batch by code securely for a student
CREATE OR REPLACE FUNCTION public.join_batch_by_code(p_code TEXT)
RETURNS UUID AS $$
DECLARE
  v_batch_id UUID;
  v_org_id UUID;
BEGIN
  -- 1. Fetch caller's organization context
  v_org_id := public.get_auth_organization_id();
  
  -- 2. Verify authorization
  IF public.get_auth_role() != 'student' THEN
    RAISE EXCEPTION 'Unauthorized: only students can join batches via code';
  END IF;

  -- 3. Lookup the batch in the same organization
  SELECT id INTO v_batch_id
  FROM public.batches
  WHERE code = p_code AND organization_id = v_org_id
  LIMIT 1;

  IF v_batch_id IS NULL THEN
    RAISE EXCEPTION 'Invalid batch code';
  END IF;

  -- 4. Insert into batch_students if not already enrolled
  INSERT INTO public.batch_students (batch_id, student_id)
  VALUES (v_batch_id, auth.uid())
  ON CONFLICT (batch_id, student_id) DO NOTHING;

  RETURN v_batch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
