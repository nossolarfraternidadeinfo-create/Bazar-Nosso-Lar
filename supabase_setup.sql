-- Execute este script no Supabase > SQL Editor > New query.
-- Cria catálogo, lista de administradores e permissões básicas.

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  description text default '',
  price text not null,
  image_url text,
  available boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.admins enable row level security;

-- Visitantes podem ver somente produtos disponíveis.
create policy "Public can view available products"
on public.products for select
using (available = true);

-- Administradores cadastrados podem ver todos os produtos e gerenciar o catálogo.
create policy "Admins can view all products"
on public.products for select to authenticated
using (exists (select 1 from public.admins where user_id = auth.uid()));

create policy "Admins can insert products"
on public.products for insert to authenticated
with check (exists (select 1 from public.admins where user_id = auth.uid()));

create policy "Admins can update products"
on public.products for update to authenticated
using (exists (select 1 from public.admins where user_id = auth.uid()))
with check (exists (select 1 from public.admins where user_id = auth.uid()));

create policy "Admins can delete products"
on public.products for delete to authenticated
using (exists (select 1 from public.admins where user_id = auth.uid()));

-- Bucket público para as fotos da vitrine.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos-produtos', 'fotos-produtos', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880;

create policy "Public can view product photos"
on storage.objects for select
using (bucket_id = 'fotos-produtos');

create policy "Admins can upload product photos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'fotos-produtos'
  and exists (select 1 from public.admins where user_id = auth.uid())
);

create policy "Admins can update product photos"
on storage.objects for update to authenticated
using (
  bucket_id = 'fotos-produtos'
  and exists (select 1 from public.admins where user_id = auth.uid())
)
with check (
  bucket_id = 'fotos-produtos'
  and exists (select 1 from public.admins where user_id = auth.uid())
);

create policy "Admins can delete product photos"
on storage.objects for delete to authenticated
using (
  bucket_id = 'fotos-produtos'
  and exists (select 1 from public.admins where user_id = auth.uid())
);

-- Depois de criar seu usuário em Authentication > Users,
-- copie o UUID dele e execute:
-- insert into public.admins (user_id) values ('COLE-AQUI-O-UUID-DO-USUARIO');
