const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/shared.controller');
const { protect, allowRoles } = require('../../shared/middlewares/auth');

// Public access to catalog
router.get('/', serviceController.getServices);
router.get('/:id', serviceController.getServiceById);

// Admin only
router.post('/', protect, allowRoles('admin'), serviceController.createService);
router.put('/:id', protect, allowRoles('admin'), serviceController.updateService);
router.delete('/:id', protect, allowRoles('admin'), serviceController.deleteService);

module.exports = router;
