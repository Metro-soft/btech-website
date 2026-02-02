const express = require('express');
const router = express.Router();
const controller = require('./order.controller');
const { protect, allowRoles } = require('../../../shared/middlewares/auth');

router.post('/', protect, controller.submitOrder);
router.get('/', protect, controller.getOrders);
router.get('/:id', protect, controller.getOrderById);

// Actions
router.put('/:id/assign', protect, allowRoles('admin'), controller.assignTask);
router.put('/:id/complete', protect, allowRoles('staff', 'admin'), controller.completeTask);
router.put('/:id/pay', protect, controller.payOrder);
router.put('/:id/reject', protect, allowRoles('staff', 'admin'), controller.rejectOrder);
router.put('/:id/request-input', protect, allowRoles('staff', 'admin'), controller.requestInput);
router.put('/:id/submit-input', protect, controller.submitInput);

module.exports = router;
