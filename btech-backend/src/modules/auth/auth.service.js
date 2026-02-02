const User = require('../../shared/models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

class AuthService {
    async register(data) {
        const { name, email, password, role, phone } = data;

        // Check existing
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            throw new Error('User already exists');
        }

        // Hash Password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create User
        const user = await User.create({
            name,
            email,
            password: hashedPassword,
            role: role || 'client',
            phone,
        });

        return this._generateAuthResponse(user);
    }

    async login(email, password) {
        // Check user
        const user = await User.findOne({ email });
        if (!user) {
            throw new Error('Invalid credentials');
        }

        // Check password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            throw new Error('Invalid credentials');
        }

        return this._generateAuthResponse(user);
    }

    async updateProfile(userId, data) {
        const fieldsToUpdate = {};
        if (data.name) fieldsToUpdate.name = data.name;
        if (data.email) fieldsToUpdate.email = data.email;
        if (data.phone) fieldsToUpdate.phone = data.phone;
        if (data.profilePicture) fieldsToUpdate.profilePicture = data.profilePicture;

        if (data.password) {
            const salt = await bcrypt.genSalt(10);
            fieldsToUpdate.password = await bcrypt.hash(data.password, salt);
        }

        const user = await User.findByIdAndUpdate(userId, fieldsToUpdate, {
            new: true,
            runValidators: true,
        });

        if (!user) {
            throw new Error('User not found');
        }

        return this._generateAuthResponse(user);
    }

    _generateAuthResponse(user) {
        const token = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET || 'fallback_secret', // Ideally use .env
            { expiresIn: '30d' }
        );

        return {
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone,
            profilePicture: user.profilePicture, // Return pfp
            token,
        };
    }
}

module.exports = new AuthService();
