const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Transaction = require('../shared/models/Transaction');
const User = require('../shared/models/User');
const path = require('path');

// Load env from root
dotenv.config({ path: path.join(__dirname, '../../.env') });

const verifyFiltering = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to DB');

        const users = await User.find({});
        console.log(`Found ${users.length} users in total.`);

        for (const user of users) {
            const count = await Transaction.countDocuments({ user: user._id });
            console.log(`User: ${user.name} (${user.role}) - ID: ${user._id} -> Transactions: ${count}`);
        }

        // Also check if any transactions have NO user
        const orphanCount = await Transaction.countDocuments({ user: { $exists: false } });
        console.log(`Transactions without user field: ${orphanCount}`);

        const nullUserCount = await Transaction.countDocuments({ user: null });
        console.log(`Transactions with null user: ${nullUserCount}`);

        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

verifyFiltering();
