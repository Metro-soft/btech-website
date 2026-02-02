const Application = require('../../../shared/models/Application');
const User = require('../../../shared/models/User');
const Transaction = require('../../../shared/models/Transaction');

// @desc    Get Earnings Report
exports.getEarnings = async (req, res) => {
    try {
        const { period } = req.query;
        const now = new Date();
        let startDate = new Date(0);

        if (period === 'weekly') {
            const day = now.getDay() || 7;
            if (day !== 1) now.setHours(-24 * (day - 1));
            startDate = now;
        } else if (period === 'monthly') {
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        } else if (period === 'annual') {
            startDate = new Date(now.getFullYear(), 0, 1);
        }

        const tasks = await Application.find({
            assignedTo: req.user.id,
            status: { $in: ['COMPLETED', 'PAID'] },
            updatedAt: { $gte: startDate }
        })
            .select('payment service type createdAt status')
            .populate('service', 'title')
            .sort({ createdAt: -1 });

        const totalEarnings = tasks.reduce((acc, curr) => acc + (curr.payment?.staffPay || 0), 0);

        // Payout Calculation
        const allPendingTasks = await Application.find({
            assignedTo: req.user.id,
            status: { $in: ['COMPLETED', 'PAID'] },
            'payment.commissionStatus': 'UNPAID'
        }).select('payment');

        const pendingPayout = allPendingTasks.reduce((acc, curr) => acc + (curr.payment?.staffPay || 0), 0);

        res.json({
            stats: { totalEarnings, pendingPayout, completedTasks: tasks.length },
            recentJobs: tasks
        });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Request Withdrawal
exports.withdrawEarnings = async (req, res) => {
    try {
        const { amount, phone } = req.body;
        const user = await User.findById(req.user.id);

        if (user.walletBalance < amount) {
            return res.status(400).json({ message: 'Insufficient funds' });
        }

        user.walletBalance -= amount;
        await user.save();

        await Transaction.create({
            user: req.user.id,
            type: 'WITHDRAWAL',
            category: 'PAYOUT',
            amount: amount,
            status: 'PENDING',
            method: 'MPESA',
            reference: `WTH-${Date.now()}`,
            metadata: { phone }
        });

        res.json({ message: 'Withdrawal request submitted' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Buy Airtime (Staff Personal)
exports.buyAirtime = async (req, res) => {
    try {
        const { amount, phone } = req.body;
        const user = await User.findById(req.user.id);

        if (user.walletBalance < amount) {
            return res.status(400).json({ message: 'Insufficient funds' });
        }

        user.walletBalance -= amount;
        await user.save();

        await Transaction.create({
            user: req.user.id,
            type: 'PAYMENT',
            category: 'AIRTIME',
            amount: amount,
            status: 'COMPLETED',
            method: 'WALLET',
            reference: `AIR-${Date.now()}`,
            metadata: { phone }
        });

        res.json({ message: 'Airtime purchased' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
