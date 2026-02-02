const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
  actor: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  
  action: { 
    type: String, 
    required: true 
  }, // e.g. "ASSIGN_TASK", "UPDATE_SETTINGS"
  
  target: { 
    type: String 
  }, // e.g. "Application #123"
  
  details: { 
    type: mongoose.Schema.Types.Mixed 
  }, // Old val vs New val
  
  ipAddress: { type: String }
}, { timestamps: true });

module.exports = mongoose.model('AuditLog', auditLogSchema);
