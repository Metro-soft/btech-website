const express = require('express');
const router = express.Router();
const serviceController = require('../../modules/admin/dashboard/controllers/serviceController');
const { protect } = require('../../shared/middlewares/auth'); // Optional auth

// Public access to catalog
router.get('/', serviceController.getServices);
router.get('/:id', serviceController.getServiceById);

// Admin only (Uncomment middleware once fully integrated)
router.post('/', /* protect, admin, */ serviceController.createService);

module.exports = router;
