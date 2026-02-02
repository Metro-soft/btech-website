const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const AuditLog = require('../shared/models/AuditLog');

dotenv.config({ path: path.join(__dirname, '../../.env') });

const showSecurityLogs = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);

        // FILTER: Look specifically for 'sqli' topic
        const query = { topics: 'sqli' };

        const logs = await AuditLog.find(query).sort({ timestamp: -1 }).limit(1);

        if (logs.length > 0) {
            const log = logs[0];
            console.log('\n🔍 --- FOUND SECURITY LOG RECORD --- 🔍');
            console.log(JSON.stringify(log, null, 2));
            console.log('------------------------------------------');
        } else {
            console.log('❌ No SQLi logs found.');
        }

        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

showSecurityLogs();
