const cron = require('node-cron');
const Application = require('../models/Application'); // Verify path
const mongoose = require('mongoose');

// Schedule: Every Friday at 17:00
const payrollJob = cron.schedule('0 17 * * 5', async () => {
    console.log('💰 Payroll Job Started: ' + new Date().toISOString());
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Step 1: Find UNPAID Completed Orders
        const orders = await Application.find({ 
            status: 'COMPLETED', 
            'payment.commissionStatus': 'UNPAID' 
        }).session(session);

        if (orders.length === 0) {
            console.log('Payroll: No pending commissions.');
            await session.commitTransaction();
            return;
        }

        // Step 2: Group by Staff
        const payouts = {};
        for (const order of orders) {
            const staffId = order.assignedTo; 
            if (!staffId) continue;

            if (!payouts[staffId]) payouts[staffId] = 0;
            payouts[staffId] += (order.payment.staffPay || 0);
        }

        // Step 3: Log Payouts (In real app, create Payout Record)
        for (const [staffId, amount] of Object.entries(payouts)) {
            console.log(`Processing Payout for ${staffId}: KES ${amount}`);
            // await PayoutModel.create([{ staff: staffId, amount }], { session });
        }

        // Step 4: Bulk Update
        const orderIds = orders.map(o => o._id);
        await Application.updateMany(
            { _id: { $in: orderIds } },
            { $set: { 'payment.commissionStatus': 'PAID' } },
            { session }
        );

        await session.commitTransaction();
        console.log('✅ Payroll Job Completed Successfully.');

    } catch (err) {
        await session.abortTransaction();
        console.error('❌ Payroll Job Failed:', err);
    } finally {
        session.endSession();
    }
});

module.exports = payrollJob;
