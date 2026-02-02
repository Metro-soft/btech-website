/**
 * AI Agent Controller
 * "The Headquarters"
 * 
 * This module allows the AI to:
 * 1. Analyze data
 * 2. Send "AI_INSIGHT" notifications
 * 3. Receive user feedback
 */

const { GoogleGenerativeAI } = require('@google/generative-ai');
const NotificationService = require('../../shared/services/notification.service');

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

// @desc    Wake up the agent (Test Endpoint)
// @route   GET /api/ai/ping
exports.ping = async (req, res) => {
    res.json({ message: "Gemini Agent is ONLINE", status: "ONLINE", provider: "Google Gemini" });
};

// @desc    Trigger a manual analysis (Example)
// @route   POST /api/ai/analyze
exports.analyze = async (req, res) => {
    // Debug Log
    console.log('AI Analyze Request from User:', req.user);

    // Validating ID
    const userId = req.user.id || req.user._id;

    // --- SEED SAMPLE DATA (Retained for Demo purposes, can be upgraded to Gemini later) ---
    const samples = [
        {
            type: 'AI_INSIGHT',
            title: 'Anomalous Transaction Detected',
            message: 'Transaction #TXN-998 has an unusually high value compared to average.',
            options: { isAiGenerated: true, priority: 'HIGH', aiActionSuggestion: 'Audit Transaction' }
        },
        {
            type: 'FINANCE',
            title: 'Payment Received',
            message: 'M-PESA payment of KES 15,000 received from Client X.',
            options: { priority: 'NORMAL' }
        },
        {
            type: 'AI_INSIGHT',
            title: 'Performance Tip',
            message: 'Most users log in at 9:00 AM. Scheduled communications sent then have 20% higher open rates.',
            options: { isAiGenerated: true, aiActionSuggestion: 'Schedule Blast' }
        }
    ];

    // Send all samples
    for (const s of samples) {
        await NotificationService.send(userId, s.type, s.title, s.message, s.options);
    }

    res.json({ message: "Seed data generated", count: samples.length });
};

// @desc    Generate a notification template based on goal and tone
// @route   POST /api/ai/generate-template
exports.generateTemplate = async (req, res) => {
    try {
        const { goal, tone } = req.body;

        if (!process.env.GEMINI_API_KEY) {
            return res.status(500).json({ message: 'Gemini API Key is missing in server configuration.' });
        }

        const prompt = `
            You are an expert copywriter for a business system.
            Goal: Write a short, professional notification message for: "${goal}".
            Tone: ${tone || 'PROFESSIONAL'}.
            
            Return ONLY a valid JSON object with no markdown formatting, no code blocks, and no extra text.
            Format:
            {
                "title": "A short, catchy title (max 40 chars)",
                "body": "The message body (max 160 chars). Use {{name}} as a placeholder for the user's name."
            }
        `;

        const result = await model.generateContent(prompt);
        const response = await result.response;
        let text = response.text();

        // Cleanup: Remove markdown code blocks if Gemini mimics the prompt structure too well
        text = text.replace(/```json/g, '').replace(/```/g, '').trim();

        let generatedData;
        try {
            generatedData = JSON.parse(text);
        } catch (e) {
            console.error("AI JSON Parse Error:", text);
            // Fallback if JSON fails
            generatedData = {
                title: "New Notification",
                body: text.substring(0, 150)
            };
        }

        res.json({
            success: true,
            data: generatedData
        });

    } catch (error) {
        console.error("Gemini API Error:", error);
        res.status(500).json({ message: 'AI Generation failed', error: error.message });
    }
};
