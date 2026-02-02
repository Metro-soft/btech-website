const jwt = require('jsonwebtoken');
const roles = require('../utils/roles'); // Optional: Use if you defined roles here

// ✅ Middleware to protect private routes using JWT
exports.protect = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = decoded; // decoded should include { id, role, ... }
      return next();
    } catch (err) {
      console.log('[AUTH FAILED] Token verify error:', err.message);
      return res.status(401).json({ message: 'Invalid token' });
    }
  }

  console.log('[AUTH FAILED] No token or invalid header:', authHeader);
  return res.status(401).json({ message: 'No token provided' });
};

// ✅ Middleware to restrict access based on user role
exports.allowRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Access denied' });
    }
    next();
  };
};
