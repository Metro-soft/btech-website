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

  layoutType: {
    type: String,
    enum: ['classic', 'compact', 'wizard', 'accordion', 'stepper'],
    default: 'classic'
  },

  tags: [{ type: String }], // For fuzzy search

  // Dynamic Form Structure for this service
  formStructure: [{
    type: {
      type: String,
      enum: ['text', 'number', 'date', 'file', 'dropdown', 'checkbox', 'section'],
      required: true
    },
    label: { type: String, required: true },
    name: { type: String, required: true }, // Key for the payload
    required: { type: Boolean, default: false },
    options: [{ type: String }], // For dropdowns
    validationRegex: { type: String }
  }]
}, { timestamps: true });

// Enable text search on title, subcategory, and tags
serviceSchema.index({ title: 'text', subcategory: 'text', tags: 'text' });

module.exports = mongoose.models.Service || mongoose.model('Service', serviceSchema);
