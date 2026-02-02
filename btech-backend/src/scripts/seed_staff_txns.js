const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Transaction = require('../shared/models/Transaction');
const User = require('../shared/models/User');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

const seedStaffTxns = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        const staff = await User.findOne({ role: 'staff' });

        if (!staff) {
            console.log('No staff user found');
            process.exit(1);
        }

        console.log(`Seeding transactions for ${staff.name} (${staff._id})...`);

        const txns = [
            {
                user: staff._id,
                amount: 500,
                type: 'PAYMENT',
                category: 'SALARY',
                status: 'COMPLETED',
                reference: 'SALARY-001',
                method: 'BANK_TRANSFER',
                description: 'Monthly Salary',
                date: new Date(),
                created_at: new Date(),
                updated_at: new Date()
            },
            {
                user: staff._id,
                amount: 150,
                type: 'DEPOSIT',
                category: 'ALLOWANCE',
                status: 'COMPLETED',
                reference: 'ALLOW-001',
                method: 'MPESA',
                description: 'Travel Allowance',
                date: new Date(),
                created_at: new Date(),
                updated_at: new Date()
            }
        ];

        await Transaction.insertMany(txns);
        console.log(`Added ${txns.length} transactions for Staff.`);
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

seedStaffTxns();
