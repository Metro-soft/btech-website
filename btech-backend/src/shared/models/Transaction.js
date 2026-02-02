const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        enum: ['DEPOSIT', 'PAYMENT', 'PAYOUT', 'REFUND'],
        required: true
    },
    category: {
        type: String, // WALLET, SERVICE_FEE, AIRTIME, STAFF_FEE, SALARY
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        default: 'KES'
    },
    status: {
        type: String,
        enum: ['PENDING', 'COMPLETED', 'FAILED'],
        default: 'PENDING'
    },
    method: {
        type: String,
        default: 'INTASEND'
    },
    reference: {
        type: String // IntaSend Invoice/Tracking ID
    },
    metadata: {
        type: Map,
        of: String
    }
}, { timestamps: true });

module.exports = mongoose.model('Transaction', transactionSchema);
