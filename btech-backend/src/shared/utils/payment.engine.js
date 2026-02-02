const IntaSend = require('intasend-node');

// Initialize SDK
const intasend = new IntaSend(
    process.env.INTASEND_PUBLISHABLE_KEY,
    process.env.INTASEND_SECRET_KEY,
    process.env.INTASEND_ENV === 'production'
);

const Transaction = require('../models/Transaction');

/**
 * Process C2B Payment (Deposit, Checkout, etc.)
 * @param {Object} user - The user object (req.user)
 * @param {Number} amount - Amount to charge
 * @param {String} phone - Phone number
 * @param {String} category - Transaction Category (WALLET, PAYMENT)
 * @param {Object} metadata - Additional metadata
 * @returns {Object} Payment initiation result
 */
exports.processC2B = async (user, amount, phone, category, metadata) => {
    const userId = user.id;
    const email = user.email;
    const name = user.name;

    // --- Validate & Format Phone Number ---
    let formattedPhone = phone;
    if (formattedPhone.startsWith('0')) {
        formattedPhone = '254' + formattedPhone.substring(1);
    } else if (formattedPhone.startsWith('+254')) {
        formattedPhone = formattedPhone.substring(1);
    }

    // 1. Create Transaction (Generate temp reference)
    const tempRef = `TXN-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

    const transaction = await Transaction.create({
        user: userId,
        type: category === 'WALLET' ? 'DEPOSIT' : 'PAYMENT',
        category: category,
        amount: parseFloat(amount),
        status: 'PENDING',
        method: 'INTASEND',
        reference: tempRef,
        metadata: {
            phone: formattedPhone,
            email,
            initiator: 'WEB_CHECKOUT',
            ...metadata
        }
    });

    // 2. IntaSend Charge (Web Checkout)
    const collection = intasend.collection();
    const response = await collection.charge({
        first_name: (name || 'Valued User').split(' ')[0],
        last_name: (name || 'Valued User').split(' ')[1] || 'User',
        email: email,
        host: process.env.BASE_URL,
        amount: parseFloat(amount),
        currency: 'KES',
        api_ref: transaction._id.toString(),
        phone_number: formattedPhone,
        redirect_url: `${process.env.BASE_URL}/api/finance/callback_success?txnId=${transaction._id}`
    });

    return {
        message: 'Payment Initiated',
        transactionId: transaction._id,
        url: response.url,
        action: 'WEB_VIEW'
    };
};
