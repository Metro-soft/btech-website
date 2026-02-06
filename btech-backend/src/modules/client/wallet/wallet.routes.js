const express = require('express');
const router = express.Router();
const { protect } = require('../../../shared/middlewares/auth');
const financeController = require('../finance/client.finance.controller');

// GET /api/wallet
router.get('/', protect, financeController.getWallet);

// GET /api/wallet/transactions (optional)
// router.get('/transactions', protect, financeController.getTransactions);

// Value Added Services
router.post('/airtime', protect, financeController.buyAirtime);
// router.post('/statement', protect, financeController.requestStatement);

module.exports = router;
