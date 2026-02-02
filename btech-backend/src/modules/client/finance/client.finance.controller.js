const User = require('../../../shared/models/User');
const Transaction = require('../../../shared/models/Transaction');
const PaymentEngine = require('../../../shared/utils/payment.engine');

// @desc    Wallet Deposit (IntaSend C2B)
// @route   POST /api/client/finance/deposit
exports.deposit = async (req, res) => {
    try {
        const { amount, phone } = req.body;
        if (!amount || !phone) return res.status(400).json({ message: 'Missing fields' });

        // Use Shared Payment Engine
        const result = await PaymentEngine.processC2B(req.user, amount, phone, 'WALLET', { type: 'DEPOSIT' });
        res.json(result);
    } catch (err) {
        console.error('Deposit Error:', err);
        res.status(500).json({ message: 'Deposit Failed', error: err.message });
    }
};

// @desc    Application Checkout (IntaSend C2B)
// @route   POST /api/client/finance/checkout
exports.checkout = async (req, res) => {
    try {
        const { amount, phone, applicationId } = req.body;

        // Use Shared Payment Engine
        const result = await PaymentEngine.processC2B(req.user, amount, phone, 'SERVICE_FEE', { applicationId });
        res.json(result);
    } catch (err) {
        console.error('Checkout Error:', err);
        res.status(500).json({ message: 'Checkout Failed', error: err.message });
    }
};

// @desc    Get My Wallet Details
// @route   GET /api/client/finance/wallet
exports.getWallet = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('walletBalance');
        const transactions = await Transaction.find({ user: req.user.id, category: 'WALLET' })
            .sort({ createdAt: -1 })
            .limit(20);

        res.json({
            balance: user.walletBalance,
            transactions: transactions
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Buy Airtime (Spend Wallet Balance)
// @route   POST /api/client/finance/airtime
exports.buyAirtime = async (req, res) => {
    try {
        const { amount, phone } = req.body;

        // 1. Check Balance
        const user = await User.findById(req.user.id);
        if (user.walletBalance < amount) {
            return res.status(400).json({ message: 'Insufficient wallet balance' });
        }

        // 2. Deduct Balance
        user.walletBalance -= amount;
        await user.save();

        // 3. Create Transaction Record
        await Transaction.create({
            user: req.user.id,
            type: 'PAYMENT', // Money leaving
            category: 'AIRTIME',
            amount: amount,
            status: 'COMPLETED',
            method: 'WALLET',
            reference: `AIR-${Date.now()}`,
            metadata: { phone }
        });

        res.json({ message: 'Airtime purchased successfully' });
    } catch (err) {
        res.status(500).json({ message: 'Airtime purchase failed', error: err.message });
    }
};
