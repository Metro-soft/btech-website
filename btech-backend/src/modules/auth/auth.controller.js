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
    const result = await authService.login(value.email, value.password, req);

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

// @desc    Get All Users (Admin)
exports.getAllUsers = async (req, res) => {
  try {
    const filters = req.query; // role=staff etc.
    const users = await authService.getAllUsers(filters);
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// @desc    Create User (Admin)
exports.createUser = async (req, res) => {
  try {
    const user = await authService.createUser(req.body, req);
    res.status(201).json(user);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// @desc    Update User (Admin)
exports.updateUser = async (req, res) => {
  try {
    const user = await authService.updateUser(req.params.id, req.body, req);
    res.json(user);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// @desc    Delete User (Admin)
exports.deleteUser = async (req, res) => {
  try {
    const result = await authService.deleteUser(req.params.id, req);
    res.json(result);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};
