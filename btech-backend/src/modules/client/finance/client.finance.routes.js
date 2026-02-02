const express = require('express');
const router = express.Router();
const { protect } = require('../../../shared/middlewares/auth');
const clientFinanceController = require('./client.finance.controller');

// All Routes Protected
router.use(protect);

router.get('/wallet', clientFinanceController.getWallet);
router.post('/deposit', clientFinanceController.deposit);
router.post('/checkout', clientFinanceController.checkout);
router.post('/airtime', clientFinanceController.buyAirtime);

module.exports = router;
