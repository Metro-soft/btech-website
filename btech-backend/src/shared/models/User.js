const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },

    phone: {
      type: String, // E.g., "+2547..."
    },

    profilePicture: {
      type: String, // Base64 string
    },

    password: {
      type: String,
      required: true,
    },

    role: {
      type: String,
      enum: ['client', 'staff', 'admin'],
      default: 'client',
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    walletBalance: {
      type: Number,
      default: 0.0,
    },

    currency: {
      type: String,
      default: 'KES',
      enum: ['KES', 'USD', 'EUR', 'GBP']
    },

    // Automation Fields
    isOnline: {
      type: Boolean,
      default: false
    },
    currentLoad: {
      type: Number, // Number of active tasks
      default: 0
    },
    lastActiveAt: {
      type: Date
    },

    // Staff Specific Details
    staffDetails: {
      nationalId: { type: String },
      kraPin: { type: String },
      
      // Enforce Bank Payment for Staff
      bankDetails: {
        bankName: { type: String },
        accountNumber: { type: String },
        branchCode: { type: String },
        accountName: { type: String }
      },

      skills: [{ type: String }],
      experienceLevel: { 
        type: String, 
        enum: ['Junior', 'Mid', 'Senior', 'Expert'],
        default: 'Junior'
      },
      verificationStatus: {
        type: String,
        enum: ['Pending', 'Verified', 'Rejected', 'InReview'],
        default: 'Pending'
      },
      documents: [{
        type: String, // URLs to uploaded docs
        name: String
      }]
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);

