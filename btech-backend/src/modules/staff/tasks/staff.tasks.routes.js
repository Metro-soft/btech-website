const express = require('express');
const router = express.Router();
const { protect, allowRoles } = require('../../../shared/middlewares/auth');
const tasksController = require('./staff.tasks.controller');

router.use(protect);
router.use(allowRoles('staff'));

router.get('/', tasksController.getMyTasks);
router.put('/:id/step', tasksController.updateStep);
router.put('/:id/complete', tasksController.completeTask);
router.put('/:id/reject', tasksController.rejectTask);
router.put('/:id/request-input', tasksController.requestInput);

module.exports = router;
