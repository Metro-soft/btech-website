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

// @desc    Generate full service details (Description, Requirements, Form)
// @route   POST /api/ai/generate-service-full
exports.generateFullServiceDetails = async (req, res) => {
    try {
        const { title, category, userPrompt } = req.body;

        if (!process.env.GEMINI_API_KEY) {
            return res.status(500).json({ message: 'Gemini API Key is missing.' });
        }

        // Use user's custom prompt if provided, otherwise default to title-based generation
        const coreInstruction = userPrompt
            ? `Task: Create a complete service definition based on this request: "${userPrompt}".`
            : `Task: Create a complete service definition for a service named "${title}".`;

        const prompt = `
            Act as a Senior Business Analyst and System Architect.
            ${coreInstruction}
            
            Return STRICT JSON object with the following structure:
            {
                "title": "A short, clear, professional Service Name (e.g. 'KRA Tax Returns')",
                "category": "One of: ['KRA', 'HELB', 'Banking', 'ETA', 'KUCCPS', 'OTHER']",
                "layoutType": "One of: ['classic', 'compact', 'wizard', 'accordion', 'stepper']",
                "description": "A professional, attractive 2-3 sentence description of functionality.",
                "requirements": ["List of strings of required documents/items from the client"],
                "basePrice": 0,
                "formStructure": [
                    {
                        "type": "text | number | date | file | dropdown | checkbox | section",
                        "label": "Human readable label",
                        "name": "camelCaseName",
                        "required": true,
                        "options": ["Option 1", "Option 2"] // Only for dropdown
                    }
                ]
            }

            Example Response for "Visa Application":
            {
                "title": "International Visa Assistance",
                "category": "ETA",
                "layoutType": "wizard",
                "description": "Comprehensive visa application assistance service.",
                "requirements": ["Original Passport", "Passport Photos"],
                "basePrice": 5000,
                "formStructure": [
                    { "type": "section", "label": "Personal Details", "name": "section_personal" },
                    { "type": "text", "label": "Full Name", "name": "fullName", "required": true },
                    { "type": "date", "label": "Date of Birth", "name": "dob", "required": true },
                    { "type": "section", "label": "Travel Info", "name": "section_travel" },
                    { "type": "dropdown", "label": "Visa Type", "name": "visaType", "options": ["Tourist", "Business"], "required": true }
                ]
            }

            Rules:
            1. Analyze the input to determine the best "category".
            2. Choose the best "layoutType" based on the complexity.
            3. "formStructure" MUST contain at least 3-5 fields relevant to the service. DO NOT return an empty list.
            4. Use correct "type" from the list provided.
            5. "name" keys must be unique.
            6. Do NOT wrap result in markdown codes. Just raw JSON.
        `;

        const result = await model.generateContent(prompt);
        const response = await result.response;
        let text = response.text();

        // Cleanup
        text = text.replace(/```json/g, '').replace(/```/g, '').trim();

        const generatedData = JSON.parse(text);

        res.json({
            success: true,
            data: generatedData
        });

    } catch (error) {
        console.error("Gemini Full Service Gen Error:", error);
        res.status(500).json({ message: 'AI Generation failed', error: error.message });
    }
};

