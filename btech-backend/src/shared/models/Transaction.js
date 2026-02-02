const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  user: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  
  application: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Application' 
  },
  
  type: { 
    type: String, 
    enum: ['DEPOSIT', 'PAYMENT', 'REFUND', 'PAYOUT'], 
    required: true 
  },
  
  amount: { type: Number, required: true },
  
  method: { 
    type: String, 
    enum: ['MPESA', 'PAYPAL', 'WALLET', 'MANUAL'], 
    required: true 
  },
  
  reference: { type: String }, // M-Pesa Code or Transaction ID
  
  status: { 
    type: String, 
    enum: ['PENDING', 'COMPLETED', 'FAILED'], 
    default: 'PENDING' 
  },
  
  metadata: { type: Map, of: String } // Extra details (e.g. phone number used)
}, { timestamps: true });

module.exports = mongoose.model('Transaction', transactionSchema);
