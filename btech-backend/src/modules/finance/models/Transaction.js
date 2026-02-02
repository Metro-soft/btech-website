const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  user: { type: String, required: true }, // Store userId as string, verified by gateway
  type: { 
    type: String, 
    enum: ['DEPOSIT', 'PAYMENT', 'REFUND', 'PAYOUT'], 
    required: true 
  },
  amount: { type: Number, required: true },
  method: { 
    type: String, 
    enum: ['MPESA', 'PAYPAL', 'WALLET', 'MANUAL', 'INTASEND'], 
    required: true 
  },
  reference: { type: String, unique: true },
  status: { 
    type: String, 
    enum: ['PENDING', 'COMPLETED', 'FAILED'], 
    default: 'PENDING' 
  },
  metadata: { 
    type: Map, 
    of: mongoose.Schema.Types.Mixed 
  }
}, { timestamps: true });

// Prevent double processing of same reference
// Prevent double processing of same reference
// transactionSchema.index({ reference: 1 }, { unique: true }); // Removed: Already defined in schema path

module.exports = mongoose.model('Transaction', transactionSchema);
