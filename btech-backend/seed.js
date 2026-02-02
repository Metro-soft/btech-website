const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');

// Models
// Adjusted paths based on project structure
const User = require('./src/shared/models/User');
const Application = require('./src/shared/models/Application');

dotenv.config();

const seedData = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('🌱 MongoDB Connected...');

        // Clear existing data
        await User.deleteMany({});
        await Application.deleteMany({});
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
            role: 'client'
        });

        console.log('👥 Users Created:');
        console.log(`   - Admin: admin@btech.com / password123`);
        console.log(`   - Staff: staff@btech.com / password123`);
        console.log(`   - Client: client@btech.com / password123`);

        // 2. Create Applications
        const apps = [
            {
                user: clientUser._id,
                type: 'HELB',
                status: 'PENDING',
                payload: {
                    applicationType: 'First Time',
                    idNumber: '12345678',
                    fullName: 'Alice Client',
                    phoneNumber: '0712345678'
                }
            },
            {
                user: clientUser._id,
                type: 'KRA',
                status: 'ASSIGNED',
                assignedTo: staffUser._id,
                payload: {
                    serviceType: 'New PIN',
                    email: 'client@btech.com',
                    idNumber: '12345678'
                },
                createdAt: new Date(Date.now() - 86400000) // 1 day ago
            },
            {
                user: clientUser._id,
                type: 'ETA',
                status: 'COMPLETED',
                assignedTo: staffUser._id,
                payment: {
                    isPaid: true,
                    method: 'MPESA',
                    transactionId: 'QWE123RTY',
                    staffPay: 350
                },
                cost: { amount: 500, currency: 'KES' },
                payload: {
                    passportNumber: 'A1234567',
                    nationality: 'Kenya'
                }
            }
        ];

        await Application.insertMany(apps);
        console.log(`📄 Created ${apps.length} sample applications.`);

        console.log('✅ Seeding Completed Successfully.');
        process.exit();

    } catch (err) {
        console.error('❌ Seeding Failed:', err);
        process.exit(1);
    }
};

seedData();
