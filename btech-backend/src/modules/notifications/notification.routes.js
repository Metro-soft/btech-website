const express = require('express');
const router = express.Router();
const protect = require('../../shared/middlewares/auth').protect;
const allowRoles = require('../../shared/middlewares/auth').allowRoles;
const templateController = require('./template.controller');
const notificationController = require('./notification.controller');

// Template Routes
router.route('/templates')
    .get(protect, allowRoles('admin'), templateController.getTemplates)
    .post(protect, allowRoles('admin'), templateController.createTemplate);

router.route('/templates/:id')
    .put(protect, allowRoles('admin'), templateController.updateTemplate)
    .delete(protect, allowRoles('admin'), templateController.deleteTemplate);

router.post('/broadcast', protect, allowRoles('admin'), templateController.sendBroadcast);

// --- User Notification Routes ---
router.get('/', protect, notificationController.getNotifications);
router.put('/:id/read', protect, notificationController.markAsRead);
router.get('/unread-count', protect, notificationController.getUnreadCount);

module.exports = router;
