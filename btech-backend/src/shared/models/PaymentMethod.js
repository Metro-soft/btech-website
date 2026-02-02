const mongoose = require('mongoose');

const paymentMethodSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        type: {
            type: String,
            enum: ['MPESA', 'CARD'],
            required: true,
        },
        provider: {
            type: String, // e.g., 'Safaricom', 'Visa', 'MasterCard'
            default: 'Unknown'
        },
        details: {
            type: String, // Masked display string (e.g., "**** 1234" or "07XX...89")
            required: true,
        },
        isDefault: {
            type: Boolean,
            default: false,
        },
    },
    { timestamps: true }
);

module.exports = mongoose.model('PaymentMethod', paymentMethodSchema);
