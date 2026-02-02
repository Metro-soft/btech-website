const mongoose = require('mongoose');

const TemplateSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },
    category: {
        type: String,
        enum: ['FINANCE', 'SYSTEM', 'MARKETING', 'URGENT', 'GENERAL'],
        default: 'GENERAL'
    },
    body: {
        type: String,
        required: true,
        // Example: "Hello {{name}}, your payment of {{amount}} is due."
    },
    action: {
        route: { type: String }, // Optional deep link, e.g. /finance/invoices
        payload: { type: Object }
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('NotificationTemplate', TemplateSchema);
