// This script is meant for an n8n Code Node.
// It dynamically calculates the Lead Score based on the client_config and the AI's extracted answers.

const config = $input.item.json.client_config || {};
const collectedAnswers = $input.item.json.collected_answers || {};

let score = 0;
const questions = config.qualification_questions || [];

// Iterate through the configured questions
questions.forEach(q => {
    // If the AI successfully extracted an answer for this question ID
    if (collectedAnswers[q.id]) {
        // Add the configured weight to the total score
        // (In a more advanced setup, weight might depend on the specific answer, 
        // e.g., 'Immediate' = 30 pts, 'Next Month' = 10 pts)
        score += q.weight || 0;
    }
});

// Classify the lead based on dynamic thresholds
const hotThreshold = config.scoring?.hot_threshold || 80;
const warmThreshold = config.scoring?.warm_threshold || 50;

let status = "cold";
if (score >= hotThreshold) {
    status = "hot";
} else if (score >= warmThreshold) {
    status = "warm";
}

return {
    json: {
        lead_score: score,
        lead_status: status
    }
};
