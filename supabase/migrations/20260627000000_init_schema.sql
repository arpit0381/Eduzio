-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Custom Enum Types
CREATE TYPE public.user_role AS ENUM ('super_admin', 'admin', 'teacher', 'student', 'parent', 'receptionist', 'accountant');
CREATE TYPE public.attendance_status AS ENUM ('present', 'absent', 'late', 'leave');
CREATE TYPE public.fee_status AS ENUM ('unpaid', 'partial', 'paid');
CREATE TYPE public.payment_mode AS ENUM ('cash', 'bank_transfer', 'cheque', 'other');

-- 1. Organizations (Tenants)
CREATE TABLE public.organizations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR NOT NULL,
    subdomain VARCHAR UNIQUE,
    logo_url TEXT,
    settings JSONB DEFAULT '{}'::jsonb NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ
);

-- Index for subdomain lookup
CREATE INDEX idx_organizations_subdomain ON public.organizations(subdomain);

-- 2. User Profiles (Extends Supabase Auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    organization_id UUID REFERENCES public.organizations ON DELETE SET NULL,
    name VARCHAR NOT NULL,
    email VARCHAR NOT NULL UNIQUE,
    phone VARCHAR,
    role public.user_role DEFAULT 'student'::public.user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ
);

-- Index on organization and role
CREATE INDEX idx_profiles_organization_id ON public.profiles(organization_id);
CREATE INDEX idx_profiles_role ON public.profiles(role);

-- 3. Batches
CREATE TABLE public.batches (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    code VARCHAR NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT unique_batch_code_per_org UNIQUE(organization_id, code)
);

CREATE INDEX idx_batches_organization ON public.batches(organization_id);

-- 4. Subjects
CREATE TABLE public.subjects (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    code VARCHAR NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT unique_subject_code_per_org UNIQUE(organization_id, code)
);

CREATE INDEX idx_subjects_organization ON public.subjects(organization_id);

-- 5. Batch Subjects (Junction table linking Batches, Subjects, and Teachers)
CREATE TABLE public.batch_subjects (
    batch_id UUID NOT NULL REFERENCES public.batches ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects ON DELETE CASCADE,
    teacher_id UUID REFERENCES public.profiles ON DELETE SET NULL,
    PRIMARY KEY (batch_id, subject_id)
);

CREATE INDEX idx_batch_subjects_teacher ON public.batch_subjects(teacher_id);

-- 6. Batch Students (Junction table linking Batches and Students)
CREATE TABLE public.batch_students (
    batch_id UUID NOT NULL REFERENCES public.batches ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    enrolled_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (batch_id, student_id)
);

-- 7. Student Guardians
CREATE TABLE public.student_guardians (
    student_id UUID PRIMARY KEY REFERENCES public.profiles ON DELETE CASCADE,
    guardian_name VARCHAR NOT NULL,
    guardian_phone VARCHAR,
    guardian_email VARCHAR,
    relation VARCHAR,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 8. Attendance Table
CREATE TABLE public.attendance (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    date DATE NOT NULL,
    status public.attendance_status NOT NULL,
    marked_by UUID REFERENCES public.profiles ON DELETE SET NULL,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_student_attendance_per_day_per_batch UNIQUE(batch_id, student_id, date)
);

CREATE INDEX idx_attendance_query ON public.attendance(organization_id, batch_id, date);
CREATE INDEX idx_attendance_student ON public.attendance(student_id);

-- 9. Homework Table
CREATE TABLE public.homework (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    description TEXT,
    file_url TEXT,
    due_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_homework_batch ON public.homework(batch_id);

-- 10. Homework Submissions Table
CREATE TABLE public.homework_submissions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    homework_id UUID NOT NULL REFERENCES public.homework ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    submission_text TEXT,
    file_url TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    status VARCHAR DEFAULT 'submitted' NOT NULL, -- 'submitted', 'graded'
    marks_obtained NUMERIC(5, 2),
    teacher_remarks TEXT,
    graded_by UUID REFERENCES public.profiles ON DELETE SET NULL,
    graded_at TIMESTAMPTZ,
    CONSTRAINT unique_submission_per_student UNIQUE(homework_id, student_id)
);

CREATE INDEX idx_homework_submissions_lookup ON public.homework_submissions(homework_id, student_id);

-- 11. Exams
CREATE TABLE public.exams (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    max_marks NUMERIC(5, 2) NOT NULL,
    exam_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_exams_batch ON public.exams(batch_id);

-- 12. Exam Marks
CREATE TABLE public.exam_marks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    exam_id UUID NOT NULL REFERENCES public.exams ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    marks_obtained NUMERIC(5, 2) NOT NULL,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_student_exam_marks UNIQUE(exam_id, student_id)
);

CREATE INDEX idx_exam_marks_lookup ON public.exam_marks(exam_id, student_id);

-- 13. Fees Structures
CREATE TABLE public.fees_structures (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    description TEXT,
    amount NUMERIC(10, 2) NOT NULL,
    due_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 14. Student Fees mapping
CREATE TABLE public.student_fees (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    fee_structure_id UUID NOT NULL REFERENCES public.fees_structures ON DELETE CASCADE,
    amount_due NUMERIC(10, 2) NOT NULL,
    amount_paid NUMERIC(10, 2) DEFAULT 0.00 NOT NULL,
    status public.fee_status DEFAULT 'unpaid'::public.fee_status NOT NULL,
    due_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_student_fee_structure UNIQUE(student_id, fee_structure_id)
);

CREATE INDEX idx_student_fees_lookup ON public.student_fees(organization_id, student_id);

-- 15. Payments Table (Manual Payments)
CREATE TABLE public.payments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    student_fee_id UUID NOT NULL REFERENCES public.student_fees ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    payment_mode public.payment_mode DEFAULT 'cash'::public.payment_mode NOT NULL,
    payment_date TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    transaction_id VARCHAR, -- Cheque No, Bank Txn Ref, etc.
    receipt_no VARCHAR NOT NULL,
    status VARCHAR DEFAULT 'success' NOT NULL, -- 'success', 'pending', 'failed'
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_payments_lookup ON public.payments(organization_id, student_fee_id);

-- 16. Announcements
CREATE TABLE public.announcements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    content TEXT NOT NULL,
    target_roles public.user_role[] NOT NULL,
    batch_id UUID REFERENCES public.batches ON DELETE CASCADE,
    created_by UUID REFERENCES public.profiles ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_announcements_query ON public.announcements(organization_id, batch_id);

-- 17. Audit Logs Table
CREATE TABLE public.audit_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations ON DELETE SET NULL,
    user_id UUID REFERENCES public.profiles ON DELETE SET NULL,
    action VARCHAR NOT NULL,
    entity_type VARCHAR NOT NULL,
    entity_id VARCHAR NOT NULL,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_audit_logs_query ON public.audit_logs(organization_id, created_at);

--------------------------------------------------------------------------------
-- JWT CLAIMS HELPERS
--------------------------------------------------------------------------------

-- Read organization_id from user JWT metadata
CREATE OR REPLACE FUNCTION public.get_auth_organization_id()
RETURNS UUID AS $$
    SELECT NULLIF(auth.jwt() -> 'user_metadata' ->> 'organization_id', '')::UUID;
$$ LANGUAGE sql STABLE;

-- Read role from user JWT metadata
CREATE OR REPLACE FUNCTION public.get_auth_role()
RETURNS VARCHAR AS $$
    SELECT auth.jwt() -> 'user_metadata' ->> 'role';
$$ LANGUAGE sql STABLE;

--------------------------------------------------------------------------------
-- TRIGGERS: AUTO CREATE & SYNC USER PROFILE
--------------------------------------------------------------------------------

-- Trigger 1: Auto create profile on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  org_id UUID;
  user_role public.user_role;
  user_name VARCHAR;
BEGIN
  org_id := (NEW.raw_user_meta_data->>'organization_id')::UUID;
  user_role := COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'student'::public.user_role);
  user_name := COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1));

  INSERT INTO public.profiles (id, organization_id, name, email, role)
  VALUES (NEW.id, org_id, user_name, NEW.email, user_role)
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- Trigger 2: Sync profile edits back to auth metadata (keeps JWT correct on role change)
CREATE OR REPLACE FUNCTION public.sync_profile_to_auth_metadata()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = 
    coalesce(raw_user_meta_data, '{}'::jsonb) || 
    jsonb_build_object(
      'organization_id', NEW.organization_id,
      'role', NEW.role,
      'name', NEW.name
    )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_profile_change
AFTER INSERT OR UPDATE OF organization_id, role, name
ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.sync_profile_to_auth_metadata();

--------------------------------------------------------------------------------
-- TRIGGERS: AUDIT LOGGING
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.log_entity_changes()
RETURNS TRIGGER AS $$
DECLARE
  org_id UUID;
  user_id UUID;
  old_val JSONB := NULL;
  new_val JSONB := NULL;
BEGIN
  org_id := public.get_auth_organization_id();
  user_id := auth.uid();

  IF TG_OP = 'DELETE' THEN
    old_val := to_jsonb(OLD);
    org_id := COALESCE(org_id, (OLD.organization_id)::UUID);
  ELSIF TG_OP = 'INSERT' THEN
    new_val := to_jsonb(NEW);
    org_id := COALESCE(org_id, (NEW.organization_id)::UUID);
  ELSIF TG_OP = 'UPDATE' THEN
    old_val := to_jsonb(OLD);
    new_val := to_jsonb(NEW);
    org_id := COALESCE(org_id, (NEW.organization_id)::UUID);
  END IF;

  INSERT INTO public.audit_logs (organization_id, user_id, action, entity_type, entity_id, old_values, new_values)
  VALUES (
    org_id,
    user_id,
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id::TEXT, OLD.id::TEXT),
    old_val,
    new_val
  );

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach Audit Log Triggers
CREATE TRIGGER audit_batches_changes
AFTER INSERT OR UPDATE OR DELETE ON public.batches
FOR EACH ROW EXECUTE FUNCTION public.log_entity_changes();

CREATE TRIGGER audit_attendance_changes
AFTER INSERT OR UPDATE OR DELETE ON public.attendance
FOR EACH ROW EXECUTE FUNCTION public.log_entity_changes();

CREATE TRIGGER audit_homework_changes
AFTER INSERT OR UPDATE OR DELETE ON public.homework
FOR EACH ROW EXECUTE FUNCTION public.log_entity_changes();

CREATE TRIGGER audit_exams_changes
AFTER INSERT OR UPDATE OR DELETE ON public.exams
FOR EACH ROW EXECUTE FUNCTION public.log_entity_changes();

CREATE TRIGGER audit_student_fees_changes
AFTER INSERT OR UPDATE OR DELETE ON public.student_fees
FOR EACH ROW EXECUTE FUNCTION public.log_entity_changes();

CREATE TRIGGER audit_payments_changes
AFTER INSERT OR UPDATE OR DELETE ON public.payments
FOR EACH ROW EXECUTE FUNCTION public.log_entity_changes();

--------------------------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) POLICIES
--------------------------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homework_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_marks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fees_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 1. Organizations Policies
CREATE POLICY "View own organization" ON public.organizations
    FOR SELECT USING (id = public.get_auth_organization_id());

CREATE POLICY "Admin can update organization" ON public.organizations
    FOR UPDATE USING (id = public.get_auth_organization_id() AND public.get_auth_role() = 'admin');

CREATE POLICY "Allow authenticated users to create organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 2. Profiles Policies
CREATE POLICY "Tenant isolation for selecting profiles" ON public.profiles
    FOR SELECT USING (organization_id = public.get_auth_organization_id());

CREATE POLICY "Admin can write profiles" ON public.profiles
    FOR ALL USING (
        organization_id = public.get_auth_organization_id() AND public.get_auth_role() = 'admin'
    );

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (id = auth.uid());

-- 3. Batches Policies
CREATE POLICY "Tenant isolation for batches" ON public.batches
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 4. Subjects Policies
CREATE POLICY "Tenant isolation for subjects" ON public.subjects
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 5. Batch Subjects Policies
CREATE POLICY "Tenant isolation for batch_subjects" ON public.batch_subjects
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.batches 
            WHERE id = batch_id AND organization_id = public.get_auth_organization_id()
        )
    );

-- 6. Batch Students Policies
CREATE POLICY "Tenant isolation for batch_students" ON public.batch_students
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.batches 
            WHERE id = batch_id AND organization_id = public.get_auth_organization_id()
        )
    );

-- 7. Student Guardians Policies
CREATE POLICY "Tenant isolation for student_guardians" ON public.student_guardians
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = student_id AND organization_id = public.get_auth_organization_id()
        )
    );

-- 8. Attendance Policies
CREATE POLICY "Tenant isolation for attendance" ON public.attendance
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 9. Homework Policies
CREATE POLICY "Tenant isolation for homework" ON public.homework
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 10. Homework Submissions Policies
CREATE POLICY "Tenant isolation for homework_submissions" ON public.homework_submissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.homework 
            WHERE id = homework_id AND organization_id = public.get_auth_organization_id()
        )
    );

-- 11. Exams Policies
CREATE POLICY "Tenant isolation for exams" ON public.exams
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 12. Exam Marks Policies
CREATE POLICY "Tenant isolation for exam_marks" ON public.exam_marks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.exams 
            WHERE id = exam_id AND organization_id = public.get_auth_organization_id()
        )
    );

-- 13. Fees Structures Policies
CREATE POLICY "Tenant isolation for fees_structures" ON public.fees_structures
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 14. Student Fees Policies
CREATE POLICY "Tenant isolation for student_fees" ON public.student_fees
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 15. Payments Policies
CREATE POLICY "Tenant isolation for payments" ON public.payments
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 16. Announcements Policies
CREATE POLICY "Tenant isolation for announcements" ON public.announcements
    FOR ALL USING (organization_id = public.get_auth_organization_id());

-- 17. Audit Logs Policies
CREATE POLICY "Tenant isolation for audit_logs" ON public.audit_logs
    FOR SELECT USING (
        organization_id = public.get_auth_organization_id() AND public.get_auth_role() = 'admin'
    );
