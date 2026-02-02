const EventEmitter = require('events');
class NotificationListener extends EventEmitter {}
const notificationBus = new NotificationListener();

// Listen for ORDER_COMPLETED
notificationBus.on('ORDER_COMPLETED', ({ orderId, clientPhone, downloadLink }) => {
    console.log(`🔔 Event Received: ORDER_COMPLETED for #${orderId}`);

    try {
        // Validation
        if (!clientPhone) {
            console.warn('⚠️ Notification Skipped: No phone number provided.');
            return;
        }

        // Simulate WhatsApp API Call
        sendWhatsAppMessage(clientPhone, downloadLink);

    } catch (err) {
        // Non-blocking error handling
        console.error('❌ Notification Failed:', err.message);
        // Do NOT throw error to keep server alive
    }
});

// Mock Function for WhatsApp
function sendWhatsAppMessage(phone, link) {
    console.log(`📲 Sending WhatsApp to ${phone}: "Good news! Your order is ready. Download here: ${link}"`);
    // integration with Twilio/Meta API would go here
}

module.exports = notificationBus;
