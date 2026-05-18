// This script is meant to be pasted into an n8n Code Node.
// It verifies the X-Twilio-Signature header to ensure the request is authentically from Twilio.

const crypto = require('crypto');

// 1. Get the incoming headers and body
const headers = $input.item.json.headers;
const body = $input.item.json.body;

// 2. Get the Twilio Auth Token (from your n8n environment variables or credentials)
// Make sure to pass this into the node securely!
const twilioAuthToken = $env.TWILIO_AUTH_TOKEN;

// 3. The URL of your webhook exactly as configured in Twilio
const webhookUrl = $env.WEBHOOK_URL + "twilio-inbound";

if (!headers['x-twilio-signature']) {
    throw new Error("Missing Twilio Signature Header. Request Rejected.");
}

const twilioSignature = headers['x-twilio-signature'];

// 4. Sort the POST parameters alphabetically
const sortedKeys = Object.keys(body).sort();

// 5. Append each key and value to the URL
let dataToSign = webhookUrl;
sortedKeys.forEach(key => {
    dataToSign += key + body[key];
});

// 6. Hash using HMAC-SHA256 and base64 encode
const expectedSignature = crypto
    .createHmac('sha256', twilioAuthToken)
    .update(dataToSign)
    .digest('base64');

// 7. Validate
if (expectedSignature !== twilioSignature) {
    // Return an error flag so the router can immediately terminate
    return {
        json: {
            isValid: false,
            error: "Invalid Twilio Signature. Potential spoofing attack."
        }
    };
}

// 8. If valid, return the original data and an isValid flag
return {
    json: {
        isValid: true,
        body: body
    }
};
