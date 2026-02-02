const express = require('express');
const router = express.Router();
const { protect } = require('../../shared/middlewares/auth'); // Adjusted path
const { register, login } = require('./auth.controller');

router.post('/register', register);
router.post('/login', login);

// Get logged-in user info (Protected)
router.get('/me', protect, (req, res) => {
    res.json(req.user);
});

router.put('/profile', protect, require('./auth.controller').updateProfile);

module.exports = router;
