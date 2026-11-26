-- M-klub Vysoké Mýto: databáze webu (jeden klub, jeden vlastník).
-- Spusťte v Supabase: SQL Editor -> vložit -> Run. Je bezpečné spustit opakovaně.

------------------------------------------------------------------ oprávnění
create table if not exists public.admins (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  role       text not null default 'editor' check (role in ('owner','editor')),
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.admins where user_id = auth.uid()) $$;

create or replace function public.is_owner() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.admins where user_id = auth.uid() and role = 'owner') $$;

-- uživatel smí vidět jen svůj vlastní záznam (zjištění role)
drop policy if exists admins_select_self on public.admins;
create policy admins_select_self on public.admins for select to authenticated using (user_id = auth.uid());

------------------------------------------------------------------ obsah (koncept)
create table if not exists public.site_settings (
  id   int primary key default 1 check (id = 1),
  data jsonb not null default '{}'::jsonb
);
create table if not exists public.categories (
  name text primary key,
  slug text not null unique,
  sort int  not null default 0
);
create table if not exists public.events (
  id           text primary key,
  iso          date not null,
  t            text not null default '19:00',
  category     text not null references public.categories (name) on update cascade on delete restrict,
  title        text not null check (char_length(title) between 1 and 200),
  descr        text not null default '',
  price        text not null default '',
  place        text not null default '',
  availability text not null default 'ok' check (availability in ('ok','sold','soon')),
  info_url     text not null default '',
  ticket_url   text not null default '',
  image        text not null default '',
  updated_at   timestamptz not null default now()
);
create table if not exists public.news (
  id         text primary key,
  iso        date,
  title      text not null check (char_length(title) between 1 and 200),
  descr      text not null default '',
  image      text not null default '',
  updated_at timestamptz not null default now()
);
create table if not exists public.gallery (
  id      text primary key,
  src     text not null,
  caption text not null default '',
  sort    int  not null default 0
);
create table if not exists public.spaces (
  id       text primary key,
  title    text not null check (char_length(title) between 1 and 200),
  place    text not null default '',
  capacity text not null default '',
  descr    text not null default '',
  contact  text not null default '',
  image    text not null default '',
  sort     int  not null default 0
);
create table if not exists public.page_contents (
  key  text primary key,
  body text not null default ''
);

------------------------------------------------------------------ publikovaná verze
create table if not exists public.published_site (
  id           int primary key default 1 check (id = 1),
  snapshot     jsonb not null,
  published_at timestamptz not null default now(),
  published_by uuid
);
create table if not exists public.publications (
  id           bigserial primary key,
  snapshot     jsonb not null,
  published_at timestamptz not null default now(),
  published_by uuid,
  note         text
);
create table if not exists public.audit_log (
  id         bigserial primary key,
  at         timestamptz not null default now(),
  user_id    uuid,
  action     text not null,
  table_name text,
  row_id     text,
  summary    text
);
create table if not exists public.inquiries (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  kind       text not null default 'contact' check (kind in ('contact','rental')),
  name       text not null check (char_length(name) between 1 and 200),
  email      text not null check (char_length(email) between 5 and 200 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]{2,}$'),
  phone      text not null default '' check (char_length(phone) <= 60),
  space      text not null default '' check (char_length(space) <= 200),
  event_date text not null default '' check (char_length(event_date) <= 30),
  headcount  text not null default '' check (char_length(headcount) <= 20),
  message    text not null check (char_length(message) between 3 and 4000),
  handled    boolean not null default false
);

------------------------------------------------------------------ RLS
do $$ declare t text; begin
  foreach t in array array['site_settings','categories','events','news','gallery','spaces','page_contents','published_site','publications','audit_log','inquiries'] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- koncept: čtení i zápis jen pro přihlášeného správce
do $$ declare t text; begin
  foreach t in array array['site_settings','categories','events','news','gallery','spaces','page_contents'] loop
    execute format('drop policy if exists %I on public.%I', t||'_admin_all', t);
    execute format('create policy %I on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t||'_admin_all', t);
  end loop;
end $$;

-- veřejnost smí jen číst publikovanou verzi; zapisuje se výhradně funkcí publish_site()
drop policy if exists published_site_read on public.published_site;
create policy published_site_read on public.published_site for select to anon, authenticated using (true);

drop policy if exists publications_admin_read on public.publications;
create policy publications_admin_read on public.publications for select to authenticated using (public.is_admin());
drop policy if exists audit_admin_read on public.audit_log;
create policy audit_admin_read on public.audit_log for select to authenticated using (public.is_admin());

-- poptávky: kdokoli smí vložit (omezeno kontrolou sloupců), číst a řešit smí jen správce
drop policy if exists inquiries_insert_public on public.inquiries;
create policy inquiries_insert_public on public.inquiries for insert to anon, authenticated with check (handled = false);
drop policy if exists inquiries_admin_read on public.inquiries;
create policy inquiries_admin_read on public.inquiries for select to authenticated using (public.is_admin());
drop policy if exists inquiries_admin_update on public.inquiries;
create policy inquiries_admin_update on public.inquiries for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists inquiries_admin_delete on public.inquiries;
create policy inquiries_admin_delete on public.inquiries for delete to authenticated using (public.is_admin());

------------------------------------------------------------------ minimální oprávnění rolí (obrana ve více vrstvách)
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
grant usage on schema public to anon, authenticated;
grant select on public.published_site to anon, authenticated;
grant insert on public.inquiries to anon;
grant select, insert, update, delete on public.site_settings, public.categories, public.events, public.news,
      public.gallery, public.spaces, public.page_contents, public.inquiries to authenticated;
grant select on public.publications, public.audit_log, public.admins to authenticated;
grant insert on public.inquiries to authenticated;

------------------------------------------------------------------ snímek obsahu
create or replace function public.build_snapshot() returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'site',  coalesce((select data from site_settings where id = 1), '{}'::jsonb),
    'texts', coalesce((select jsonb_object_agg(key, body) from page_contents), '{}'::jsonb),
    'cats',  coalesce((select jsonb_agg(name order by sort, name) from categories), '[]'::jsonb),
    'events', coalesce((select jsonb_agg(jsonb_build_object('id',id,'iso',iso,'t',t,'c',category,'title',title,'desc',descr,
               'price',price,'place',place,'av',availability,'url',info_url,'tk',ticket_url,'img',image) order by iso, t, id) from events), '[]'::jsonb),
    'news',  coalesce((select jsonb_agg(jsonb_build_object('id',id,'iso',iso,'title',title,'desc',descr,'img',image) order by iso desc nulls last, id) from news), '[]'::jsonb),
    'gallery', coalesce((select jsonb_agg(jsonb_build_object('id',id,'src',src,'cap',caption) order by sort, id) from gallery), '[]'::jsonb),
    'spaces', coalesce((select jsonb_agg(jsonb_build_object('id',id,'title',title,'place',place,'cap',capacity,'desc',descr,
               'contact',contact,'img',image) order by sort, id) from spaces), '[]'::jsonb)
  )
$$;
revoke all on function public.build_snapshot() from public, anon, authenticated;

create or replace function public._apply_snapshot(snap jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from events; delete from news; delete from gallery; delete from spaces; delete from page_contents; delete from categories;
  insert into categories(name, slug, sort)
    select c.value, regexp_replace(lower(translate(c.value,'áčďéěíňóřšťúůýžÁČĎÉĚÍŇÓŘŠŤÚŮÝŽ','acdeeinorstuuyzacdeeinorstuuyz')),'[^a-z0-9]+','-','g'), c.ordinality::int
    from jsonb_array_elements_text(snap->'cats') with ordinality as c(value, ordinality);
  insert into events(id,iso,t,category,title,descr,price,place,availability,info_url,ticket_url,image)
    select e->>'id',(e->>'iso')::date,coalesce(e->>'t','19:00'),e->>'c',e->>'title',coalesce(e->>'desc',''),coalesce(e->>'price',''),
           coalesce(e->>'place',''),coalesce(nullif(e->>'av',''),'ok'),coalesce(e->>'url',''),coalesce(e->>'tk',''),coalesce(e->>'img','')
    from jsonb_array_elements(snap->'events') e;
  insert into news(id,iso,title,descr,image)
    select n->>'id', nullif(n->>'iso','')::date, n->>'title', coalesce(n->>'desc',''), coalesce(n->>'img','')
    from jsonb_array_elements(snap->'news') n;
  insert into gallery(id,src,caption,sort)
    select g.value->>'id', g.value->>'src', coalesce(g.value->>'cap',''), g.ordinality::int
    from jsonb_array_elements(snap->'gallery') with ordinality as g(value, ordinality);
  insert into spaces(id,title,place,capacity,descr,contact,image,sort)
    select s.value->>'id', s.value->>'title', coalesce(s.value->>'place',''), coalesce(s.value->>'cap',''), coalesce(s.value->>'desc',''),
           coalesce(s.value->>'contact',''), coalesce(s.value->>'img',''), s.ordinality::int
    from jsonb_array_elements(snap->'spaces') with ordinality as s(value, ordinality);
  insert into page_contents(key, body) select k, v from jsonb_each_text(coalesce(snap->'texts','{}'::jsonb)) as t(k, v);
  insert into site_settings(id, data) values (1, coalesce(snap->'site','{}'::jsonb))
    on conflict (id) do update set data = excluded.data;
end $$;
revoke all on function public._apply_snapshot(jsonb) from public, anon, authenticated;

------------------------------------------------------------------ funkce pro administraci
create or replace function public.draft_snapshot() returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  return build_snapshot();
end $$;

create or replace function public.has_unpublished_changes() returns boolean
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  return build_snapshot() is distinct from (select snapshot from published_site where id = 1);
end $$;

create or replace function public.publish_site(p_note text default null) returns timestamptz
language plpgsql security definer set search_path = public as $$
declare snap jsonb; ts timestamptz := now();
begin
  if not is_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  snap := build_snapshot();
  insert into published_site(id, snapshot, published_at, published_by) values (1, snap, ts, auth.uid())
    on conflict (id) do update set snapshot = excluded.snapshot, published_at = excluded.published_at, published_by = excluded.published_by;
  insert into publications(snapshot, published_at, published_by, note) values (snap, ts, auth.uid(), p_note);
  delete from publications where id not in (select id from publications order by id desc limit 30);
  insert into audit_log(user_id, action, summary) values (auth.uid(), 'publish', coalesce(p_note, 'Změny zveřejněny'));
  return ts;
end $$;

create or replace function public.discard_changes() returns void
language plpgsql security definer set search_path = public as $$
declare snap jsonb;
begin
  if not is_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  select snapshot into snap from published_site where id = 1;
  if snap is null then raise exception 'nothing_published'; end if;
  perform _apply_snapshot(snap);
  insert into audit_log(user_id, action, summary) values (auth.uid(), 'discard', 'Neuložené změny zahozeny');
end $$;

create or replace function public.restore_publication(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare snap jsonb;
begin
  if not is_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  select snapshot into snap from publications where id = p_id;
  if snap is null then raise exception 'not_found'; end if;
  perform _apply_snapshot(snap);
  insert into audit_log(user_id, action, row_id, summary) values (auth.uid(), 'restore', p_id::text, 'Koncept obnoven z dřívější verze');
end $$;

revoke all on function public.is_admin(), public.is_owner(), public.draft_snapshot(), public.has_unpublished_changes(),
  public.publish_site(text), public.discard_changes(), public.restore_publication(bigint) from public, anon;
grant execute on function public.is_admin(), public.is_owner(), public.draft_snapshot(), public.has_unpublished_changes(),
  public.publish_site(text), public.discard_changes(), public.restore_publication(bigint) to authenticated;
-- is_admin() se používá i uvnitř RLS politik pro roli anon, proto musí být spustitelná i pro ni
grant execute on function public.is_admin() to anon;

------------------------------------------------------------------ historie úprav (audit)
create or replace function public.audit_trigger() returns trigger
language plpgsql security definer set search_path = public as $$
declare rid text; ttl text;
begin
  rid := coalesce(to_jsonb(case when tg_op = 'DELETE' then old else new end)->>'id',
                  to_jsonb(case when tg_op = 'DELETE' then old else new end)->>'key',
                  to_jsonb(case when tg_op = 'DELETE' then old else new end)->>'name');
  ttl := coalesce(to_jsonb(case when tg_op = 'DELETE' then old else new end)->>'title',
                  to_jsonb(case when tg_op = 'DELETE' then old else new end)->>'name', '');
  insert into audit_log(user_id, action, table_name, row_id, summary)
    values (auth.uid(), lower(tg_op), tg_table_name, rid, left(ttl, 120));
  return null;
end $$;
revoke all on function public.audit_trigger() from public, anon, authenticated;

do $$ declare t text; begin
  foreach t in array array['site_settings','categories','events','news','gallery','spaces','page_contents'] loop
    execute format('drop trigger if exists audit_%1$s on public.%1$I', t);
    execute format('create trigger audit_%1$s after insert or update or delete on public.%1$I for each row execute function public.audit_trigger()', t);
  end loop;
end $$;

create or replace function public.touch_updated_at() returns trigger language plpgsql as
$$ begin new.updated_at := now(); return new; end $$;
drop trigger if exists touch_events on public.events;
create trigger touch_events before update on public.events for each row execute function public.touch_updated_at();
drop trigger if exists touch_news on public.news;
create trigger touch_news before update on public.news for each row execute function public.touch_updated_at();

------------------------------------------------------------------ úložiště fotografií
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 10485760, array['image/jpeg','image/png','image/webp','image/gif','image/avif'])
on conflict (id) do update set public = true, file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif','image/avif'];

drop policy if exists media_public_read on storage.objects;
create policy media_public_read on storage.objects for select to anon, authenticated using (bucket_id = 'media');
drop policy if exists media_admin_insert on storage.objects;
create policy media_admin_insert on storage.objects for insert to authenticated with check (bucket_id = 'media' and public.is_admin());
drop policy if exists media_admin_update on storage.objects;
create policy media_admin_update on storage.objects for update to authenticated using (bucket_id = 'media' and public.is_admin()) with check (bucket_id = 'media' and public.is_admin());
drop policy if exists media_admin_delete on storage.objects;
create policy media_admin_delete on storage.objects for delete to authenticated using (bucket_id = 'media' and public.is_admin());
