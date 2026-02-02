const Application = require('../../../shared/models/Application');
const User = require('../../../shared/models/User');

// @desc    Get Staff Dashboard Stats
// @route   GET /api/staff/dashboard/stats
exports.getDashboardStats = async (req, res) => {
    try {
        const tasks = await Application.find({ assignedTo: req.user.id })
            .select('-payload')
            .sort({ createdAt: -1 });

        const pending = tasks.filter(t => t.status === 'ASSIGNED' || t.status === 'IN_PROGRESS').length;
        const completed = tasks.filter(t => t.status === 'COMPLETED').length;

        // Calculate Earnings (This month)
        const now = new Date();
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);

        const earnings = tasks
            .filter(t => (t.status === 'COMPLETED' || t.status === 'PAID') && t.updatedAt >= firstDay)
            .reduce((acc, curr) => acc + (curr.payment?.staffPay || 0), 0);

        const currentUser = await User.findById(req.user.id).select('name profilePicture isOnline');

        res.json({
            stats: {
                pendingTasks: pending,
                completedTasks: completed,
                monthlyEarnings: earnings,
                monthlyGoal: 20000,
                goalPercentage: Math.min(Math.round((earnings / 20000) * 100), 100),
                isOnline: currentUser?.isOnline || false
            },
            user: {
                name: currentUser?.name || 'Staff',
                profilePicture: currentUser?.profilePicture,
                isOnline: currentUser?.isOnline || false
            },
            recentTasks: tasks.slice(0, 5)
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Toggle Availability
// @route   POST /api/staff/dashboard/availability
exports.toggleAvailability = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        user.isOnline = !user.isOnline;
        await user.save();

        res.json({
            isOnline: user.isOnline,
            message: `You are now ${user.isOnline ? 'Online' : 'Offline'}`
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
