const mongoose = require('mongoose');

const systemSettingSchema = new mongoose.Schema({
  key: { 
    type: String, 
    unique: true, 
    required: true 
  }, // e.g. "USD_RATE", "MAINTENANCE_MODE"
  
  value: { 
    type: mongoose.Schema.Types.Mixed, 
    required: true 
  },
  
  description: { type: String },
  
  isPublic: { type: Boolean, default: false } // Is this exposed to frontend?
}, { timestamps: true });

module.exports = mongoose.model('SystemSetting', systemSettingSchema);
