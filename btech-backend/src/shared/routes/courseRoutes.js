const express = require('express');
const router = express.Router();
const courseController = require('../../modules/admin/dashboard/controllers/courseController');

router.get('/', courseController.getCourses);
router.get('/:id', courseController.getCourseById);

module.exports = router;
