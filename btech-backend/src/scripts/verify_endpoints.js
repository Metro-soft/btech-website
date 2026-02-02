const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

const USERS = {
    client: { email: 'client@btech.com', password: 'password123', role: 'client' },
    staff: { email: 'staff@btech.com', password: 'password123', role: 'staff' },
    admin: { email: 'admin@btech.com', password: 'password123', role: 'admin' }
};

const login = async (role) => {
    try {
        const creds = USERS[role];
        console.log(`🔑 Logging in as ${role.toUpperCase()} (${creds.email})...`);
        const res = await axios.post(`${BASE_URL}/auth/login`, {
            email: creds.email,
            password: creds.password
        });
        console.log(`✅ ${role.toUpperCase()} Login Success`);
        return res.data.token;
    } catch (err) {
        console.error(`❌ ${role.toUpperCase()} Login Failed:`, err.response?.data?.message || err.message);
        return null;
    }
};

const testEndpoint = async (role, token, method, endpoint, description) => {
    try {
        const config = { headers: { Authorization: `Bearer ${token}` } };
        let res;
        if (method === 'GET') res = await axios.get(`${BASE_URL}${endpoint}`, config);
        // Add other methods if needed

        console.log(`✅ [${role.toUpperCase()}] ${description}: Success (${res.status})`);
        // console.log(`   Data:`, res.data); // Uncomment for verbose
    } catch (err) {
        console.error(`❌ [${role.toUpperCase()}] ${description} FAILED:`, err.response?.status, err.response?.data?.message || err.message);
    }
};

const runTests = async () => {
    console.log('🚀 --- STARTING ENDPOINT VERIFICATION --- 🚀\n');

    // 1. CLIENT SILO TEST
    const clientToken = await login('client');
    if (clientToken) {
        await testEndpoint('client', clientToken, 'GET', '/client/orders', 'Get My Orders');
        await testEndpoint('client', clientToken, 'GET', '/client/finance/wallet', 'Get Wallet');
    }

    // 2. STAFF SILO TEST
    const staffToken = await login('staff');
    if (staffToken) {
        await testEndpoint('staff', staffToken, 'GET', '/staff/dashboard', 'Get Dashboard Stats');
        await testEndpoint('staff', staffToken, 'GET', '/staff/tasks', 'Get My Tasks');
        await testEndpoint('staff', staffToken, 'GET', '/staff/finance/earnings', 'Get Earnings');
    }

    // 3. ADMIN SILO TEST
    const adminToken = await login('admin');
    if (adminToken) {
        await testEndpoint('admin', adminToken, 'GET', '/admin/workflow/applications', 'Get All Applications');
        await testEndpoint('admin', adminToken, 'GET', '/admin/finance/transactions', 'Get All Transactions');
    }

    // 4. SHARED KERNEL TEST
    console.log('\n--- SHARED KERNEL TESTS ---');
    if (clientToken) {
        await testEndpoint('client', clientToken, 'GET', '/services', 'Get Services (Public)');
    }

    console.log('\n🏁 --- VERIFICATION COMPLETE --- 🏁');
};

runTests();
