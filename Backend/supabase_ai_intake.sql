-- Private storage bucket and RLS for door knocker image intake.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'lead-intake-images',
  'lead-intake-images',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/heic', 'image/heif', 'image/webp']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Lead intake uploads by owner path" on storage.objects;
create policy "Lead intake uploads by owner path"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'lead-intake-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Lead intake reads by owner path" on storage.objects;
create policy "Lead intake reads by owner path"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'lead-intake-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Lead intake deletes by owner path" on storage.objects;
create policy "Lead intake deletes by owner path"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'lead-intake-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
