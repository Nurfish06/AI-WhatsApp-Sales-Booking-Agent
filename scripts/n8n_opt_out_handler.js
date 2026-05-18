// This script is meant to be pasted into an n8n Code Node for the Main Router.
// It checks if the incoming message contains an opt-out keyword.

const messageBody = $input.item.json.body.Body;
const phone = $input.item.json.body.From;

if (!messageBody) {
    return { json: { isOptOut: false } };
}

// Common opt-out keywords based on WhatsApp and Twilio standards
const optOutKeywords = ["STOP", "UNSUBSCRIBE", "REMOVE", "OPT OUT", "NO MORE MESSAGES"];

// Normalize message for checking
const normalizedMessage = messageBody.trim().toUpperCase();

const isOptOut = optOutKeywords.includes(normalizedMessage);

return {
    json: {
        isOptOut: isOptOut,
        phone: phone,
        originalMessage: messageBody
    }
};
