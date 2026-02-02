const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
    },

    description: {
      type: String,
      required: true,
    },

    instructor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    category: {
      type: String,
      enum: ['Degree', 'Diploma', 'Certificate', 'Artisan'],
      required: true,
    },

    university: {
      type: String, // e.g. "University of Nairobi"
      required: true
    },

    code: {
      type: String, // e.g. "1266108"
      unique: true,
      required: true
    },

    clusterPoints: {
      type: Number, // e.g. 42.5
      required: true
    },

    price: {
      type: Number,
      default: 0,
    },

    thumbnail: {
      type: String, // URL or file path
    },

    published: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Course', courseSchema);

