const express = require('express');
const router = express.Router();
const controller = require('./dashboard.controller');
const { protect, allowRoles } = require('../../../shared/middlewares/auth'); // Corrected depth

// Endpoint: /api/v1/admin/dashboard/quick-stats
router.get(
  '/quick-stats',
  protect,
  allowRoles('admin'),
  controller.getQuickStats
);

// Endpoint: /api/admin/dashboard/users
router.get('/users', protect, allowRoles('admin'), controller.getAllUsers);

// Endpoint: /api/admin/dashboard/users/:id
router.put('/users/:id', protect, allowRoles('admin'), controller.updateUserRole);

module.exports = router;
