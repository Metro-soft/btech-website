const Application = require('../../shared/models/Application');

// @desc    Get Staff Dashboard Stats & Tasks
exports.getDashboard = async (req, res) => {
    try {
        const tasks = await Application.find({ assignedTo: req.user.id })
            .select('-payload')
            .populate('user', 'name email')
            .sort({ createdAt: -1 });

        const pending = tasks.filter(t => t.status === 'ASSIGNED' || t.status === 'IN_PROGRESS').length;
        const completed = tasks.filter(t => t.status === 'COMPLETED').length;
        
        // Calculate Earnings (This month)
        const now = new Date();
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
        
        const earnings = tasks
            .filter(t => t.status === 'COMPLETED' && t.updatedAt >= firstDay)
            .reduce((acc, curr) => acc + (curr.payment?.staffPay || 0), 0);

        res.json({
            stats: {
                pendingTasks: pending,
                completedTasks: completed,
                monthlyEarnings: earnings
            },
            recentTasks: tasks.slice(0, 5)
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Assign Logic from OrderController (Moved here for separation)
exports.rejectTask = async (req, res) => {
    try {
        const { reason } = req.body;
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Task not found' });

        if (app.assignedTo.toString() !== req.user.id) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        app.status = 'REJECTED';
        app.adminNotes = reason;
        await app.save();
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.completeTask = async (req, res) => {
    try {
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Task not found' });

        if (app.assignedTo.toString() !== req.user.id) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        app.status = 'COMPLETED';
        app.completedAt = Date.now();
        await app.save();
        res.json(app);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.requestInput = async (req, res) => {
    try {
        const { message, type } = req.body;
        const app = await Application.findById(req.params.id);
        if (!app) return res.status(404).json({ message: 'Task not found' });

        if (app.assignedTo.toString() !== req.user.id) {
             return res.status(403).json({ message: 'Not authorized' });
        }

        app.clientAction = {
            required: true,
            type: type || 'OTP',
            message: message || 'Please provide the requested information',
            response: null
        };
        app.status = 'IN_PROGRESS';
        await app.save();
        res.json(app);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
