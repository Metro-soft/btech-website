const express = require('express');
const router = express.Router();

// Aggregating Client Sub-modules
router.use('/finance', require('./finance/client.finance.routes'));
router.use('/files', require('./files/client.files.routes'));
router.use('/orders', require('./orders/client.orders.routes'));
router.use('/wallet', require('./wallet/wallet.routes'));

module.exports = router;
