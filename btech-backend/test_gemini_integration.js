require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function testGemini() {
    console.log("1. Checking Environment Request...");
    if (!process.env.GEMINI_API_KEY) {
        console.error("❌ Link Error: GEMINI_API_KEY not found in .env");
        return;
    }
    console.log("✅ API Key found.");

    console.log("2. Connecting to Google Gemini...");
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    // Verified working model: gemini-2.5-flash
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const goal = "Remind client to renew their subscription";
    const prompt = `
            You are an expert copywriter for a business system.
            Goal: Write a short, professional notification message for: "${goal}".
            Tone: PROFESSIONAL.
            
            Return ONLY a valid JSON object.
            Format:
            {
                "title": "Title",
                "body": "Body"
            }
        `;

    try {
        console.log("3. Sending Prompt to AI...");
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        console.log("\n--- AI RESPONSE ---");
        console.log(text);
        console.log("-------------------");
        console.log("\n✅ Test Passed! Gemini is integrated and responding.");
    } catch (error) {
        console.error("\n❌ Test Failed:", error.message);
    }
}

testGemini();
