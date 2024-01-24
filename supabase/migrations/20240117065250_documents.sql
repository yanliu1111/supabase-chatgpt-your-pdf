create extension if not exists pg_net with schema extensions;
create extension if not exists vector with schema extensions;
-- pg_net extenstion for give you additional functions to call http endpoint
-- pg_vector essentially is web hook function
-- create vector extension, PG vector is a native vector type for Postgres
create table documents (
  id bigint primary key generated always as identity,
  name text not null,
  storage_object_id uuid not null references storage.objects (id),
  created_by uuid not null references auth.users (id) default auth.uid(),
  created_at timestamp with time zone not null default now()
);

create view documents_with_storage_path
with (security_invoker=true)
as
  select documents.*, storage.objects.name as storage_object_path
  from documents
  join storage.objects
    on storage.objects.id = documents.storage_object_id;
-- When create the view, you have to set security_invoker=true means: when you create this view and somebody actually calls this view pg needs to decide which permission level is for the people using this view / admin role / you are basically as a admin role to create this view and that role is usually call this. = true, means actually basically inherit their permission of whoever is calling this view versus defined the view

create table document_sections (
  id bigint primary key generated always as identity,
  document_id bigint not null references documents (id),
  content text not null,
  embedding vector (384)
);
-- 384 is the size of dimension of the vector, from hunggingface we used gte small model, which is 384 size of vector today
-- lower dimension is tipically better for search, but it's also less accurate
-- text-embedding-ada-002 is the largest embedding dimension for today, many people used 1536 dimension, but it takes way more space in memory and takes a longer to create indexes on once you scale up tp a large number of records
create index on document_sections using hnsw (embedding vector_ip_ops);
-- vector_ip_ops is the index operator, similar search operator, called inner product, use this because embedding will be normalized, so we can use inner product to calculate the distance between two vectors
-- if you use different distance measure like cosine for example, you are creating the index on the right operator
alter table documents enable row level security;
alter table document_sections enable row level security;

create policy "Users can insert documents"
on documents for insert to authenticated with check (
  auth.uid() = created_by
);

create policy "Users can query their own documents"
on documents for select to authenticated using (
  auth.uid() = created_by
);

create policy "Users can insert document sections"
on document_sections for insert to authenticated with check (
  document_id in (
    select id
    from documents
    where created_by = auth.uid()
  )
);

create policy "Users can update their own document sections"
on document_sections for update to authenticated using (
  document_id in (
    select id
    from documents
    where created_by = auth.uid()
  )
) with check (
  document_id in (
    select id
    from documents
    where created_by = auth.uid()
  )
);

create policy "Users can query their own document sections"
on document_sections for select to authenticated using (
  document_id in (
    select id
    from documents
    where created_by = auth.uid()
  )
);

create function supabase_url()
returns text
language plpgsql
security definer
as $$
declare
  secret_value text;
begin
  select decrypted_secret into secret_value from vault.decrypted_secrets where name = 'supabase_url';
  return secret_value;
end;
$$;

create function private.handle_storage_update()
returns trigger
language plpgsql
as $$
declare
  document_id bigint;
  result int;
begin
  insert into documents (name, storage_object_id, created_by)
    values (new.path_tokens[2], new.id, new.owner)
    returning id into document_id;
 
  -- we create a edge function called process, and what it will do well as the name suggests it's going to process the docutments, so this is going to be the edge function that takes our document the file that we uploaded in this case it's a markdown file, scans through it splits it into smaller chunks and then actually inserts those chunks into those document sections.
  -- web hook function, when you upload a file, it will call this function
  select
    net.http_post(
      url := supabase_url() || '/functions/v1/process',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', current_setting('request.headers')::json->>'authorization'
      ),
      body := jsonb_build_object(
        'document_id', document_id
      )
    )
  into result;

  return null;
end;
$$;

create trigger on_file_upload
  after insert on storage.objects
  for each row
  execute procedure private.handle_storage_update();