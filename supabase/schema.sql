-- ================================
-- 1. Enable pgvector extension
-- ================================
create extension if not exists vector;

-- ================================
-- 2. Create leads table
-- ================================
create table leads (
  id bigint primary key generated always as identity,
  business_name text,
  address text,
  phone text,
  website text,
  email text,
  rating numeric,
  reviews_count integer,
  category text,
  ai_score integer,
  ai_reason text,
  status text default 'uncontacted',
  embedding vector(1536),
  created_at timestamp default now()
);

-- ================================
-- 3. Create vector search function
-- ================================
create or replace function match_leads(
  query_embedding vector(1536),
  match_threshold float,
  match_count int
)
returns table (
  id bigint,
  business_name text,
  address text,
  phone text,
  website text,
  email text,
  rating numeric,
  reviews_count integer,
  category text,
  ai_score integer,
  ai_reason text,
  status text,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    leads.id,
    leads.business_name,
    leads.address,
    leads.phone,
    leads.website,
    leads.email,
    leads.rating,
    leads.reviews_count,
    leads.category,
    leads.ai_score,
    leads.ai_reason,
    leads.status,
    1 - (leads.embedding <=> query_embedding) as similarity
  from leads
  where 1 - (leads.embedding <=> query_embedding) > match_threshold
  order by similarity desc
  limit match_count;
end;
$$;

-- ================================
-- 4. Create vector index
-- ================================
create index on leads
using ivfflat (embedding vector_cosine_ops)
with (lists = 100);

-- ================================
-- 5. Add search_text column
-- (run this if table already exists)
-- ================================
alter table leads
add column if not exists search_text text;
