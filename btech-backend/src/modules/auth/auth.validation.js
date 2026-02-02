const Joi = require('joi');

const registerSchema = Joi.object({
    name: Joi.string().min(2).max(50).required().messages({
        'string.empty': 'Name cannot be empty',
        'string.min': 'Name must be at least 2 characters',
    }),
    email: Joi.string().email().required().messages({
        'string.email': 'Please provide a valid email address',
    }),
    password: Joi.string().min(6).required().messages({
        'string.min': 'Password must be at least 6 characters',
    }),
    role: Joi.string().valid('client', 'staff', 'admin').default('client'),
    phone: Joi.string().pattern(/^[0-9]+$/).min(10).max(15).optional(),
});

const loginSchema = Joi.object({
    email: Joi.string().email().required().messages({
        'string.empty': 'Email is required',
        'string.email': 'Please provide a valid email address',
    }),
    password: Joi.string().required().messages({
        'string.empty': 'Password is required',
    }),
});

const updateProfileSchema = Joi.object({
    name: Joi.string().min(2).max(50),
    email: Joi.string().email(),
    phone: Joi.string().pattern(/^[0-9]+$/).min(10).max(15),
    password: Joi.string().min(6),
    profilePicture: Joi.string().allow(null, ''),
});

module.exports = {
    registerSchema,
    loginSchema,
    updateProfileSchema,
};
