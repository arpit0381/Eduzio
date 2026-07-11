-- Migration: Fix student_fees schema mismatch safely

-- 1. Drop old constraints and columns that are no longer used
ALTER TABLE public.student_fees DROP CONSTRAINT IF EXISTS unique_student_fee_structure;
ALTER TABLE public.student_fees DROP COLUMN IF EXISTS fee_structure_id;

-- 2. Add batch_id with foreign key reference
ALTER TABLE public.student_fees ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.batches(id) ON DELETE SET NULL;

-- 3. Safely rename columns to match model class if they exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='student_fees' AND column_name='amount_due') THEN
    ALTER TABLE public.student_fees RENAME COLUMN amount_due TO amount;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='student_fees' AND column_name='amount_paid') THEN
    ALTER TABLE public.student_fees RENAME COLUMN amount_paid TO paid_amount;
  END IF;
END $$;

-- 4. Safely change status column type from custom enum to VARCHAR if it is USER-DEFINED (enum)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='student_fees' AND column_name='status' AND data_type='USER-DEFINED') THEN
    ALTER TABLE public.student_fees ALTER COLUMN status TYPE VARCHAR USING status::VARCHAR;
    ALTER TABLE public.student_fees ALTER COLUMN status SET DEFAULT 'pending';
  END IF;
END $$;

-- 5. Add paid_date and remarks columns
ALTER TABLE public.student_fees ADD COLUMN IF NOT EXISTS paid_date TIMESTAMPTZ;
ALTER TABLE public.student_fees ADD COLUMN IF NOT EXISTS remarks TEXT;

-- 6. Rename teacher_id to created_by in homework table if it exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='homework' AND column_name='teacher_id') THEN
    ALTER TABLE public.homework RENAME COLUMN teacher_id TO created_by;
  END IF;
END $$;

-- 7. Force Supabase to reload Postgrest schema cache
NOTIFY pgrst, 'reload schema';
