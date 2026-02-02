const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

async function verifyPatch() {
    console.log('--- Starting PATCH Verification ---');

    // 1. Login
    let token = '';
    try {
        console.log('Attempting Login...');
        const res = await axios.post(`${BASE_URL}/auth/login`, {
            email: 'admin@btech.com',
            password: 'password123'
        });
        token = res.data.token;
        console.log('✅ Login Successful');
    } catch (e) {
        console.log('Login failed. Creating test admin...');
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

    // 2. Create a Dummy User to test on
    let userId = '';
    let originalName = 'Patch Test User';
    try {
        console.log('\n--- Creating Dummy User ---');
        // Use a unique email to avoid conflict
        const userEmail = `patch_test_${Date.now()}_${Math.floor(Math.random() * 1000)}@test.com`;
        const userRes = await axios.post(`${BASE_URL}/auth/register`, {
            name: originalName,
            email: userEmail,
            password: 'password123',
            role: 'client'
        });

        // Try to get ID from response, otherwise fetch list
        if (userRes.data.user && userRes.data.user._id) {
            userId = userRes.data.user._id;
            console.log(`✅ User Created & ID captured: ${userId}`);
        } else {
            console.log('User created (token returned). Fetching list to find ID...');

            const listRes = await axios.get(`${BASE_URL}/admin/dashboard/users`, { headers });

            let users = [];
            if (Array.isArray(listRes.data)) {
                users = listRes.data;
            } else if (listRes.data && Array.isArray(listRes.data.users)) {
                users = listRes.data.users;
            } else {
                console.error('❌ Unexpected Users API response format:', listRes.data);
                return;
            }

            // Find by the unique email we just made
            const targetUser = users.find(u => u.email === userEmail);

            if (targetUser) {
                userId = targetUser._id;
                console.log(`✅ Target User Found in list: ${userId}`);
            } else {
                console.error('❌ Created user not found in list');
                return;
            }
        }

    } catch (e) {
        console.error('❌ Create/Fetch User Failed:', e.response?.data || e.message);
        return;
    }

    // 3. Test PATCH endpoint
    try {
        console.log(`\n--- Testing PATCH /users/${userId} ---`);
        const newName = originalName + ' (Updated)';

        const res = await axios.patch(
            `${BASE_URL}/admin/dashboard/users/${userId}`,
            { name: newName },
            { headers }
        );

        // Check if response has user object or just the updated user
        const updatedUser = res.data.user || res.data;

        if (res.status === 200 && updatedUser.name === newName) {
            console.log('✅ PATCH Success! Name updated to:', updatedUser.name);

            // Revert
            console.log('Reverting change...');
            await axios.patch(
                `${BASE_URL}/admin/dashboard/users/${userId}`,
                { name: originalName },
                { headers }
            );
            console.log('✅ Revert Successful');
        } else {
            console.error('❌ PATCH responded but Verification Failed. Res:', res.data);
        }

    } catch (e) {
        console.error('❌ PATCH Request Failed:', e.response?.data || e.message);
    }

    console.log('\n--- Verification Complete ---');
}

verifyPatch();
