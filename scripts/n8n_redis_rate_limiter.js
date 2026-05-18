// This script is meant for an n8n Code Node.
// It implements basic rate limiting using Redis to prevent API abuse and cost spikes.

// Expected input: customer_phone from the incoming Twilio webhook
const phone = $input.item.json.body.From;

// Since n8n Code nodes can't natively perform async Redis calls easily without custom modules,
// this acts as a pseudo-code logic placeholder for an n8n Redis Node check.
// In practice, use the native n8n Redis Node before this Code node to GET and INCR the key.

const currentHits = $input.item.json.redis_hits || 0;
const RATE_LIMIT_MAX = 50; // Max messages per 24 hours

if (currentHits > RATE_LIMIT_MAX) {
    return {
        json: {
            allowed: false,
            reason: "Rate limit exceeded. Too many messages sent in 24 hours.",
            phone: phone
        }
    };
}

return {
    json: {
        allowed: true,
        currentHits: currentHits + 1,
        phone: phone
    }
};
