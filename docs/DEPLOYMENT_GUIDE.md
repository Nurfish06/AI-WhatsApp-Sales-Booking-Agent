# AI WhatsApp Sales & Booking Agent — Full Deployment Guide

> **Audience:** Developer or system administrator deploying the system for the first time, or handing it off to a client team.
> **Time to complete:** ~60–90 minutes for a first-time deployment.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Clone & Configure the Repository](#2-clone--configure-the-repository)
3. [Configure Environment Variables](#3-configure-environment-variables)
4. [Start the Docker Stack](#4-start-the-docker-stack)
5. [Set Up n8n Credentials](#5-set-up-n8n-credentials)
6. [Import Workflows into n8n](#6-import-workflows-into-n8n)
7. [Configure the Twilio Webhook](#7-configure-the-twilio-webhook)
8. [Set Up the Database Schema](#8-set-up-the-database-schema)
9. [Activate All Workflows](#9-activate-all-workflows)
10. [Run the Postman Test Suite](#10-run-the-postman-test-suite)
11. [Onboard a New Client](#11-onboard-a-new-client)
12. [Monitoring & Maintenance](#12-monitoring--maintenance)
13. [Production Checklist](#13-production-checklist)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Prerequisites

Ensure the following are installed on your server or local machine before starting.

| Tool | Minimum Version | Install |
|------|----------------|---------|
| Docker | 24.x | https://docs.docker.com/get-docker/ |
| Docker Compose | 2.x | Bundled with Docker Desktop |
| Git | 2.x | https://git-scm.com |
| Node.js (for Newman testing) | 18.x | https://nodejs.org |
| Postman (optional GUI) | Latest | https://postman.com |

**External accounts required before starting:**

- ✅ **Twilio** — Account SID, Auth Token, and a WhatsApp-enabled sender number
- ✅ **OpenAI** — API key with GPT-4o access
- ✅ **Google Cloud** — Service account or OAuth credentials with Google Calendar API enabled
- ⬜ **Slack** — Incoming webhook URL (optional, for escalation alerts)
- ⬜ **Telegram** — Bot token and chat/group ID (optional, for escalation alerts)
- ⬜ **SMTP server** — Host, port, user, password (optional, for email reports)

---

## 2. Clone & Configure the Repository

```bash
git clone https://github.com/Nurfish06/AI-WhatsApp-Sales-Booking-Agent.git
cd AI-WhatsApp-Sales-Booking-Agent
```

---

## 3. Configure Environment Variables

Copy the example env file and fill in your real values.

```bash
cp docker/.env.example docker/.env
```

Open `docker/.env` in a text editor and set every value:

```env
# ─── PostgreSQL ───────────────────────────────────────────────
POSTGRES_DB=agent_db
POSTGRES_USER=agent_user
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD_HERE

# ─── n8n ──────────────────────────────────────────────────────
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=CHANGE_ME_N8N_PASSWORD
N8N_HOST=localhost           # Change to your domain in production
N8N_PORT=5678
N8N_PROTOCOL=http            # Change to https in production
WEBHOOK_URL=http://localhost:5678   # Change to your public URL

# ─── PgBouncer ────────────────────────────────────────────────
PGBOUNCER_DATABASE=agent_db
PGBOUNCER_USER=agent_user
PGBOUNCER_PASSWORD=CHANGE_ME_STRONG_PASSWORD_HERE

# ─── Redis ────────────────────────────────────────────────────
REDIS_PASSWORD=CHANGE_ME_REDIS_PASSWORD
```

> **Security rule:** Never commit `docker/.env` to Git. It is already in `.gitignore`.

---

## 4. Start the Docker Stack

```bash
cd docker
docker compose up -d
```

This starts four containers:

| Container | Service | Port |
|-----------|---------|------|
| `agent_n8n` | n8n workflow engine | 5678 |
| `agent_postgres` | PostgreSQL database | 5432 (internal) |
| `agent_pgbouncer` | Connection pooler | 6432 (internal) |
| `agent_redis` | Session cache + rate limiter | 6379 (internal) |

**Verify all containers are running:**

```bash
docker compose ps
```

All four should show `Up`. If any show `Exit`, check logs:

```bash
docker compose logs agent_n8n
docker compose logs agent_postgres
```

**Access n8n UI:**  
Open your browser → `http://localhost:5678`  
Log in with the credentials you set in `N8N_BASIC_AUTH_USER` and `N8N_BASIC_AUTH_PASSWORD`.

---

## 5. Set Up n8n Credentials

All secrets are stored **exclusively** in n8n's encrypted credential store. Never hardcode them in workflow files.

Navigate to: **n8n UI → Settings → Credentials → Add Credential**

### 5.1 Twilio Credential

| Field | Value |
|-------|-------|
| Credential Name | `Twilio Account` |
| Account SID | Your Twilio Account SID (starts with `AC`) |
| Auth Token | Your Twilio Auth Token |

### 5.2 OpenAI Credential

| Field | Value |
|-------|-------|
| Credential Name | `OpenAI Account` |
| API Key | Your OpenAI API Key (starts with `sk-`) |

### 5.3 PostgreSQL Credential

| Field | Value |
|-------|-------|
| Credential Name | `Postgres Account` |
| Host | `pgbouncer` ← **Use the PgBouncer container, not postgres directly** |
| Port | `6432` |
| Database | `agent_db` |
| User | `agent_user` |
| Password | Your `POSTGRES_PASSWORD` from `docker/.env` |
| SSL | Disabled (internal Docker network) |

### 5.4 Redis Credential

| Field | Value |
|-------|-------|
| Credential Name | `Redis account` |
| Host | `redis` |
| Port | `6379` |
| Password | Your `REDIS_PASSWORD` from `docker/.env` |

### 5.5 Google Calendar Credential

1. Go to **Google Cloud Console** → APIs & Services → Credentials
2. Create an **OAuth 2.0 Client ID** (Web Application type)
3. Add `http://localhost:5678/rest/oauth2-credential/callback` as an Authorized redirect URI
4. In n8n: **Add Credential → Google Calendar OAuth2 API**
5. Enter Client ID and Client Secret, then click **Connect** to complete OAuth flow

| Credential Name | `Google Calendar Account` |
|-----------------|--------------------------|

### 5.6 Slack Credential (Optional)

1. Go to https://api.slack.com/apps → Create App → Incoming Webhooks
2. Enable Incoming Webhooks and create one for your chosen channel
3. Copy the Webhook URL

| Field | Value |
|-------|-------|
| Credential Name | `Slack account` |
| Webhook URL | Your Slack Incoming Webhook URL |

### 5.7 Telegram Credential (Optional)

1. Message `@BotFather` on Telegram → `/newbot` → follow prompts
2. Copy the **Bot Token** given to you
3. Add the bot to your admin group/channel and make it an admin
4. Get your Chat ID: visit `https://api.telegram.org/bot<TOKEN>/getUpdates` and find `chat.id`

| Field | Value |
|-------|-------|
| Credential Name | `Telegram Bot API` |
| Access Token | Your Telegram Bot Token |

Store the `TELEGRAM_CHAT_ID` value — you will need it when configuring the client record in the database.

### 5.8 SMTP Email Credential (Optional)

| Field | Value |
|-------|-------|
| Credential Name | `SMTP Account` |
| Host | e.g. `smtp.gmail.com` or your SMTP host |
| Port | `587` (TLS) or `465` (SSL) |
| User | Your SMTP username / email address |
| Password | Your SMTP password or app-specific password |

---

## 6. Import Workflows into n8n

All 9 workflow files are in the `n8n-workflows/` directory. Import them one by one.

### Import steps (for each file):

1. In n8n UI → **Workflows** → **Add Workflow** (top right)
2. Click the **⋮ menu** → **Import from File**
3. Select the file from `n8n-workflows/`
4. After import, **re-link credentials**: open each node that has a credential field, click the credential dropdown, and select the correct credential you created in Step 5
5. Save the workflow

### Import order (important — dependencies first):

| Order | File | Description |
|-------|------|-------------|
| 1st | `06_Notification_Service.json` | No dependencies |
| 2nd | `05_Escalation_Handler.json` | Depends on 06 |
| 3rd | `03_Qualification_Scorer.json` | No dependencies |
| 4th | `04_Calendar_Booking.json` | No dependencies |
| 5th | `02_Conversation_Engine.json` | No dependencies |
| 6th | `01_Main_Router.json` | Depends on 02, 03, 04, 05, 06 |
| 7th | `07_Monitoring_Heartbeat.json` | Depends on 06 |
| 8th | `08_Monthly_Report_Generator.json` | Depends on 06 |
| 9th | `09_Data_Retention_Policy.json` | No dependencies |

### Update Cross-Workflow IDs

After importing, several workflows call each other using hardcoded IDs that say `REPLACE_WITH_*_ID`. You must update these:

1. In n8n, open each workflow and note its **Workflow ID** from the URL (e.g., `http://localhost:5678/workflow/42` → ID is `42`)
2. Open `01_Main_Router.json` → find nodes referencing `REPLACE_WITH_CONVERSATION_ENGINE_ID` and `REPLACE_WITH_NOTIFICATION_SERVICE_ID` and update them with the real IDs
3. Open `05_Escalation_Handler.json` → update `REPLACE_WITH_NOTIFICATION_SERVICE_ID`
4. Open `07_Monitoring_Heartbeat.json` → update `REPLACE_WITH_NOTIFICATION_SERVICE_ID`

---

## 7. Configure the Twilio Webhook

This tells Twilio to send all incoming WhatsApp messages to your n8n instance.

### Step 1: Get your Webhook URL

In n8n, open `01_Main_Router` → click the **Webhook node** → copy the **Production URL**.  
It will look like: `https://your-domain.com/api/whatsapp/webhook`

> **Important:** For production, your n8n instance must be publicly accessible via HTTPS. Use a reverse proxy (Nginx/Caddy) or a service like Ngrok for local testing:
> ```bash
> ngrok http 5678
> # Copy the https://xxxx.ngrok.io URL
> ```

### Step 2: Set the Webhook in Twilio

1. Log into **Twilio Console** → Messaging → Services → (your WhatsApp sender)
2. Or go to: **Phone Numbers → Manage → Active Numbers → your number**
3. Scroll to **Messaging Configuration**
4. Set **A MESSAGE COMES IN** → Webhook → `https://your-domain.com/api/whatsapp/webhook`
5. Method: `HTTP POST`
6. Save

### Step 3: Configure Twilio Sandbox (Development Only)

If using the Twilio WhatsApp Sandbox for testing:
1. **Twilio Console → Messaging → Try it out → Send a WhatsApp message**
2. Set the **When a message comes in** webhook to your URL
3. Have customers send the sandbox join code first (e.g., `join <word>-<word>`)

---

## 8. Set Up the Database Schema

Connect to the PostgreSQL container and run the schema setup:

```bash
docker exec -it agent_postgres psql -U agent_user -d agent_db
```

Then paste and execute the following SQL:

```sql
-- Clients table (multi-tenant)
CREATE TABLE IF NOT EXISTS client_configs (
  client_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  whatsapp_number VARCHAR(20) UNIQUE NOT NULL,
  business_name VARCHAR(255) NOT NULL,
  brand_voice TEXT,
  calendar_id VARCHAR(255),
  max_bookings_per_day INTEGER DEFAULT 10,
  scoring_thresholds JSONB DEFAULT '{"hot": 80, "warm": 50}',
  scoring_rules JSONB DEFAULT '{}',
  notification_preferences JSONB DEFAULT '{"slack_enabled": true, "telegram_enabled": false}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES client_configs(client_id),
  customer_phone VARCHAR(20) NOT NULL,
  state VARCHAR(50) DEFAULT 'new',
  ai_turn_count INTEGER DEFAULT 0,
  collected_data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id),
  role VARCHAR(10) NOT NULL,  -- 'user' or 'assistant'
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES client_configs(client_id),
  conversation_id UUID REFERENCES conversations(id),
  event_id VARCHAR(255),
  booking_time TIMESTAMPTZ,
  booking_date DATE GENERATED ALWAYS AS (booking_time::date) STORED,
  status VARCHAR(20) DEFAULT 'confirmed',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Escalations table
CREATE TABLE IF NOT EXISTS escalations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id),
  priority VARCHAR(20) DEFAULT 'medium',
  status VARCHAR(50) DEFAULT 'awaiting_acknowledgment',
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dead Letter Queue
CREATE TABLE IF NOT EXISTS dead_letter_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type VARCHAR(50),
  entity_id UUID,
  error_reason TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- System Logs (synced from Redis)
CREATE TABLE IF NOT EXISTS system_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  log_entry TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_customer_phone ON conversations(customer_phone);
CREATE INDEX IF NOT EXISTS idx_conversations_client_id ON conversations(client_id);
CREATE INDEX IF NOT EXISTS idx_bookings_booking_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_escalations_status ON escalations(status);
```

Exit psql with `\q`.

---

## 9. Activate All Workflows

Back in the n8n UI:

1. Open each workflow
2. Toggle the **Active** switch (top right) to ON
3. Confirm the activation dialog

**Activation order:**

| Order | Workflow | Trigger Type |
|-------|----------|-------------|
| 1st | `06_Notification_Service` | On-call (no auto-trigger) |
| 2nd | `05_Escalation_Handler` | On-call |
| 3rd | `03_Qualification_Scorer` | On-call |
| 4th | `04_Calendar_Booking` | On-call |
| 5th | `02_Conversation_Engine` | On-call |
| 6th | `01_Main_Router` | **Webhook** — activating this opens the live endpoint |
| 7th | `07_Monitoring_Heartbeat` | Schedule (every 5 min) |
| 8th | `08_Monthly_Report_Generator` | Schedule (monthly) |
| 9th | `09_Data_Retention_Policy` | Schedule (nightly 2 AM) |

> **Note:** `01_Main_Router` activation makes the system live. Do this last, after all other workflows are active and tested.

---

## 10. Run the Postman Test Suite

### Option A — Postman GUI

1. Open Postman → **Import** → select both files:
   - `docs/postman/AI_WhatsApp_Agent.postman_collection.json`
   - `docs/postman/Local_Dev_Environment.json`
2. Select the **AI WhatsApp Agent — Local Dev** environment from the dropdown
3. Set the `valid_test_signature` variable (see below)
4. Click **Run Collection**

### Option B — Command Line (Newman)

```bash
npm install -g newman

newman run docs/postman/AI_WhatsApp_Agent.postman_collection.json \
  -e docs/postman/Local_Dev_Environment.json \
  --reporters cli,json \
  --reporter-json-export test-results.json
```

### Computing the valid_test_signature

The `valid_test_signature` is an HMAC-SHA1 of your Twilio Auth Token + the full webhook URL + sorted POST parameters. For local testing, you have two options:

**Option 1 — Temporarily disable signature validation** in `01_Main_Router` (development only, re-enable before going live)

**Option 2 — Compute it with Node.js:**

```js
const crypto = require('crypto');

const authToken = 'YOUR_TWILIO_AUTH_TOKEN';
const url = 'http://localhost:5678/api/whatsapp/webhook';
const params = {
  Body: 'Hello',
  From: 'whatsapp:+971501234567',
  NumMedia: '0',
  To: 'whatsapp:+12025550001'
};

// Sort params alphabetically and concatenate
const sortedKeys = Object.keys(params).sort();
let str = url;
for (const key of sortedKeys) str += key + params[key];

const sig = crypto.createHmac('sha1', authToken).update(str).digest('base64');
console.log(sig); // Paste this into the Postman environment variable
```

**Expected test results:**
- Tests 01–03 (Health & Security): All green ✅
- Tests 04 (Rate limiting): May show expected 429 ✅
- Tests 05 (Failure paths): All `no 500` assertions pass ✅
- Test 07.01 (OpenAI direct): Requires a real `OPENAI_API_KEY` in the environment

---

## 11. Onboard a New Client

Each business that uses the agent is a "client". Onboard them with a SQL INSERT:

```sql
INSERT INTO client_configs (
  whatsapp_number,
  business_name,
  brand_voice,
  calendar_id,
  max_bookings_per_day,
  scoring_thresholds,
  scoring_rules,
  notification_preferences
) VALUES (
  'whatsapp:+12025550001',            -- Your Twilio WhatsApp number for this client
  'Dubai Smiles Dental Clinic',
  'Warm, professional, and reassuring. Always use the customer name.',
  'your-google-calendar-id@group.calendar.google.com',
  12,                                  -- Max bookings per day
  '{"hot": 80, "warm": 50}',
  '{
    "service_type": {"weight": 30, "values": {"teeth_whitening": 3, "cleaning": 2, "implants": 3}},
    "budget":       {"weight": 40, "values": {"under_500": 1, "500_2000": 2, "over_2000": 3}},
    "urgency":      {"weight": 30, "values": {"asap": 3, "this_week": 2, "flexible": 1}}
  }',
  '{
    "slack_enabled": true,
    "telegram_enabled": true,
    "email_enabled": true,
    "telegram_chat_id": "-1001234567890"
  }'
);
```

After inserting, send a test WhatsApp message to the configured number to verify the full flow end-to-end.

---

## 12. Monitoring & Maintenance

### Health Dashboard

The `07_Monitoring_Heartbeat` workflow runs every 5 minutes automatically. It will alert via the Notification Service if Postgres, Redis, or OpenAI becomes unreachable.

### View Audit Logs

```bash
# Live Redis logs
docker exec -it agent_redis redis-cli LRANGE audit_logs 0 49

# PostgreSQL logs (synced every 5 min)
docker exec -it agent_postgres psql -U agent_user -d agent_db \
  -c "SELECT * FROM system_logs ORDER BY created_at DESC LIMIT 50;"
```

### View Dead Letter Queue

```bash
docker exec -it agent_postgres psql -U agent_user -d agent_db \
  -c "SELECT * FROM dead_letter_queue WHERE status = 'pending';"
```

### Database Backup

```bash
bash scripts/backup-db.sh
```

Backups are saved to `db_backups/` (excluded from git).

### Scaling Up

For high traffic:
1. Increase `pool_size` in `docker/pgbouncer.ini`
2. Scale n8n workers: add `N8N_CONCURRENCY_PRODUCTION_LIMIT=20` to `docker/.env`
3. Deploy Redis Cluster if rate limiting needs to span multiple nodes

---

## 13. Production Checklist

Before going live with a real client, verify every item:

### Security
- [ ] `docker/.env` is not committed to Git
- [ ] All passwords are strong (16+ chars, mixed case, symbols)
- [ ] Twilio Signature Validation is **enabled** in `01_Main_Router`
- [ ] n8n is behind HTTPS (SSL certificate installed)
- [ ] `N8N_PROTOCOL=https` and `WEBHOOK_URL=https://...` in `.env`
- [ ] No credentials hardcoded in any workflow node

### Functionality
- [ ] All 9 workflows are **Active** in n8n
- [ ] All cross-workflow IDs (`REPLACE_WITH_*`) have been updated
- [ ] PostgreSQL schema has been applied (all tables exist)
- [ ] A test client row exists in `client_configs`
- [ ] End-to-end test passed: WhatsApp message → AI response received
- [ ] Escalation test passed: "speak to a human" → Slack/Telegram alert received
- [ ] Booking test passed: calendar event created in Google Calendar

### Monitoring
- [ ] `07_Monitoring_Heartbeat` is active and running every 5 minutes
- [ ] `09_Data_Retention_Policy` is active and scheduled for 2 AM
- [ ] Slack/Telegram alerts are working (test by temporarily killing Redis)
- [ ] Postman test suite passes with real signature

### Data & Privacy
- [ ] GDPR retention policy is configured (90-day anonymization active)
- [ ] PII is masked in all logs (`+971******4567` format)
- [ ] Database backups are configured and tested

---

## 14. Troubleshooting

### n8n can't connect to Postgres

**Symptom:** Postgres nodes fail with "connection refused"  
**Check:** Are you connecting to `pgbouncer:6432`? Not `postgres:5432`.  
**Fix:** In each Postgres credential, set Host=`pgbouncer`, Port=`6432`.

### Twilio returns 11200 (HTTP retrieval failure)

**Symptom:** Twilio can't reach your webhook  
**Check:** Is n8n publicly accessible via HTTPS?  
**Fix:** Use Ngrok (`ngrok http 5678`) or configure a real domain with SSL.

### Signature validation always fails

**Symptom:** All requests return 401/403 in production  
**Check:** Is `WEBHOOK_URL` in `.env` exactly matching the URL Twilio is calling?  
**Fix:** The signature is computed against the exact URL. Even a trailing slash difference will cause failure. Copy the exact URL from the Twilio console.

### OpenAI returns 429 (rate limit)

**Symptom:** Conversation Engine escalates due to API error  
**Check:** Is your OpenAI usage tier sufficient?  
**Fix:** Upgrade your OpenAI plan or request a rate limit increase. The retry logic (3 attempts) handles transient spikes.

### Google Calendar shows "insufficient permissions"

**Symptom:** Calendar Booking fails when creating events  
**Fix:** Re-authenticate the Google OAuth credential in n8n. Ensure the OAuth scope includes `https://www.googleapis.com/auth/calendar`.

### Redis connection refused

**Symptom:** Rate limiter or audit log nodes fail  
**Check:** `docker compose ps` — is `agent_redis` Up?  
**Fix:** `docker compose restart agent_redis`

### Workflow execution stuck / timing out

**Symptom:** `01_Main_Router` takes > 800ms and Twilio retries  
**Check:** Is the downstream workflow (Conversation Engine) taking too long?  
**Fix:** Ensure `01_Main_Router` uses **fire-and-forget** execution for the Conversation Engine (do not use `waitForResult`).

---

## Quick Reference

```
n8n UI:          http://localhost:5678
n8n Credentials: Settings → Credentials
Workflow Files:  n8n-workflows/*.json
Postman Tests:   docs/postman/AI_WhatsApp_Agent.postman_collection.json
Env File:        docker/.env
DB Schema:       Section 8 of this guide
Logs (Redis):    docker exec agent_redis redis-cli LRANGE audit_logs 0 49
Logs (Postgres): SELECT * FROM system_logs ORDER BY created_at DESC;
```

---

*Last updated: 2026-05-19 | Maintained by the AI WhatsApp Agent team*
