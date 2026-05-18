#!/bin/bash
# Admin Client Onboarding Script (Phase 2)
# Usage: ./onboard-client.sh --business-name "Name" --whatsapp-number "+1234" --twilio-number "+5678" --timezone "UTC"

set -e

# Default values
BUSINESS_NAME=""
WHATSAPP_NUMBER=""
TWILIO_NUMBER=""
TIMEZONE="UTC"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --business-name) BUSINESS_NAME="$2"; shift ;;
        --whatsapp-number) WHATSAPP_NUMBER="$2"; shift ;;
        --twilio-number) TWILIO_NUMBER="$2"; shift ;;
        --timezone) TIMEZONE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$BUSINESS_NAME" ] || [ -z "$WHATSAPP_NUMBER" ] || [ -z "$TWILIO_NUMBER" ]; then
    echo "Usage: ./onboard-client.sh --business-name \"Name\" --whatsapp-number \"+1234\" --twilio-number \"+5678\" [--timezone \"UTC\"]"
    exit 1
fi

echo "🚀 Onboarding new client: $BUSINESS_NAME"

# Generate a new UUID for the client
CLIENT_ID=$(cat /proc/sys/kernel/random/uuid || uuidgen)

# Prepare SQL
SQL="
INSERT INTO clients (id, business_name, whatsapp_number, twilio_number, timezone) 
VALUES ('$CLIENT_ID', '$BUSINESS_NAME', '$WHATSAPP_NUMBER', '$TWILIO_NUMBER', '$TIMEZONE');
"

# Execute in Postgres Container
echo "💾 Writing to PostgreSQL..."
docker exec -i agent_postgres psql -U n8n_user -d whatsapp_agent_db -c "$SQL"

echo "✅ Client onboarded successfully!"
echo "Client ID: $CLIENT_ID"
echo "Next step: Insert client_config for this client_id to finalize setup."
