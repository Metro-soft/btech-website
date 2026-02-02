const express = require('express');
const router = express.Router();
const { protect, allowRoles } = require('../../../shared/middlewares/auth');
const workflowController = require('./admin.workflow.controller.js');

router.use(protect);
router.use(allowRoles('admin'));

router.get('/applications', workflowController.getAllApplications);
router.put('/applications/:id/assign', workflowController.assignTask);
router.put('/applications/:id/reject', workflowController.rejectApplication);
router.put('/applications/:id/verify', workflowController.verifyTask);

module.exports = router;
