# AI WhatsApp Sales & Booking Agent

A 24/7 AI-powered virtual sales representative that lives in WhatsApp. It instantly engages inbound leads, intelligently qualifies them against custom business criteria, books appointments into live calendars, and seamlessly hands off to humans when necessary.

## 🚀 Key Features

- **Instant Inbound Response:** Never miss a WhatsApp message.
- **Smart Lead Qualification:** Dynamically scores leads based on business rules.
- **Automated Scheduling:** Integrates with Google Calendar to suggest and book available slots.
- **Human Escalation:** Graceful handoff to staff via Slack/Email for complex queries or hot leads.
- **Multi-Tenant Architecture:** Scalable design for supporting multiple client accounts simultaneously.
- **Self-Healing:** Built-in error handling and recovery workflows.

## 🏗️ Architecture

- **Gateway:** Twilio WhatsApp API
- **Orchestration:** n8n (Self-hosted via Docker)
- **AI Engine:** OpenAI `gpt-4o`
- **Database:** PostgreSQL 16 (Conversation persistence, multi-tenant configs)
- **Cache / Locks:** Redis 7

## 📂 Quick Start

*Internal design documents and architectural specs are kept private in the `.gitignore` via the `docs/` folder.*

1. **Copy Environment Variables:** 
   ```bash
   cp docker/.env.example docker/.env
   ```
   *Fill in your Twilio, OpenAI, and Postgres credentials.*
2. **Start Services:** 
   ```bash
   cd docker && docker-compose up -d
   ```
3. **Run Health Check:** 
   ```bash
   ./scripts/health-check.sh
   ```
4. **Testing APIs:**
   Import the Postman collection located at `docs/postman/AI_WhatsApp_Agent.postman_collection.json` to simulate inbound webhook traffic and test integrations.

## 🔒 Security

- Zero hardcoded credentials. Uses n8n's encrypted vault.
- PII is securely handled and masked in logs.
- All webhook endpoints strictly validate the `X-Twilio-Signature`.

---
*Built for Phase 1 MVP deployment.*
