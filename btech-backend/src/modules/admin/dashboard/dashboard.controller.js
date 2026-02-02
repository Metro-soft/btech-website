const Application = require('../../../shared/models/Application'); // Corrected depth
const User = require('../../../shared/models/User');

exports.getQuickStats = async (req, res) => {
    try {
        const totalRevenue = await Application.aggregate([
            { $match: { status: 'PAID' } },
            { $group: { _id: null, total: { $sum: '$cost.amount' } } }
        ]);

        const pendingTasks = await Application.countDocuments({ status: 'PENDING' });
        const activeStaff = await User.countDocuments({ role: 'staff', isOnline: true });
        const totalUsers = await User.countDocuments();

        res.json({
            revenue: totalRevenue[0]?.total || 0,
            pendingTasks,
            activeStaff,
            totalUsers
        });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
};

exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.find().select('-password').sort({ createdAt: -1 });
        res.json(users);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
};

exports.updateUserRole = async (req, res) => {
    try {
        const { role } = req.body;
        const user = await User.findByIdAndUpdate(
            req.params.id, 
            { role }, 
            { new: true }
        ).select('-password');
        
        if (!user) return res.status(404).json({ message: 'User not found' });
        
        res.json(user);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
};
