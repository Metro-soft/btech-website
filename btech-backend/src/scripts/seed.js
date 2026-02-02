const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Service = require('../shared/models/Service');
const Course = require('../shared/models/Course');
const path = require('path');

// Try loading from default (cwd) or explicit path
require('dotenv').config(); 
// Fallback if that didn't work (e.g. separate process context)
if (!process.env.MONGODB_URI) {
  require('dotenv').config({ path: path.join(__dirname, '../../.env') });
}

const services = [
  // --- KRA SERVICES ---
  {
    title: 'File Returns',
    category: 'KRA',
    subcategory: 'Employment Returns',
    description: 'File your annual employment returns (P9).',
    requirements: ['KRA PIN', 'iTax Password', 'P9 Form'],
    basePrice: 500,
    tags: ['kra', 'p9', 'returns', 'tax']
  },
  {
    title: 'File Nil Returns',
    category: 'KRA',
    subcategory: 'Nil Returns',
    description: 'For those with no income to declare.',
    requirements: ['KRA PIN', 'iTax Password'],
    basePrice: 200,
    tags: ['kra', 'nil', 'returns', 'zero']
  },
  {
    title: 'New Personal PIN',
    category: 'KRA',
    subcategory: 'Registration',
    description: 'Register for a new Personal KRA PIN.',
    requirements: ['National ID Copy', 'Email', 'Phone'],
    basePrice: 300,
    tags: ['kra', 'pin', 'registration', 'new']
  },
  {
    title: 'Tax Compliance Certificate',
    category: 'KRA',
    subcategory: 'Compliance',
    description: 'Apply for a Tax Compliance Certificate (TCC).',
    requirements: ['KRA PIN', 'iTax Password'],
    basePrice: 500,
    tags: ['kra', 'tcc', 'compliance', 'certificate']
  },
  
  // --- HELB SERVICES ---
  {
    title: 'First Time Application',
    category: 'HELB',
    description: 'Apply for HELB loan for the first time.',
    requirements: ['National ID', 'KCSE Result Slip', 'Passport Photo', 'Bank Account'],
    basePrice: 500,
    tags: ['helb', 'loan', 'first', 'university']
  },
  {
    title: 'Subsequent Application',
    category: 'HELB',
    description: 'Apply for second or subsequent HELB loan.',
    requirements: ['National ID', 'HELB Portal Password'],
    basePrice: 300,
    tags: ['helb', 'loan', 'subsequent', 'renewal']
  },

  // --- ETA SERVICES ---
  {
    title: 'East Africa Tourist Visa',
    category: 'ETA',
    description: 'Single entry tourist visa for Kenya, Uganda, Rwanda.',
    requirements: ['Passport', 'Photo', 'Itinerary'],
    basePrice: 1000,
    tags: ['eta', 'visa', 'tourist', 'travel']
  },
  {
    title: 'Transit eTA',
    category: 'ETA',
    description: 'Authority to transit through Kenya (Max 72h).',
    requirements: ['Passport', 'Flight Ticket'],
    basePrice: 800,
    tags: ['eta', 'visa', 'transit', 'travel']
  }
];

const courses = [
  {
    code: '1266108',
    title: 'Bachelor of Science (Computer Science)',
    university: 'University of Nairobi',
    clusterPoints: 42.5,
    category: 'Degree',
    description: 'Study software engineering, algorithms, and AI.',
    instructor: '6578a1b2c3d4e5f678901234', // Placeholder ObjectId, will need a real user or leave dummy
    price: 0
  },
  {
    code: '1266109',
    title: 'Bachelor of Medicine and Surgery',
    university: 'University of Nairobi',
    clusterPoints: 45.0,
    category: 'Degree',
    description: 'Train to become a medical doctor.',
    instructor: '6578a1b2c3d4e5f678901234',
    price: 0
  },
  {
    code: '1266113',
    title: 'Diploma in ICT',
    university: 'Technical University of Kenya',
    clusterPoints: 25.0,
    category: 'Diploma',
    description: 'Foundational skills in Information Technology.',
    instructor: '6578a1b2c3d4e5f678901234',
    price: 0
  }
];

const seedDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('📦 Connected to MongoDB');

    // Clear existing
    await Service.deleteMany({});
    await Course.deleteMany({});
    console.log('🧹 Cleared existing data');

    // Insert Services
    await Service.insertMany(services);
    console.log(`✅ Seeded ${services.length} services`);

    // Insert Courses (Hack: Need a valid user ID for instructor)
    // We'll find the first user in DB or create a dummy objectId if allowed by schema
    // Schema says required: true. Let's try to find an admin.
    const admin = await mongoose.connection.collection('users').findOne({ role: 'admin' });
    const instructorId = admin ? admin._id : new mongoose.Types.ObjectId();

    const coursesWithInstructor = courses.map(c => ({ ...c, instructor: instructorId }));
    await Course.insertMany(coursesWithInstructor);
    console.log(`✅ Seeded ${courses.length} courses`);

    console.log('🚀 Seeding complete');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
  }
};

seedDB();
