CREATE TABLE clients (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_name   VARCHAR(255) NOT NULL,
    whatsapp_number VARCHAR(20) NOT NULL UNIQUE,
    twilio_number   VARCHAR(20) NOT NULL,
    timezone        VARCHAR(50) DEFAULT 'UTC',
    business_hours  JSONB DEFAULT '{"monday":{"open":"09:00","close":"17:00"},"tuesday":{"open":"09:00","close":"17:00"},"wednesday":{"open":"09:00","close":"17:00"},"thursday":{"open":"09:00","close":"17:00"},"friday":{"open":"09:00","close":"17:00"},"saturday":null,"sunday":null}',
    brand_voice     VARCHAR(20) DEFAULT 'professional',
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE client_config (
    client_id       UUID REFERENCES clients(id) ON DELETE CASCADE,
    config_key      VARCHAR(100) NOT NULL,
    config_value    JSONB NOT NULL,
    updated_at      TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (client_id, config_key)
);

CREATE TABLE conversations (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id           UUID REFERENCES clients(id) ON DELETE CASCADE,
    customer_phone      VARCHAR(20) NOT NULL,
    customer_name       VARCHAR(100),
    twilio_channel_sid  VARCHAR(100),
    current_stage       VARCHAR(50) DEFAULT 'greeting',
    lead_score          INTEGER DEFAULT 0,
    lead_status         VARCHAR(20) DEFAULT 'new',
    lead_qualification  JSONB DEFAULT '{}',
    sentiment           VARCHAR(20),
    sentiment_score     FLOAT,
    escalation_status   BOOLEAN DEFAULT false,
    escalation_reason   VARCHAR(100),
    opted_out           BOOLEAN DEFAULT false,
    opted_out_at        TIMESTAMP,
    appointment_booked  BOOLEAN DEFAULT false,
    appointment_date    TIMESTAMP,
    calendar_event_id   VARCHAR(100),
    conversation_history JSONB DEFAULT '[]',
    total_messages      INTEGER DEFAULT 0,
    first_contact       TIMESTAMP DEFAULT NOW(),
    last_contact        TIMESTAMP DEFAULT NOW(),
    is_active           BOOLEAN DEFAULT true,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_conv_client ON conversations(client_id);
CREATE INDEX idx_conv_phone ON conversations(customer_phone);
CREATE INDEX idx_conv_active ON conversations(is_active) WHERE is_active = true;
CREATE INDEX idx_conv_lead_status ON conversations(client_id, lead_status);
CREATE INDEX idx_conv_last_contact ON conversations(last_contact);

CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    direction       VARCHAR(10) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    message_body    TEXT NOT NULL,
    message_type    VARCHAR(20) DEFAULT 'text',
    media_url       TEXT,
    twilio_sid      VARCHAR(100),
    ai_intent       VARCHAR(50),
    ai_confidence   FLOAT,
    ai_sentiment    VARCHAR(20),
    processing_time_ms INTEGER,
    error_occurred  BOOLEAN DEFAULT false,
    error_message   TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_msg_conv ON messages(conversation_id);
CREATE INDEX idx_msg_created ON messages(created_at);
CREATE INDEX idx_msg_twilio_sid ON messages(twilio_sid);

CREATE TABLE escalations (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id     UUID REFERENCES conversations(id) ON DELETE CASCADE,
    trigger_reason      VARCHAR(100) NOT NULL,
    trigger_message     TEXT,
    priority            VARCHAR(20) DEFAULT 'medium',
    escalated_to        VARCHAR(100),
    escalated_at        TIMESTAMP DEFAULT NOW(),
    acknowledged_by     VARCHAR(100),
    acknowledged_at     TIMESTAMP,
    resolved_at         TIMESTAMP,
    resolution_notes    TEXT,
    timeout_occurred    BOOLEAN DEFAULT false,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE bookings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id     UUID REFERENCES conversations(id) ON DELETE SET NULL,
    client_id           UUID REFERENCES clients(id) ON DELETE CASCADE,
    customer_phone      VARCHAR(20) NOT NULL,
    customer_name       VARCHAR(100),
    service_type        VARCHAR(100),
    appointment_start   TIMESTAMP NOT NULL,
    appointment_end     TIMESTAMP NOT NULL,
    calendar_event_id   VARCHAR(100) NOT NULL,
    status              VARCHAR(20) DEFAULT 'confirmed',
    cancellation_reason TEXT,
    reminder_24h_sent   BOOLEAN DEFAULT false,
    reminder_2h_sent    BOOLEAN DEFAULT false,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_book_client ON bookings(client_id);
CREATE INDEX idx_book_start ON bookings(appointment_start);
CREATE INDEX idx_book_status ON bookings(status);

CREATE TABLE audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id       UUID REFERENCES clients(id),
    event_type      VARCHAR(50) NOT NULL,
    event_data      JSONB,
    severity        VARCHAR(20) DEFAULT 'info',
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_client ON audit_log(client_id);
CREATE INDEX idx_audit_type ON audit_log(event_type);
CREATE INDEX idx_audit_created ON audit_log(created_at);

-- MVP Initial Data Setup (Hardcoded configuration for Single Client)
INSERT INTO clients (id, business_name, whatsapp_number, twilio_number, timezone, brand_voice)
VALUES ('00000000-0000-0000-0000-000000000001', 'Dubai Smiles Dental Clinic', '+971501234567', '+971551234567', 'Asia/Dubai', 'professional');

INSERT INTO client_config (client_id, config_key, config_value)
VALUES 
('00000000-0000-0000-0000-000000000001', 'services', '["Teeth Cleaning", "Whitening", "Checkup"]'),
('00000000-0000-0000-0000-000000000001', 'qualification_questions', '[{"id": "service_type", "question": "What dental service are you interested in?", "type": "select", "options_from": "services", "weight": 20}, {"id": "urgency", "question": "How soon are you looking to visit us?", "type": "select", "options": ["As soon as possible", "This week", "This month"], "weight": 30}]'),
('00000000-0000-0000-0000-000000000001', 'booking', '{"calendar_id": "primary", "appointment_duration_minutes": 30, "buffer_minutes": 15, "max_bookings_per_day": 20}');
