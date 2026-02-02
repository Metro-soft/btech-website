const express = require('express');
const router = express.Router();
const { protect, allowRoles } = require('../../../shared/middlewares/auth');
const financeController = require('./staff.finance.controller');

router.use(protect);
router.use(allowRoles('staff'));

router.get('/earnings', financeController.getEarnings);
router.post('/withdraw', financeController.withdrawEarnings);
router.post('/airtime', financeController.buyAirtime);

module.exports = router;
