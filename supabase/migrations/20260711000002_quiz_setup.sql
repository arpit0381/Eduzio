-- Migration: Setup Quiz System & Fix Homework Subject Constraint

-- 1. Fix homework subject_id not-null constraint
ALTER TABLE public.homework ALTER COLUMN subject_id DROP NOT NULL;

-- 2. Drop old exam tables
DROP TABLE IF EXISTS public.exam_marks CASCADE;
DROP TABLE IF EXISTS public.exams CASCADE;

-- 3. Create quizzes table
CREATE TABLE public.quizzes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    description TEXT,
    duration_minutes INT NOT NULL DEFAULT 10,
    questions JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_by UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 4. Create quiz_attempts table
CREATE TABLE public.quiz_attempts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    quiz_id UUID NOT NULL REFERENCES public.quizzes ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    score INT NOT NULL,
    total_questions INT NOT NULL,
    completed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_student_quiz UNIQUE(quiz_id, student_id)
);

-- 5. Enable RLS
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

-- 6. RLS policies
CREATE POLICY "Tenant isolation for quizzes" ON public.quizzes
    FOR ALL USING (organization_id = public.get_auth_organization_id());

CREATE POLICY "Tenant isolation for quiz_attempts" ON public.quiz_attempts
    FOR ALL USING (
        quiz_id IN (SELECT id FROM public.quizzes WHERE organization_id = public.get_auth_organization_id())
    );

-- 7. Force Supabase to reload Postgrest schema cache
NOTIFY pgrst, 'reload schema';
--heheh--