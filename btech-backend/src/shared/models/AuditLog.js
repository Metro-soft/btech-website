const mongoose = require('mongoose');
require('./User'); // Ensure User model is registered (Mongoose Best Practice for populate)

const AuditLogSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    // required: true // Optional for anonymous security logs
  },
  buffer: {
    type: String,
    enum: ['db', 'cache', 'file'],
    default: 'db'
  },
  topics: {
    type: [String],
    index: true
  },
  action: {
    type: String,
    // required: true, // Made optional for transition to 'topics'
    enum: ['VIEW_DOCUMENT', 'DOWNLOAD_ORIGINAL', 'LOGIN', 'LOGOUT', 'STATUS_CHANGE', 'PAYMENT', 'ASSIGNMENT', 'CREATE', 'UPDATE', 'DELETE', 'WITHDRAWAL_APPROVAL', 'USER_CREATE', 'USER_UPDATE', 'USER_DELETE', 'USER_SUSPEND', 'USER_ACTIVATE']
  },
  resource: {
    type: String, // Filename or Resource ID
    required: true
  },
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed // Flexible metadata
  },
  description: String,
  ipAddress: String,
  userAgent: String,
  timestamp: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('AuditLog', AuditLogSchema);
