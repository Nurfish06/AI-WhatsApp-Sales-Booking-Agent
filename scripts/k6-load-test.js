import http from 'k6/http';
import { check, sleep } from 'k6';

// Run with: k6 run scripts/k6-load-test.js

export const options = {
    stages: [
        { duration: '30s', target: 20 },  // Ramp up to 20 users over 30s
        { duration: '1m', target: 20 },   // Hold at 20 users for 1m
        { duration: '10s', target: 0 },   // Ramp down to 0 users
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
        http_req_failed: ['rate<0.01'],   // Error rate should be less than 1%
    },
};

export default function () {
    const url = 'http://localhost:5679/webhook-test/twilio-inbound';
    
    // Simulate Twilio Webhook Payload
    const payload = JSON.stringify({
        MessageSid: `SM${Math.random().toString(36).substring(7)}`,
        From: "whatsapp:+1234567890",
        To: "whatsapp:+0987654321",
        Body: "I need to book an appointment.",
        NumMedia: "0"
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
            'X-Twilio-Signature': 'mock_signature'
        },
    };

    const res = http.post(url, payload, params);

    // Verify response
    check(res, {
        'status is 200': (r) => r.status === 200,
    });

    sleep(1); // Wait 1 second between requests per virtual user
}
