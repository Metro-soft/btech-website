const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/shared.controller');
const { protect } = require('../../shared/middlewares/auth'); // Optional auth

// Public access to catalog
router.get('/', serviceController.getServices);
router.get('/:id', serviceController.getServiceById);

// Admin only (Uncomment middleware once fully integrated)
router.post('/', /* protect, admin, */ serviceController.createService);
router.put('/:id', /* protect, admin, */ serviceController.updateService);
router.delete('/:id', /* protect, admin, */ serviceController.deleteService);

module.exports = router;
