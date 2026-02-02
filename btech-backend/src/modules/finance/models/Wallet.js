const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
  user: { type: String, required: true, unique: true },
  balance: { type: Number, default: 0.0, min: 0 },
  currency: { type: String, default: 'KES' },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

// Optimistic Concurrency Control
walletSchema.plugin(schema => {
  schema.pre('findOneAndUpdate', function() {
    this.setOptions({ new: true, runValidators: true });
  });
});

module.exports = mongoose.model('Wallet', walletSchema);
