require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function listAndTest() {
    if (!process.env.GEMINI_API_KEY) {
        console.error("❌ No API Key found in .env");
        return;
    }

    try {
        console.log("1. Fetching available models...");
        // Native fetch to bypass library abstractions for raw list
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${process.env.GEMINI_API_KEY}`);
        const data = await response.json();

        if (data.error) {
            console.error("❌ API Error:", data.error);
            return;
        }

        const contentModels = data.models.filter(m =>
            m.supportedGenerationMethods.includes('generateContent')
        );

        console.log(`\nFound ${contentModels.length} models that support 'generateContent':`);
        contentModels.forEach(m => console.log(` - ${m.name} (${m.displayName})`));

        console.log("\n2. Testing models one by one...");
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

        for (const m of contentModels) {
            // Strip 'models/' prefix if present for the SDK, although SDK usually handles both
            const modelName = m.name.replace('models/', '');
            console.log(`\n👉 Testing: ${modelName}`);

            try {
                const model = genAI.getGenerativeModel({ model: modelName });
                const result = await model.generateContent("Say 'OK'");
                const response = await result.response;
                console.log(`   ✅ SUCCESS! Response: ${response.text()}`);
                console.log(`   🏆 RECOMMENDED MODEL: ${modelName}`);
                return; // Stop after first success
            } catch (err) {
                console.log(`   ❌ Failed: ${err.message.split(']')[1] || err.message}`);
            }
        }

        console.log("\n❌ All models failed test.");

    } catch (error) {
        console.error("Fatal Error:", error);
    }
}

listAndTest();
