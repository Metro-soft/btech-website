const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  title: { 
    type: String, 
    required: true, 
    index: true 
  }, // Main searchable title (e.g. "File Returns")
  
  category: { 
    type: String, 
    enum: ['KRA', 'HELB', 'ETA', 'KUCCPS', 'OTHER'], 
    required: true, 
    index: true 
  },
  
  subcategory: { 
    type: String, 
    index: true 
  }, // e.g., "Employment Returns"
  
  description: { type: String },
  
  requirements: [{ type: String }], // List of required docs
  
  basePrice: { type: Number, default: 0 },
  
  isActive: { type: Boolean, default: true },
  
  tags: [{ type: String }] // For fuzzy search
}, { timestamps: true });

// Enable text search on title, subcategory, and tags
serviceSchema.index({ title: 'text', subcategory: 'text', tags: 'text' });

module.exports = mongoose.model('Service', serviceSchema);
