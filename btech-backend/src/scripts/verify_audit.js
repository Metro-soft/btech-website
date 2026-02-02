const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const AuditLog = require('../shared/models/AuditLog');

dotenv.config({ path: path.join(__dirname, '../../.env') });

const verifyAudit = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');



        // Fetch last 10 logs
        const logs = await AuditLog.find().sort({ timestamp: -1 }).limit(10).populate('user', 'name');

        if (logs.length === 0) {
            console.log('⚠️  No logs found.');
        } else {
            console.log('📋  LATEST AUDIT LOGS');
            console.log('---------------------------------------------------------------------------------');
            console.log(`| ${'TIME'.padEnd(10)} | ${'BUFFER'.padEnd(8)} | ${'TOPICS'.padEnd(30)} | ${'MESSAGE'.padEnd(30)} |`);
            console.log('---------------------------------------------------------------------------------');

            logs.forEach(log => {
                const time = log.timestamp.toLocaleTimeString();
                const buffer = log.buffer || 'db';

                // Construct topics string
                let uniqueTopics = log.topics || [];
                // If legacy action exists and no topics, add it
                if (uniqueTopics.length === 0 && log.action) {
                    uniqueTopics = ['legacy', log.action.toLowerCase()];
                }
                const topicsStr = uniqueTopics.join(', ');

                const msg = log.description || log.message || log.resource;

                console.log(`| ${time.padEnd(10)} | ${buffer.padEnd(8)} | ${topicsStr.padEnd(30)} | ${msg.substring(0, 30).padEnd(30)} |`);
            });
            console.log('---------------------------------------------------------------------------------');
        }

        process.exit();
    } catch (err) {
        console.error('❌ Error:', err);
        process.exit(1);
    }
};

verifyAudit();
