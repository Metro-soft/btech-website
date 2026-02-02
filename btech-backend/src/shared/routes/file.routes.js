const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth');
const fileViewer = require('../controllers/file.viewer');

// Public or Protected View? Usually Protected.
router.use(protect);
router.get('/:filename', fileViewer.viewFile);

module.exports = router;
