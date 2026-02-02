const authService = require('./auth.service');
const { registerSchema, loginSchema, updateProfileSchema } = require('./auth.validation');

// @desc    Register user
exports.register = async (req, res) => {
  try {
    // 1. Validate Input
    const { error, value } = registerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    // 2. Call Service
    const result = await authService.register(value);

    // 3. Send Response
    res.status(201).json(result);
  } catch (err) {
    const statusCode = err.message === 'User already exists' ? 400 : 500;
    res.status(statusCode).json({ message: err.message });
  }
};

// @desc    Login user
exports.login = async (req, res) => {
  try {
    // 1. Validate Input
    const { error, value } = loginSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    // 2. Call Service
    const result = await authService.login(value.email, value.password);

    // 3. Send Response
    res.json(result);
  } catch (err) {
    const statusCode = err.message === 'Invalid credentials' ? 400 : 500;
    res.status(statusCode).json({ message: err.message });
  }
};

// @desc    Update User Profile
exports.updateProfile = async (req, res) => {
  try {
    // 1. Validate Input
    const { error, value } = updateProfileSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    // 2. Call Service
    // req.user.id comes from the auth middleware
    const result = await authService.updateProfile(req.user.id, value);

    // 3. Send Response
    res.json(result);
  } catch (err) {
    const statusCode = err.message === 'User not found' ? 404 : 500;
    res.status(statusCode).json({ message: err.message });
  }
};
