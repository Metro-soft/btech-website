const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema({
  trackingNumber: {
    type: String,
    unique: true,
    required: true,
    index: true // e.g. "TRK-8X29"
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false // Allow anonymous/guest applications initially, or require auth later
  },
  service: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Service' // Link to the dynamic service catalog
  },
  type: {
    type: String,
    enum: ['ETA', 'KUCCPS', 'HELB', 'KRA', 'OTHER'],
    required: true
  },
  status: {
    type: String,
    enum: ['PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'REJECTED', 'PAID'],
    default: 'PENDING'
  },
  timeline: [{
    status: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
    note: { type: String },
    actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User' } // Who made the change
  }],
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  cost: {
    amount: { type: Number, default: 0 },
    currency: { type: String, default: 'KES' }
  },
  payment: {
    method: { type: String, enum: ['MPESA', 'PAYPAL', 'CARD', 'NONE'], default: 'NONE' },
    transactionId: String,
    isPaid: { type: Boolean, default: false },
    staffPay: { type: Number, default: 0 }, // Calculated earnings
    commissionStatus: { 
      type: String, 
      enum: ['UNPAID', 'PAID', 'HELD'], 
      default: 'UNPAID' 
    }
  },
  finalPrice: { type: Number }, // Dynamic price at purchase
  renewalDate: { type: Date }, // For CRM Reminders
  // Dynamic payload for different application types
  payload: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  adminNotes: {
    type: String
  },
  // Interactive Flow
  clientAction: {
     required: { type: Boolean, default: false },
     type: { type: String, enum: ['OTP', 'TEXT', 'FILE'], default: 'OTP' },
     message: { type: String }, // e.g., "Enter the OTP sent to your phone"
     response: { type: String } // User's submitted data
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Application', applicationSchema);
