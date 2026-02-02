const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env
dotenv.config();

const BASE_URL = 'http://localhost:5000/api';
let adminToken = '';
let templateId = '';

const login = async (email, password) => {
    const res = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Login failed');
    return data.token;
};

const createTemplate = async () => {
    console.log('📝 Creating Template...');
    const res = await fetch(`${BASE_URL}/notifications/templates`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
            title: 'Test Broadcast',
            category: 'SYSTEM',
            body: 'This is a test notification from the automated script.',
            action: { route: '/home', payload: {} }
        })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Create Template failed');
    console.log('✅ Template Created:', data._id);
    return data._id;
};

const sendBroadcast = async (tmplId) => {
    console.log('loud_sound Sending Broadcast...');
    const res = await fetch(`${BASE_URL}/notifications/broadcast`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
            audience: 'CLIENTS',
            title: 'Script Broadcast',
            message: 'Hello from the test script!',
            templateId: tmplId,
            type: 'SYSTEM'
        })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Broadcast failed');
    console.log('✅ Broadcast Success:', data);
};

const verifyInDatabase = async () => {
    console.log('🔍 Verifying in Database...');
    await mongoose.connect(process.env.MONGO_URI);

    // Find the client user "Alice Client" seeded in seed.js
    const User = require('./src/shared/models/User');
    const Notification = require('./src/shared/models/Notification'); // Assuming path

    const client = await User.findOne({ email: 'client@btech.com' });
    if (!client) throw new Error('Client user not found in DB');

    // Find latest notification
    const notif = await Notification.findOne({ user: client._id }).sort({ createdAt: -1 });

    if (notif && notif.title === 'Script Broadcast') {
        console.log('✅ VERIFIED: Notification found in DB for client:', client.email);
        console.log('   ID:', notif._id);
        console.log('   Title:', notif.title);
        console.log('   Message:', notif.message);
    } else {
        console.error('❌ FAILED: Notification not found or mismatch.');
        if (notif) console.log('   Latest found:', notif.title);
    }

    await mongoose.disconnect();
};

const run = async () => {
    try {
        // 1. Login Admin
        console.log('🔐 Logging in as Admin...');
        adminToken = await login('admin@btech.com', 'password123');
        console.log('✅ Logged in.');

        // 2. Create Template
        templateId = await createTemplate();

        // 3. Broadcast
        await sendBroadcast(templateId);

        // 4. Wait for async processing
        console.log('⏳ Waiting 2s for processing...');
        await new Promise(r => setTimeout(r, 2000));

        // 5. Verify
        await verifyInDatabase();

    } catch (err) {
        console.error('❌ Test Failed:', err);
    }
};

run();
