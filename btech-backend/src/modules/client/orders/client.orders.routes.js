const express = require('express');
const router = express.Router();
const { protect } = require('../../../shared/middlewares/auth');
const clientOrdersController = require('./client.orders.controller');

router.use(protect); // All Client Orders require Login

router.post('/', clientOrdersController.submitOrder);
router.get('/', clientOrdersController.getMyOrders);
router.get('/:id', clientOrdersController.getOrderById);
router.post('/:id/pay', clientOrdersController.payOrder);
router.post('/:id/input', clientOrdersController.submitInput);

module.exports = router;
