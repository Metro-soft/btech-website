const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');

// Models
// Adjusted paths based on project structure
const User = require('../shared/models/User');
const Application = require('../shared/models/Application');
const Transaction = require('../shared/models/Transaction');

dotenv.config();

const seedData = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('🌱 MongoDB Connected...');

        // Clear existing data
        await User.deleteMany({});
        await Application.deleteMany({});
        await Transaction.deleteMany({});
        console.log('🗑️  Cleared existing data.');

        // 1. Create Users
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('password123', salt);

        const adminUser = await User.create({
            name: 'Super Admin',
            email: 'admin@btech.com',
            password: hashedPassword,
            role: 'admin',
            isOnline: true
        });

        const staffUser = await User.create({
            name: 'John Staff',
            email: 'staff@btech.com',
            password: hashedPassword,
            role: 'staff',
            isOnline: true,
            currentLoad: 1
        });

        const clientUser = await User.create({
            name: 'Alice Client',
            email: 'client@btech.com',
            password: hashedPassword,
            role: 'client',
            walletBalance: 5000
        });

        console.log('👥 Users Created.');

        // Helper to get date X days ago
        const daysAgo = (days) => {
            const d = new Date();
            d.setDate(d.getDate() - days);
            return d;
        };

        // 2. Create Historical Transactions (Last 7 Days)
        const transactions = [];
        const statuses = ['COMPLETED', 'PENDING', 'FAILED', 'COMPLETED', 'COMPLETED']; // Weighted towards complete
        const categories = ['GENERAL', 'WITHDRAWAL', 'SERVICE_FEE', 'GENERAL'];

        for (let i = 0; i < 40; i++) {
            const dayOffset = i % 8; // 0 to 7 days
            const isWithdrawal = i % 4 === 0; // 25% are withdrawals
            const amount = isWithdrawal ? (500 + i * 50) : (1000 + i * 100);

            transactions.push({
                user: clientUser._id,
                amount: amount,
                type: isWithdrawal ? 'PAYMENT' : 'DEPOSIT', // Withdrawals are payments out
                category: isWithdrawal ? 'WITHDRAWAL' : 'GENERAL',
                status: statuses[i % statuses.length],
                reference: `TXN-${1000 + i}`,
                method: 'INTASEND',
                description: isWithdrawal ? 'Withdrawal Request' : 'Wallet Deposit',
                date: daysAgo(dayOffset),
                created_at: daysAgo(dayOffset),
                updated_at: daysAgo(dayOffset)
            });
        }
        await Transaction.insertMany(transactions);
        console.log(`💰 Created ${transactions.length} transactions.`);

        // 3. Create Applications (Last 7 Days)
        const appStatuses = ['PENDING', 'APPROVED', 'REJECTED', 'APPROVED', 'PENDING'];
        // Map rough statuses to valid schema enums
        const getValidStatus = (s) => {
            if (s === 'APPROVED') return 'COMPLETED';
            if (s === 'REJECTED') return 'REJECTED';
            return 'PENDING';
        };

        const applications = [];

        for (let i = 0; i < 25; i++) {
            const dayOffset = i % 7;
            const rawStatus = appStatuses[i % appStatuses.length];

            applications.push({
                trackingNumber: `TRK-${Date.now()}-${i}`,
                user: clientUser._id,
                type: ['HELB', 'KRA', 'ETA', 'KUCCPS'][i % 4],
                status: getValidStatus(rawStatus),
                assignedTo: i % 2 === 0 ? staffUser._id : null,
                payload: {
                    serviceType: 'Standard Service',
                    idNumber: `ID-${2000 + i}`
                },
                createdAt: daysAgo(dayOffset),
                updatedAt: daysAgo(dayOffset)
            });
        }

        await Application.insertMany(applications);
        console.log(`📄 Created ${applications.length} applications.`);

        console.log('✅ Seeding Completed Successfully.');
        process.exit();

    } catch (err) {
        console.error('❌ Seeding Failed:', err);
        process.exit(1);
    }
};

seedData();
