const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config();

const NotificationSchema = new mongoose.Schema({}, { strict: false });
const Notification = mongoose.model('Notification', NotificationSchema, 'notifications'); // Force collection name

const checkNotifications = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');

        const count = await Notification.countDocuments();
        console.log(`📊 Total Notifications in DB: ${count}`);

        if (count > 0) {
            const notifications = await Notification.find().limit(5);
            console.log('\n🔍 First 5 Notifications:');
            console.log(JSON.stringify(notifications, null, 2));

            // Ask to delete?
            // checking if they match "Performance Tip"
            const stuck = notifications.filter(n => JSON.stringify(n).includes('Performance Tip'));
            if (stuck.length > 0) {
                console.log('\n⚠️ FOUND STUCK NOTIFICATIONS! The data IS in the database.');
            }
        } else {
            console.log('✅ Database is empty. No notifications found.');
        }

        await mongoose.disconnect();
    } catch (e) {
        console.error('Error:', e);
    }
};

checkNotifications();
