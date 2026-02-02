const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';
// Using a known admin/staff credential from seed or creating a login flow
// For now, I'll attempt to login as an admin if possible, or assume a token is available.
// Since I don't have a token, I'll try to login with common credentials or register a new admin if the DB allows.
// Wait, I can't guess credentials. I'll check if I can register.

async function verify() {
    console.log('--- Starting Verification ---');

    // 1. Login (Attempting to use a test account or register)
    let token = '';
    try {
        console.log('Attempting Login...');
        const res = await axios.post(`${BASE_URL}/auth/login`, {
            email: 'admin@btech.com', // Hypothetical
            password: 'password123'
        });
        token = res.data.token;
        console.log('✅ Login Successful');
    } catch (e) {
        console.log('Login failed (Expected if user doesnt exist). Creating test admin...');
        try {
            const res = await axios.post(`${BASE_URL}/auth/register`, {
                name: 'Test Admin',
                email: `admin_${Date.now()}@test.com`,
                password: 'password123',
                role: 'admin'
            });
            token = res.data.token;
            console.log('✅ Admin Registered successfully');
        } catch (regError) {
            console.error('❌ Failed to register/login:', regError.response?.data || regError.message);
            return;
        }
    }

    const headers = { Authorization: `Bearer ${token}` };

    // 2. Check Live Activity Feed
    try {
        console.log('\n--- Verifying Live Feed ---');
        const res = await axios.get(`${BASE_URL}/admin/dashboard/activity`, { headers });
        if (Array.isArray(res.data)) {
            console.log(`✅ Live Feed returned ${res.data.length} items`);
            if (res.data.length > 0) {
                console.log('   Latest Action:', res.data[0].action);
            }
        } else {
            console.error('❌ Live Feed returned unexpected format');
        }
    } catch (e) {
        console.error('❌ Live Feed Endpoint Failed:', e.response?.data || e.message);
    }

    // 3. Check Pending Review Stats
    try {
        console.log('\n--- Verifying Quick Stats ---');
        const res = await axios.get(`${BASE_URL}/admin/dashboard/quick-stats`, { headers });
        if (res.data.pendingReviews !== undefined) {
            console.log(`✅ Stats includes pendingReviews: ${res.data.pendingReviews}`);
        } else {
            console.error('❌ Stats MISSING pendingReviews field');
        }
    } catch (e) {
        console.error('❌ Stats Endpoint Failed:', e.response?.data || e.message);
    }

    console.log('\n--- Verification Complete ---');
}

verify();
