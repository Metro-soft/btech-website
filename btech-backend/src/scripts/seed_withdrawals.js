const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Transaction = require('../shared/models/Transaction');
const User = require('../shared/models/User');

dotenv.config();

const seedPendingWithdrawals = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('🌱 MongoDB Connected...');

        // Find a user to assign these to (Staff or Client)
        const user = await User.findOne({ email: 'client@btech.com' });
        if (!user) {
            console.error('❌ User client@btech.com not found. Run seed.js first.');
            process.exit(1);
        }

        const withdrawals = [
            {
                user: user._id,
                type: 'PAYMENT',
                category: 'WITHDRAWAL',
                amount: 7500,
                status: 'PENDING',
                method: 'MPESA',
                reference: `WD-${Date.now()}-1`,
                description: 'Urgent Withdrawal Request',
                metadata: { phone: '254712345678' }
            },
            {
                user: user._id,
                type: 'PAYMENT',
                category: 'WITHDRAWAL',
                amount: 3200,
                status: 'PENDING',
                method: 'BANK',
                reference: `WD-${Date.now()}-2`,
                description: 'Weekly Earnings Payout',
                metadata: { bank: 'KCB', account: '1234567890' }
            },
            {
                user: user._id,
                type: 'PAYMENT',
                category: 'WITHDRAWAL',
                amount: 15000,
                status: 'PENDING',
                method: 'MPESA',
                reference: `WD-${Date.now()}-3`,
                description: 'Large Withdrawal',
                metadata: { phone: '254799999999' }
            }
        ];

        await Transaction.insertMany(withdrawals);
        console.log(`✅ Added ${withdrawals.length} Pending Withdrawals correctly.`);
        process.exit();

    } catch (err) {
        console.error('❌ Seeding Failed:', err);
        process.exit(1);
    }
};

seedPendingWithdrawals();
