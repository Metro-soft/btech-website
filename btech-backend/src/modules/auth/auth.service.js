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

        // Audit Log
        const AuditService = require('../../shared/services/audit.service');
        await AuditService.log({
            userId: user._id,
            topics: ['auth', 'login', 'info'],
            message: `User ${user.name} logged in`,
            resource: user.email,
            buffer: 'db'
        });

        return this._generateAuthResponse(user);
    }

    async updateProfile(userId, data) {
        const fieldsToUpdate = {};
        if (data.name) fieldsToUpdate.name = data.name;
        if (data.email) fieldsToUpdate.email = data.email;
        if (data.phone) fieldsToUpdate.phone = data.phone;
        if (data.profilePicture) fieldsToUpdate.profilePicture = data.profilePicture;
        if (data.staffDetails) fieldsToUpdate.staffDetails = data.staffDetails;

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
        if (!process.env.JWT_SECRET) {
            throw new Error('JWT_SECRET is not defined in environment variables');
        }

        const token = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET,
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
    async getAllUsers(filters = {}) {
        const query = {};
        if (filters.role && filters.role !== 'All') {
            query.role = filters.role.toLowerCase();
        }
        // Exclude password
        return await User.find(query).select('-password').sort({ createdAt: -1 });
    }

    async createUser(data) {
        // basic validation handled by controller/mongoose, but check email uniqueness
        const existing = await User.findOne({ email: data.email });
        if (existing) throw new Error('User already exists');

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(data.password, salt);

        const user = await User.create({
            ...data,
            password: hashedPassword
        });

        return user;
    }

    async updateUser(id, data) {
        const updates = { ...data };

        // Hash password if updating
        if (updates.password) {
            const salt = await bcrypt.genSalt(10);
            updates.password = await bcrypt.hash(updates.password, salt);
        }

        const user = await User.findByIdAndUpdate(id, updates, { new: true }).select('-password');
        if (!user) throw new Error('User not found');
        return user;
    }

    async deleteUser(id) {
        const user = await User.findByIdAndDelete(id);
        if (!user) throw new Error('User not found');
        return { message: 'User deleted successfully' };
    }
}

module.exports = new AuthService();
