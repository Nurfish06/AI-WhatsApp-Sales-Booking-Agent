# AI WhatsApp Sales & Booking Agent

> **24/7 AI-powered sales agent that lives in WhatsApp.** It instantly engages inbound leads, qualifies them against custom business rules, books appointments into live Google Calendars, and escalates to a human when it matters most — via Slack, Telegram, or Email.

---

## ✨ What It Does

A customer sends a WhatsApp message to your business number at 2 AM. Within 2 seconds:

1. 🛡️ **Security** — The webhook validates the Twilio signature and checks rate limits
2. 🧠 **AI Conversation** — GPT-4o responds with the right tone for your brand
3. 📊 **Lead Scoring** — Dynamic multi-criteria scoring based on budget, urgency, and intent
4. 📅 **Booking** — Checks live calendar availability and locks the slot (double-booking proof)
5. 🔔 **Alerts** — Hot leads and escalations instantly notify your team on Slack + Telegram
6. 🧑‍💼 **Handoff** — If the customer asks for a human, a full context package is sent and a human takes over

All of this runs on your own infrastructure — **no SaaS lock-in, no per-message fees.**

---

## 🏗️ Architecture

```
WhatsApp Customer
      │
      ▼
Twilio WhatsApp API ──► 01_Main_Router (Webhook + Sig Validation + Rate Limit)
                                │
              ┌─────────────────┼──────────────────┐
              ▼                 ▼                  ▼
   02_Conversation_Engine  04_Calendar_Booking  05_Escalation_Handler
     (OpenAI GPT-4o)        (Google Calendar)   (Slack/Telegram/Email)
              │                                      │
              ▼                                      ▼
   03_Qualification_Scorer              06_Notification_Service
     (Lead Scoring)                      (Multi-Channel Alerts)
              │
              ▼
   07_Monitoring_Heartbeat    09_Data_Retention_Policy    08_Monthly_Report_Generator
     (Health + DLQ, 5min)       (GDPR Cleanup, 2AM)        (Analytics, Monthly)
```

| Layer | Technology |
|-------|-----------|
| **WhatsApp Gateway** | Twilio Programmable Messaging |
| **Workflow Engine** | n8n (self-hosted, Docker) |
| **AI Engine** | OpenAI GPT-4o (JSON mode, temperature-controlled) |
| **Database** | PostgreSQL 16 via PgBouncer connection pool |
| **Cache / Rate Limiter** | Redis 7 |
| **Calendar** | Google Calendar API |
| **Alerts** | Slack, Telegram Bot, SMTP Email, Twilio SMS |

---

## 🚀 Quick Start

**Full instructions → [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md)**

```bash
# 1. Clone
git clone https://github.com/Nurfish06/AI-WhatsApp-Sales-Booking-Agent.git
cd AI-WhatsApp-Sales-Booking-Agent

# 2. Configure environment
cp docker/.env.example docker/.env
# → Edit docker/.env with your credentials

# 3. Start the stack
cd docker
docker compose up -d

# 4. Open n8n
# http://localhost:5678

# 5. Import workflows (n8n-workflows/*.json) in order:
# 06 → 05 → 03 → 04 → 02 → 01 → 07 → 08 → 09

# 6. Run test suite
npx newman run docs/postman/AI_WhatsApp_Agent.postman_collection.json \
  -e docs/postman/Local_Dev_Environment.json
```

---

## 📂 Project Structure

```
├── docker/
│   ├── docker-compose.yml          # n8n + PostgreSQL + PgBouncer + Redis
│   └── .env.example                # Template — copy to .env and fill in
│
├── n8n-workflows/
│   ├── 01_Main_Router.json         # Entry point (Twilio webhook + rate limiting)
│   ├── 02_Conversation_Engine.json # GPT-4o AI with retry + fallback logic
│   ├── 03_Qualification_Scorer.json# Dynamic lead scoring engine
│   ├── 04_Calendar_Booking.json    # Atomic booking with double-booking prevention
│   ├── 05_Escalation_Handler.json  # Human handoff with DLQ fallback
│   ├── 06_Notification_Service.json# Slack/Telegram/Email routing hub
│   ├── 07_Monitoring_Heartbeat.json# Health checks + DLQ processing (every 5 min)
│   ├── 08_Monthly_Report_Generator.json
│   └── 09_Data_Retention_Policy.json  # GDPR anonymization (nightly 2 AM)
│
├── docs/
│   ├── DEPLOYMENT_GUIDE.md         # ← Full setup, credentials, go-live checklist
│   └── postman/
│       ├── AI_WhatsApp_Agent.postman_collection.json  # 20 automated tests
│       └── Local_Dev_Environment.json                 # Postman env variables
│
└── scripts/
    ├── backup-db.sh                # Database backup
    └── deploy.sh                   # Deployment helper
```

---

## 🔒 Security Principles

- **Zero hardcoded secrets** — All credentials stored in n8n's encrypted vault
- **Twilio Signature Validation** — Every inbound webhook is cryptographically verified
- **Redis Rate Limiting** — Per-phone and global limits prevent abuse and billing spikes
- **Prompt Injection Defense** — System prompts are hardened against DAN, role-play, and override attacks
- **PII Masking** — Phone numbers logged as `+971******4567`
- **GDPR Compliance** — Automatic 90-day data anonymization via `09_Data_Retention_Policy`
- **Double-Booking Prevention** — Atomic calendar re-check at the moment of booking confirmation

---

## 🛡️ Resilience Features

Every external API call has:
- **3 automatic retries** with exponential backoff
- **Explicit failure paths** — no silent failures
- **Fallback responses** that keep the customer informed
- **Dead Letter Queue** — failed escalations are persisted and retried every 5 minutes

---

## 📋 n8n Credentials Required

| Credential | Required | Purpose |
|------------|----------|---------|
| `Twilio Account` | ✅ Yes | WhatsApp gateway |
| `OpenAI Account` | ✅ Yes | GPT-4o AI engine |
| `Postgres Account` | ✅ Yes | Conversation storage |
| `Redis account` | ✅ Yes | Rate limiting + session cache |
| `Google Calendar Account` | ⬜ Optional | Appointment booking |
| `Slack account` | ⬜ Optional | Escalation alerts |
| `Telegram Bot API` | ⬜ Optional | Instant mobile alerts |
| `SMTP Account` | ⬜ Optional | Email reports |

> **Full credential setup steps with field-by-field instructions → [`docs/DEPLOYMENT_GUIDE.md §5`](docs/DEPLOYMENT_GUIDE.md)**

---

## 🧪 Testing

```bash
# Install Newman (Postman CLI runner)
npm install -g newman

# Run the full 20-test suite
newman run docs/postman/AI_WhatsApp_Agent.postman_collection.json \
  -e docs/postman/Local_Dev_Environment.json \
  --reporters cli,json \
  --reporter-json-export test-results.json
```

Tests cover: health checks, Twilio signature validation, prompt injection, opt-out (STOP), customer booking flow, rate limiting, 5 failure paths, and edge cases (Unicode, XSS, media, long messages).

---

*Production-ready. Built with n8n + OpenAI + Twilio. Self-hosted, multi-tenant, GDPR-compliant.*
