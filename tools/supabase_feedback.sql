-- RCIL site feedback (likes + comments)
-- Run once in Supabase → SQL Editor.
-- Then set admin password (see bottom).

-- Supabase: pgcrypto lives in schema "extensions"
create extension if not exists pgcrypto with schema extensions;

-- ── likes ────────────────────────────────────────────────────────
create table if not exists public.page_likes (
  id uuid primary key default gen_random_uuid(),
  page_id text not null,
  client_id text not null,
  created_at timestamptz not null default now(),
  unique (page_id, client_id)
);

create index if not exists page_likes_page_id_idx on public.page_likes (page_id);

alter table public.page_likes enable row level security;

drop policy if exists "likes_select" on public.page_likes;
create policy "likes_select" on public.page_likes
  for select to anon, authenticated using (true);

drop policy if exists "likes_insert" on public.page_likes;
create policy "likes_insert" on public.page_likes
  for insert to anon, authenticated
  with check (char_length(page_id) > 0 and char_length(client_id) > 0);

drop policy if exists "likes_delete_own" on public.page_likes;
-- Direct DELETE disabled. Use remove_page_like() so only (page_id, client_id) pairs are removed.

create or replace function public.remove_page_like(p_page_id text, p_client_id text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.page_likes
  where page_id = p_page_id and client_id = p_client_id;
$$;

revoke all on function public.remove_page_like(text, text) from public;
grant execute on function public.remove_page_like(text, text) to anon, authenticated;

-- ── comments ─────────────────────────────────────────────────────
create table if not exists public.page_comments (
  id uuid primary key default gen_random_uuid(),
  page_id text not null,
  author_name text not null,
  affiliation text not null default '',
  body text not null,
  is_private boolean not null default false,
  viewer_token uuid,
  created_at timestamptz not null default now(),
  constraint page_comments_name_len check (char_length(trim(author_name)) between 1 and 80),
  constraint page_comments_aff_len check (char_length(affiliation) <= 120),
  constraint page_comments_body_len check (char_length(trim(body)) between 1 and 4000),
  constraint page_comments_private_token check (
    (is_private = false and viewer_token is null)
    or (is_private = true and viewer_token is not null)
  )
);

create index if not exists page_comments_page_id_idx on public.page_comments (page_id);
create index if not exists page_comments_viewer_token_idx on public.page_comments (viewer_token);

alter table public.page_comments enable row level security;

-- Direct table reads: public comments only (private never leak via select *)
drop policy if exists "comments_select_public" on public.page_comments;
create policy "comments_select_public" on public.page_comments
  for select to anon, authenticated using (is_private = false);

drop policy if exists "comments_insert" on public.page_comments;
create policy "comments_insert" on public.page_comments
  for insert to anon, authenticated
  with check (
    char_length(trim(author_name)) between 1 and 80
    and char_length(trim(body)) between 1 and 4000
    and char_length(affiliation) <= 120
    and (
      (is_private = false and viewer_token is null)
      or (is_private = true and viewer_token is not null)
    )
  );

-- ── site secrets (admin password hash) ───────────────────────────
create table if not exists public.site_secrets (
  key text primary key,
  value text not null
);

alter table public.site_secrets enable row level security;
-- no policies → anon cannot read secrets

-- ── RPCs ─────────────────────────────────────────────────────────
create or replace function public.fetch_page_comments(
  p_page_id text,
  p_tokens uuid[] default '{}'
)
returns table (
  id uuid,
  page_id text,
  author_name text,
  affiliation text,
  body text,
  is_private boolean,
  created_at timestamptz,
  is_mine boolean
)
language sql
security definer
set search_path = public
as $$
  select
    c.id,
    c.page_id,
    c.author_name,
    c.affiliation,
    c.body,
    c.is_private,
    c.created_at,
    (c.is_private and c.viewer_token = any (p_tokens)) as is_mine
  from public.page_comments c
  where c.page_id = p_page_id
    and (
      c.is_private = false
      or c.viewer_token = any (p_tokens)
    )
  order by c.created_at asc;
$$;

revoke all on function public.fetch_page_comments(text, uuid[]) from public;
grant execute on function public.fetch_page_comments(text, uuid[]) to anon, authenticated;

create or replace function public.fetch_page_comments_admin(
  p_page_id text,
  p_password text
)
returns table (
  id uuid,
  page_id text,
  author_name text,
  affiliation text,
  body text,
  is_private boolean,
  created_at timestamptz,
  is_mine boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  stored text;
begin
  select value into stored from public.site_secrets where key = 'admin_password_hash';
  if stored is null or stored = '' then
    raise exception 'admin password not configured';
  end if;
  if extensions.crypt(p_password, stored) <> stored then
    raise exception 'invalid admin password';
  end if;

  return query
  select
    c.id,
    c.page_id,
    c.author_name,
    c.affiliation,
    c.body,
    c.is_private,
    c.created_at,
    false as is_mine
  from public.page_comments c
  where c.page_id = p_page_id
  order by c.created_at asc;
end;
$$;

revoke all on function public.fetch_page_comments_admin(text, text) from public;
grant execute on function public.fetch_page_comments_admin(text, text) to anon, authenticated;

create or replace function public.count_page_likes(p_page_id text)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::bigint from public.page_likes where page_id = p_page_id;
$$;

revoke all on function public.count_page_likes(text) from public;
grant execute on function public.count_page_likes(text) to anon, authenticated;

-- ── set / rotate admin password ──────────────────────────────────
-- Replace YOUR_PASSWORD, then run:
--
--   select public.set_feedback_admin_password('YOUR_PASSWORD');
--
create or replace function public.set_feedback_admin_password(p_password text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if char_length(p_password) < 8 then
    raise exception 'password must be at least 8 characters';
  end if;
  insert into public.site_secrets(key, value)
  values ('admin_password_hash', extensions.crypt(p_password, extensions.gen_salt('bf')))
  on conflict (key) do update set value = excluded.value;
  return 'admin password updated';
end;
$$;

-- Callable only from SQL Editor (service role / postgres), not from the website.
revoke all on function public.set_feedback_admin_password(text) from public;
revoke all on function public.set_feedback_admin_password(text) from anon, authenticated;
