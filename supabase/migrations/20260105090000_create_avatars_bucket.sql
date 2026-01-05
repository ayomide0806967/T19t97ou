-- Create Storage bucket for user avatars/covers used by the app.
-- Bucket name expected by the Flutter client: `avatars`

do $$
begin
  if not exists (
    select 1 from storage.buckets where id = 'avatars'
  ) then
    insert into storage.buckets (id, name, public)
    values ('avatars', 'avatars', true);
  end if;
end $$;

-- Public read access for avatar objects.
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Public read avatars'
  ) then
    create policy "Public read avatars"
      on storage.objects
      for select
      using (bucket_id = 'avatars');
  end if;
end $$;

-- Authenticated users can upload (insert) objects into the avatars bucket.
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Users can upload avatars'
  ) then
    create policy "Users can upload avatars"
      on storage.objects
      for insert
      with check (bucket_id = 'avatars' and auth.uid() = owner);
  end if;
end $$;

-- Authenticated users can update their own objects in the avatars bucket.
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Users can update avatars'
  ) then
    create policy "Users can update avatars"
      on storage.objects
      for update
      using (bucket_id = 'avatars' and auth.uid() = owner)
      with check (bucket_id = 'avatars' and auth.uid() = owner);
  end if;
end $$;

-- Authenticated users can delete their own objects in the avatars bucket.
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Users can delete avatars'
  ) then
    create policy "Users can delete avatars"
      on storage.objects
      for delete
      using (bucket_id = 'avatars' and auth.uid() = owner);
  end if;
end $$;

