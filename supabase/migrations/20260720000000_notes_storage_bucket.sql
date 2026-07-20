-- Migration: Create Storage Bucket for Notes
INSERT INTO storage.buckets (id, name, public)
VALUES ('notes', 'notes', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Enable RLS and create public access policies
CREATE POLICY "Public Read Access for Notes Bucket"
ON storage.objects FOR SELECT
USING (bucket_id = 'notes');

CREATE POLICY "Authenticated Users Upload Notes"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'notes');

CREATE POLICY "Authenticated Users Update Notes"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'notes');

CREATE POLICY "Authenticated Users Delete Notes"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'notes');
