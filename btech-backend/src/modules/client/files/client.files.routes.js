const express = require('express');
const router = express.Router();
const { protect } = require('../../../shared/middlewares/auth');
const upload = require('../../../shared/middlewares/uploadMiddleware'); // Assuming this exists
const filesController = require('./client.files.controller');

router.use(protect);

router.post('/upload', upload.single('file'), filesController.uploadFile);

module.exports = router;
