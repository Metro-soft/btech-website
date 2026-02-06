const express = require('express');
const router = express.Router();
const { protect, allowRoles } = require('../../shared/middlewares/auth');
const aiController = require('./ai.controller');

router.use(protect);
router.use(allowRoles('admin')); // Only admins can talk to the AI for now

router.get('/ping', aiController.ping);
router.post('/analyze', aiController.analyze);
router.post('/generate-template', aiController.generateTemplate);
router.post('/generate-service-full', aiController.generateFullServiceDetails);

module.exports = router;
