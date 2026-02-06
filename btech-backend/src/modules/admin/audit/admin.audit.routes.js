const express = require('express');
const router = express.Router();
const auditController = require('./admin.audit.controller');
const { protect, allowRoles } = require('../../../shared/middlewares/auth');

// Protect all routes with Admin Auth
router.get('/', [protect, allowRoles('admin')], auditController.getLogs);

module.exports = router;
