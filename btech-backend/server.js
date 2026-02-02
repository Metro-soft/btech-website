const express = require('express');
const dotenv = require('dotenv');
const path = require('path');
const connectDB = require('./src/config/db');
// const academyRoutes = require('./routes/academyRoutes'); // Removed legacy



// Load env variables
dotenv.config();

// Connect to MongoDB
connectDB();

const app = express();

const cors = require('cors');

// Middleware
// Middleware
app.use(cors({
  origin: '*', // Allow all origins (or specify client URL)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-auth-token']
}));
app.use(express.json({ limit: '50mb' })); // Accept JSON with increased limit for Base64
app.use(express.urlencoded({ limit: '50mb', extended: true }));

const { rateLimiter, sqlInjectionDetector } = require('./src/shared/middlewares/securityLogger');
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// --- SECURITY MIDDLEWARE (Threat Detection) ---
app.use(rateLimiter);
app.use(sqlInjectionDetector);

// Set Static Folder for Uploads
// --- FILES (Shared Secure View) ---
app.use('/api/files/view', require('./src/shared/routes/file.routes'));

// --- CLIENT MODULE ---
app.use('/api/client/finance', require('./src/modules/client/finance/client.finance.routes'));
app.use('/api/client/orders', require('./src/modules/client/orders/client.orders.routes'));
app.use('/api/client/files', require('./src/modules/client/files/client.files.routes'));

// --- STAFF MODULE ---
app.use('/api/staff/dashboard', require('./src/modules/staff/dashboard/staff.dashboard.routes'));
app.use('/api/staff/tasks', require('./src/modules/staff/tasks/staff.tasks.routes'));
app.use('/api/staff/finance', require('./src/modules/staff/finance/staff.finance.routes'));

// --- ADMIN MODULE ---
app.use('/api/admin/workflow', require('./src/modules/admin/workflow/admin.workflow.routes'));
app.use('/api/admin/finance', require('./src/modules/admin/finance/admin.finance.routes'));

// --- SHARED PUBLIC APIs ---
app.use('/api/services', require('./src/shared/routes/services.routes'));
app.use('/api/courses', require('./src/shared/routes/courses.routes'));
app.use('/api/auth', require('./src/modules/auth/auth.routes'));


// Sample root route
app.get('/', (req, res) => {
  res.send('BTech Academy Backend is running');
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
