const Transaction = require('../../../shared/models/Transaction');
const AuditService = require('../../../shared/services/audit.service');

// @desc    Get All Transactions
// @route   GET /api/admin/finance/transactions
exports.getAllTransactions = async (req, res) => {
    try {
        const transactions = await Transaction.find()
            .populate('user', 'name email')
            .sort({ createdAt: -1 })
            .limit(100);
        res.json(transactions);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// @desc    Approve Withdrawal
// @route   POST /api/admin/finance/withdrawals/approve
exports.approveWithdrawal = async (req, res) => {
    try {
        const { transactionId } = req.body;

        const txn = await Transaction.findById(transactionId);
        if (!txn) return res.status(404).json({ message: 'Transaction not found' });
        if (txn.status !== 'PENDING' || txn.category !== 'PAYOUT') {
            return res.status(400).json({ message: 'Invalid transaction status or type' });
        }

        // --- MOCK B2C TRANSFER (In production, call IntaSend B2C here) ---
        // await PaymentEngine.processB2C(txn);

        txn.status = 'COMPLETED';
        if (!txn.metadata) txn.metadata = new Map();
        txn.metadata.set('approvedBy', req.user.id);
        txn.metadata.set('approvalTime', new Date());

        await txn.save();

        await AuditService.log({
            userId: req.user.id,
            action: 'WITHDRAWAL_APPROVAL',
            resource: txn._id.toString(),
            description: `Approved withdrawal of ${txn.amount}`,
            req
        });

        res.json({ message: 'Withdrawal Approved', transaction: txn });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
