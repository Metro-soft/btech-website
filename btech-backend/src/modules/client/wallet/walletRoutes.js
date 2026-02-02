const express = require('express');
const router = express.Router();
const { protect } = require('../../../shared/middlewares/auth');
const financeController = require('../../finance/controllers/financeController');

// GET /api/wallet - Get Wallet Balance & Transactions
router.get('/', protect, financeController.getWallet);

// POST /api/wallet/deposit - Initiate IntaSend Deposit
router.post('/deposit', protect, financeController.deposit);

// POST /api/wallet/callback - Handle IntaSend Webhooks (No Auth required for webhooks usually, or verify signature)
router.post('/callback', financeController.handleIntasendWebhook);

module.exports = router;
