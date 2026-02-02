const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

async function verifyCrud() {
    console.log('--- Starting CRUD Verification ---');

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
    let originalName = 'CRUD Test User';
    try {
        console.log('\n--- Creating Dummy User ---');
        const userEmail = `crud_test_${Date.now()}_${Math.floor(Math.random() * 1000)}@test.com`;
        const userRes = await axios.post(`${BASE_URL}/auth/register`, {
            name: originalName,
            email: userEmail,
            password: 'password123',
            role: 'client'
        });

        if (userRes.data.user && userRes.data.user._id) {
            userId = userRes.data.user._id;
            console.log(`✅ User Created & ID captured: ${userId}`);
        } else { // Fallback if no user object in response (Auth token only)
            console.log('Fetching list to find ID...');
            const listRes = await axios.get(`${BASE_URL}/admin/dashboard/users`, { headers });
            const list = Array.isArray(listRes.data) ? listRes.data : listRes.data.users;
            const targetUser = list.find(u => u.email === userEmail);
            if (targetUser) {
                userId = targetUser._id;
                console.log(`✅ Found Created User ID: ${userId}`);
            } else {
                throw new Error('User created but not found in list');
            }
        }
    } catch (e) {
        console.error('❌ Create User Failed:', e.response?.data || e.message);
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

        const updatedUser = res.data.user || res.data;
        if (res.status === 200 && updatedUser.name === newName) {
            console.log('✅ PATCH Success! Name updated to:', updatedUser.name);
        } else {
            throw new Error(`PATCH Failed. Expected ${newName}, got ${updatedUser.name}`);
        }

    } catch (e) {
        console.error('❌ PATCH Request Failed:', e.response?.data || e.message);
        // Do not return, attempt delete anyway
    }

    // 4. Test DELETE endpoint
    try {
        console.log(`\n--- Testing DELETE /users/${userId} ---`);
        const res = await axios.delete(
            `${BASE_URL}/admin/dashboard/users/${userId}`,
            { headers }
        );

        if (res.status === 200) {
            console.log('✅ DELETE Request Successful');

            // Verify it's actually gone
            console.log('Verifying user is gone...');
            try {
                // Try to update it again, should fail with 404 or just check list
                await axios.patch(
                    `${BASE_URL}/admin/dashboard/users/${userId}`,
                    { name: 'Should Fail' },
                    { headers }
                );
                console.error('❌ User still exists (PATCH succeeded after DELETE)');
            } catch (checkErr) {
                if (checkErr.response && checkErr.response.status === 404) {
                    console.log('✅ Verified: User 404 Not Found');
                } else {
                    console.log('✅ Verified: User access failed as expected');
                }
            }

        } else {
            console.error('❌ DELETE Failed status:', res.status);
        }

    } catch (e) {
        console.error('❌ DELETE Request Failed:', e.response?.data || e.message);
    }

    console.log('\n--- CRUD Verification Complete ---');
}

verifyCrud();
