const Notification = require('../models/Notification');

class NotificationService {
    /**
     * Send a notification to a specific user
     * @param {string} userId - The recipient's ID
     * @param {string} type - Enum: SYSTEM, APPLICATION, FINANCE, etc.
     * @param {string} title - Short title
     * @param {string} message - Body content
     * @param {Object} options - { priority, isAiGenerated, action, etc. }
     */
    static async send(userId, type, title, message, options = {}) {
        try {
            // 1. Save to Database
            const notification = await Notification.create({
                user: userId,
                type,
                title,
                message,
                priority: options.priority || 'NORMAL',
                isAiGenerated: options.isAiGenerated || false,
                aiActionSuggestion: options.aiActionSuggestion,
                action: options.action
            });

            // 2. Emit Real-time Event (if Socket.IO is initialized)
            if (global.io) {
                // Emit to the user's specific room
                global.io.to(userId.toString()).emit('notification', notification);

                // Also emit an update for unread count
                const unreadCount = await Notification.countDocuments({ user: userId, isRead: false });
                global.io.to(userId.toString()).emit('unread_count', { count: unreadCount });
            }

            return notification;
        } catch (error) {
            console.error('CRITICAL: NotificationService Error:', error);
            // We don't throw here to avoid breaking the main transaction flow
            // (e.g. if notification fails, the payment should still succeed)
        }
    }

    /**
     * Send to all Admins
     */
    static async broadcastToAdmins(type, title, message, options = {}) {
        // Logic to find admins and send to all (omitted for brevity, can be added later)
    }
}

module.exports = NotificationService;
