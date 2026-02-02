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

// Admin: User Management
router.get('/users', protect, require('./auth.controller').getAllUsers);
router.post('/users', protect, require('./auth.controller').createUser);
router.put('/users/:id', protect, require('./auth.controller').updateUser);
router.delete('/users/:id', protect, require('./auth.controller').deleteUser);

module.exports = router;
