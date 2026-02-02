const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Models
const Transaction = require('../shared/models/Transaction');
const Application = require('../shared/models/Application');
const User = require('../shared/models/User');

dotenv.config({ path: path.join(__dirname, '../../.env') });

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');

        // 1. Check Total Applications
        const appCount = await Application.countDocuments();
        console.log('📄 Total Applications:', appCount);

        // 2. Check Services Aggregation
        const servicesStats = await Application.aggregate([
            {
                $group: {
                    _id: '$type',
                    count: { $sum: 1 }
                }
            }
        ]);
        console.log('📊 Services Stats (Raw Aggregation):', servicesStats);

        if (servicesStats.length === 0 && appCount > 0) {
            console.warn('⚠️  Applications exist but aggregation returned empty. Checking "type" field on first 5 apps:');
            const sampleApps = await Application.find().select('type status trackingNumber').limit(5);
            console.log(sampleApps);
        }

        // 3. Check Pending Withdrawals
        const pendingWithdrawals = await Transaction.countDocuments({
            category: 'WITHDRAWAL',
            status: 'PENDING'
        });
        console.log('⏳ Pending Withdrawals:', pendingWithdrawals);

        process.exit();
    } catch (err) {
        console.error('❌ Error:', err);
        process.exit(1);
    }
};

connectDB();
