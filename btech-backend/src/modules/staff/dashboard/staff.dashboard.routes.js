const express = require('express');
const router = express.Router();
const { protect, allowRoles } = require('../../../shared/middlewares/auth');
const dashboardController = require('./staff.dashboard.controller');

router.use(protect);
router.use(allowRoles('staff'));

router.get('/', dashboardController.getDashboardStats);
router.post('/availability', dashboardController.toggleAvailability);

module.exports = router;
