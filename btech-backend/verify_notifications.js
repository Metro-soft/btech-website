const http = require('http');

// Configuration
const BASE_URL = 'http://localhost:5000';
const CREDENTIALS = {
    email: 'admin@btech.com',
    password: 'password123'
};

// Helper to make HTTP requests
const request = (method, path, body = null, token = null) => {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api' + path, // Ensure prefix matches your routes
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };

        if (token) {
            options.headers['Authorization'] = `Bearer ${token}`;
        }

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    resolve({ statusCode: res.statusCode, body: parsed });
                } catch (e) {
                    resolve({ statusCode: res.statusCode, body: data });
                }
            });
        });

        req.on('error', (e) => reject(e));

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
};

const runTests = async () => {
    console.log('🧪 Starting Notification Endpoint Tests...\n');

    try {
        // 1. LOGIN
        console.log('1️⃣  Logging in as Admin...');
        const loginRes = await request('POST', '/auth/login', CREDENTIALS);

        if (loginRes.statusCode !== 200 || !loginRes.body.token) {
            console.error('❌ Login Failed:', loginRes.body);
            process.exit(1);
        }
        const token = loginRes.body.token;
        console.log('✅ Login Successful. Token received.\n');

        // 1.5 GET USER NOTIFICATIONS (NEW ENDPOINT)
        console.log('1️⃣.5️⃣  Testing GET /notifications (New Endpoint)...');
        const userNotifRes = await request('GET', '/notifications', null, token);

        if (userNotifRes.statusCode === 200) {
            console.log(`✅ User Notifications fetched: Found ${Array.isArray(userNotifRes.body) ? userNotifRes.body.length : 0} notifications.`);
        } else {
            console.error('❌ Fetch User Notifications Failed:', userNotifRes.body);
        }
        console.log('');

        // 2. GET TEMPLATES
        console.log('2️⃣  Testing GET /notifications/templates...');
        const templatesRes = await request('GET', '/notifications/templates', null, token);

        if (templatesRes.statusCode === 200) {
            console.log(`✅ Templates fetched: Found ${Array.isArray(templatesRes.body) ? templatesRes.body.length : 0} templates.`);
        } else {
            console.error('❌ Fetch Templates Failed:', templatesRes.body);
        }
        console.log('');

        // 3. BROADCAST
        console.log('3️⃣  Testing POST /notifications/broadcast...');
        const broadcastPayload = {
            audience: 'ALL_USERS',
            title: 'Test Broadcast from Script',
            message: 'This is a test notification verifying the wiring.',
            type: 'SYSTEM'
        };

        const broadcastRes = await request('POST', '/notifications/broadcast', broadcastPayload, token);

        if (broadcastRes.statusCode === 200) {
            console.log('✅ Broadcast sent successfully:', broadcastRes.body);
        } else {
            console.error('❌ Broadcast Failed:', broadcastRes.body);
        }
        console.log('');

        // 4. CREATE TEMPLATE (Optional/Cleanup)
        console.log('4️⃣  Testing POST /notifications/templates...');
        const templatePayload = {
            title: 'Test Template',
            body: 'This is a test template content.',
            category: 'SYSTEM'
        };
        const createRes = await request('POST', '/notifications/templates', templatePayload, token);

        if (createRes.statusCode === 201) {
            console.log('✅ Template created successfully:', createRes.body);
        } else {
            console.error('❌ Create Template Failed:', createRes.body);
        }


    } catch (e) {
        console.error('❌ Test Script Error:', e);
    }
};

runTests();
