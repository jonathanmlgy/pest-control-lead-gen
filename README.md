# 🦟 AI-Powered Lead Generation System
### For Pest Control Business — Built with n8n, Apify, Groq, Supabase & Telegram

---

## 📌 Overview

An end-to-end AI automation system that scrapes Google Maps for potential pest control clients, qualifies them using an LLM, stores them in a vector database, and lets you query leads in plain English through Telegram.

Built as a portfolio project to demonstrate real-world AI automation engineering skills including data pipelines, LLM decision-making, vector search, and RAG-lite patterns.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SCRAPER WORKFLOW                         │
│                                                             │
│  Manual Trigger                                             │
│       ↓                                                     │
│  Apify (Google Maps Scraper)                                │
│  "restaurants Cavite", "offices Imus", "warehouses Cavite"  │
│       ↓                                                     │
│  Loop Over Items (batch size: 1)                            │
│       ↓                                                     │
│  Supabase GET → duplicate check                             │
│       ↓                                                     │
│  IF node → exists? skip : continue                          │
│       ↓                                                     │
│  AI Agent (Groq llama3) → score + categorize lead           │
│       ↓                                                     │
│  Code Node → parse AI JSON output                           │
│       ↓                                                     │
│  Supabase CREATE → save lead                                │
│       ↓                                                     │
│  Gemini Embedding API → generate vector                     │
│       ↓                                                     │
│  Supabase UPDATE → save embedding to lead record            │
│       ↓                                                     │
│  Loop back                                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  TELEGRAM BOT WORKFLOW                      │
│                                                             │
│  Telegram Trigger                                           │
│  "Find restaurants in Cavite"                               │
│       ↓                                                     │
│  Gemini Embedding API → convert query to vector             │
│       ↓                                                     │
│  Supabase RPC → match_leads() vector similarity search      │
│       ↓                                                     │
│  IF node → leads found? continue : send no results message  │
│       ↓                                                     │
│  AI Agent → format leads into clean readable response       │
│       ↓                                                     │
│  Telegram → send response back to user                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **n8n** | Workflow automation and orchestration |
| **Apify** | Google Maps scraping via `compass~crawler-google-places` |
| **Groq** (llama3-3-70b) | LLM for lead scoring and categorization |
| **Google Gemini** | Generating text embeddings (`text-embedding-004`) |
| **Supabase** | PostgreSQL database + pgvector for vector search |
| **Telegram Bot** | Natural language query interface |

---

## ✨ Key Features

### 1. Automated Lead Scraping
- Scrapes Google Maps for businesses likely to need pest control
- Targets restaurants, offices, warehouses, hotels, schools
- Configurable search keywords and locations

### 2. AI Lead Qualification
- Each lead is scored 1-10 by an LLM
- Automatically categorized (restaurant, warehouse, office, etc.)
- Status assigned: `hot`, `warm`, or `cold`
- Scoring considers: business type, phone availability, rating, review count

### 3. Intelligent Duplicate Detection
- Checks Supabase before saving each lead
- Skips existing leads automatically
- Prevents duplicate entries across multiple runs

### 4. Vector Embeddings
- Each lead generates a rich semantic description
- Converted to a 768-dimension vector using Gemini embeddings
- Stored in Supabase pgvector for semantic search

### 5. Natural Language Querying via Telegram
- Ask questions in plain English
- Vector similarity search finds semantically relevant leads
- AI formats results into clean, mobile-friendly responses

---

## 📊 Database Schema

```sql
create table leads (
  id              bigint primary key generated always as identity,
  business_name   text,
  address         text,
  phone           text,
  website         text,
  email           text,
  rating          numeric,
  reviews_count   integer,
  category        text,
  ai_score        integer,
  ai_reason       text,
  status          text default 'uncontacted',
  search_text     text,
  embedding       vector(768),
  created_at      timestamp default now()
);
```

---

## 🔍 Vector Search Function

```sql
create or replace function match_leads(
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  id bigint,
  business_name text,
  address text,
  phone text,
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
```

---

## 🤖 AI Scoring Logic

The AI Agent evaluates each business on:

```
Base Score by Business Type:
- 8-10 (hot):  restaurants, food businesses, warehouses, hotels, schools, hospitals
- 5-7  (warm): offices, retail stores, commercial buildings
- 1-4  (cold): sari-sari stores, solo practitioners, residential

Score Boosts:
+2 points → has a phone number
+1 point  → has 10+ reviews
+1 point  → rating above 4.0
+1 point  → has a website
```

---

## 💬 Telegram Bot Usage

Send natural language queries to the bot:

```
✅ Good queries (semantic search):
"Find food businesses in Cavite"
"Show me places that handle food"
"Find businesses similar to restaurants"
"Show me commercial establishments in Tagaytay"
"Find places where hygiene matters"

ℹ️ Combined queries (semantic + filter):
"Find hot leads in Cavite"
"Show me warm leads"
"Find uncontacted businesses"
```

### Example Response:
```
🏢 Antonio's Restaurant
📍 Tagaytay City, Cavite
📞 +63912345678
⭐ Score: 9/10
🔥 Status: hot

🏢 Pinocchio Pizza & Wine
📍 Amadeo, Cavite
📞 +63945678901
⭐ Score: 8/10
🔥 Status: hot
```

---

## 🚀 Setup Guide

### Prerequisites
- n8n Cloud account
- Apify account + API token
- Groq API key
- Google Gemini API key
- Supabase account
- Telegram Bot token (via @BotFather)

### 1. Supabase Setup
```sql
-- Enable pgvector
create extension if not exists vector;

-- Run the leads table SQL
-- Run the match_leads function SQL
-- Run the vector index SQL
```

### 2. Import n8n Workflows
- Import `scraper-workflow.json`
- Import `telegram-bot-workflow.json`
- Import `error-notifications-workflow.json`

### 3. Configure Credentials
Add these credentials in n8n:
- Apify API token
- Groq API key
- Google Gemini API key
- Supabase URL + secret key
- Telegram Bot token

### 4. Run
- Trigger the scraper workflow manually
- Start the Telegram bot workflow
- Message your bot to query leads

---

## 🗂️ Project Structure

```
pest-control-lead-gen/
├── workflows/
│   ├── scraper-workflow.json
│   ├── telegram-bot-workflow.json
│   └── error-notifications-workflow.json
├── supabase/
│   ├── schema.sql
│   ├── match_leads_function.sql
│   └── vector_index.sql
└── README.md
```

---

## 🧠 Concepts Demonstrated

| Concept | Implementation |
|---------|---------------|
| **Data Pipeline** | Apify → n8n → Supabase |
| **LLM Integration** | Groq scoring and categorizing leads |
| **Agentic Design** | AI handles reasoning, n8n handles operations |
| **Vector Database** | Supabase pgvector with 768-dim embeddings |
| **RAG-lite Pattern** | Telegram query → vector search → AI response |
| **Semantic Search** | match_leads() cosine similarity function |
| **API Integration** | 5 external APIs orchestrated in one system |
| **Error Handling** | Try/catch, IF nodes, fallback messages |
| **Real World Use Case** | Actual pest control business problem solved |

---

## 🔮 Future Improvements (V3)

- [ ] Full RAG with pest control knowledge base
- [ ] Review text analysis for pest complaint detection
- [ ] Lead similarity scoring
- [ ] Personalized outreach message generation
- [ ] Webhook trigger instead of manual
- [ ] Lead status update via Telegram
- [ ] Analytics dashboard

---

## 👤 Author

Built by Jonathan as a portfolio project demonstrating AI automation engineering skills.

---

## 📝 License

MIT
