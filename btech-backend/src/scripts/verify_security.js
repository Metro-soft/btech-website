const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

const runSecurityTest = async () => {
    console.log('🚀 --- STARTING SECURITY VERIFICATION --- 🚀\n');

    // 1. SQL Injection Test
    console.log('💉 Testing SQL Injection Detection...');
    try {
        await axios.post(`${BASE_URL}/auth/login`, {
            email: "admin@btech.com' OR '1'='1",
            password: "password123"
        });
        console.log('❌ Failed: SQLi Request was NOT blocked (200 OK)');
    } catch (err) {
        if (err.response && err.response.status === 403) {
            console.log('✅ Success: SQLi Request Blocked (403 Forbidden)');
        } else {
            console.log(`⚠️  Warning: Unexpected status ${err.response?.status}`);
            console.log(err.message);
        }
    }

    // 2. DOS / Rate Limit Test
    console.log('\n🌊 Testing DOS / Rate Limiting (Sending 110 reqs)...');
    let blocked = false;
    for (let i = 0; i < 110; i++) {
        try {
            await axios.get(`${BASE_URL}/services`); // Public endpoint
            if (i % 20 === 0) process.stdout.write('.'); // Progress bar
        } catch (err) {
            if (err.response && err.response.status === 429) {
                console.log(`\n✅ Success: Rate Limit Triggered at request #${i + 1} (429 Too Many Requests)`);
                blocked = true;
                break;
            }
        }
    }

    if (!blocked) {
        console.log('\n❌ Failed: Rate Limit NOT triggered after 110 requests.');
    }

    console.log('\n🏁 --- SECURITY VERIFICATION COMPLETE --- 🏁');
};

runSecurityTest();
