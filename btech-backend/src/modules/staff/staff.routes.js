const express = require('express');
const router = express.Router();
const { protect, allowRoles } = require('../../shared/middlewares/auth');
const staffController = require('./staff.controller');

// All routes require 'staff' role
router.use(protect);
router.use(allowRoles('staff'));

router.get('/dashboard', staffController.getDashboard);
router.put('/tasks/:id/complete', staffController.completeTask);
router.put('/tasks/:id/reject', staffController.rejectTask);
router.put('/tasks/:id/request-input', staffController.requestInput);

module.exports = router;
