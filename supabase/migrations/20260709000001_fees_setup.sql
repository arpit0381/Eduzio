-- Migration: Setup Student Fees System

-- 1. Create student_fees table
CREATE TABLE IF NOT EXISTS public.student_fees (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL,
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES public.batches(id) ON DELETE SET NULL,
    amount NUMERIC(10, 2) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR DEFAULT 'pending' NOT NULL, -- 'paid', 'pending', 'overdue'
    paid_amount NUMERIC(10, 2) DEFAULT 0 NOT NULL,
    paid_date TIMESTAMPTZ,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS on student_fees
ALTER TABLE public.student_fees ENABLE ROW LEVEL SECURITY;

-- RLS Policies for student_fees

-- Students can read their own fees
CREATE POLICY "Students can read their own fees"
ON public.student_fees
FOR SELECT
TO authenticated
USING (
    organization_id = public.get_auth_organization_id() 
    AND auth.uid() = student_id
);

-- Admins and teachers can manage all fees in their organization
CREATE POLICY "Admins and teachers can manage all fees"
ON public.student_fees
FOR ALL
TO authenticated
USING (
    organization_id = public.get_auth_organization_id()
)
WITH CHECK (
    organization_id = public.get_auth_organization_id()
);
