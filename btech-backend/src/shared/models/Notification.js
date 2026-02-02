const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['SYSTEM', 'APPLICATION', 'FINANCE', 'TASK', 'SECURITY', 'AI_INSIGHT'],
    required: true
  },
  priority: {
    type: String,
    enum: ['LOW', 'NORMAL', 'HIGH', 'CRITICAL'],
    default: 'NORMAL'
  },
  title: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },

  // AI Specifics
  isAiGenerated: {
    type: Boolean,
    default: false
  },
  aiActionSuggestion: {
    type: String
  },

  // Action / Deep Link Payload
  action: {
    route: { type: String },     // e.g., '/admin/applications/123'
    entityId: { type: String },  // e.g., '65b...'
    payload: { type: Map, of: String }
  },

  isRead: {
    type: Boolean,
    default: false
  },
  isArchived: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: '90d' // Auto-delete after 90 days
  }
});

module.exports = mongoose.model('Notification', NotificationSchema);
