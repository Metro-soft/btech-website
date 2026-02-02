const cron = require('node-cron');
const Application = require('../models/Application');

// Schedule: Daily at 09:00
const crmJob = cron.schedule('0 9 * * *', async () => {
    console.log('📢 CRM Job Started: ' + new Date().toISOString());

    try {
        // Step 1: Calculate Target Date (Today - 11 Months)
        const today = new Date();
        const targetDate = new Date(today.setMonth(today.getMonth() - 11));
        
        // Date Range for that day
        const startOfDay = new Date(targetDate.setHours(0,0,0,0));
        const endOfDay = new Date(targetDate.setHours(23,59,59,999));

        // Step 2: Find Orders expiring soon
        const orders = await Application.find({
            status: 'COMPLETED',
            createdAt: { $gte: startOfDay, $lte: endOfDay }
        });

        if (orders.length === 0) {
            console.log('CRM: No renewals found for today.');
            return;
        }

        // Step 3: Trigger Notifications
        for (const order of orders) {
            // Emulate Notification Service call
            // eventBus.emit('SEND_SMS', { ... })
            console.log(`CRM Reminder: Sending SMS to Client of Order #${order._id} for Renewal.`);
        }

        console.log(`✅ CRM Job Processed ${orders.length} reminders.`);

    } catch (err) {
        console.error('❌ CRM Job Failed:', err);
    }
});

module.exports = crmJob;
