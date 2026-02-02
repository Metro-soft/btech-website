const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipient: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    required: true
  },
  
  title: { type: String, required: true },
  
  message: { type: String, required: true },
  
  isRead: { type: Boolean, default: false },
  
  type: { 
    type: String, 
    enum: ['GENERAL', 'WARNING', 'SUCCESS', 'UPDATE', 'FOLLOW_UP'], 
    default: 'GENERAL' 
  },
  
  link: { type: String } // Deepbox/Deep link
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
