const express = require('express');
const router = express.Router();
const { protect, allowRoles } = require('../../../shared/middlewares/auth');
const financeController = require('./admin.finance.controller');

router.use(protect);
router.use(allowRoles('admin'));

router.get('/transactions', financeController.getAllTransactions);
router.post('/withdrawals/approve', financeController.approveWithdrawal);

module.exports = router;
