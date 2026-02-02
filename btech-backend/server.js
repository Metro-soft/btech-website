const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./src/config/db');
// const academyRoutes = require('./routes/academyRoutes'); // Removed legacy



// Load env variables
dotenv.config();

// Connect to MongoDB
connectDB();

const app = express();

const cors = require('cors');

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Accept JSON with increased limit for Base64
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Modular Routes
const authRoutes = require('./src/modules/auth/auth.routes');
const orderRoutes = require('./src/modules/client/orders/order.routes');
const adminDashboardRoutes = require('./src/modules/admin/dashboard/dashboard.routes');
const clientOrderRoutes = require('./src/modules/client/orders/order.routes'); // Changed from orderRoutes to order.routes
const walletRoutes = require('./src/modules/client/wallet/walletRoutes');
const staffRoutes = require('./src/modules/staff/staff.routes'); // New Staff Module

const errorHandler = require('./src/shared/middlewares/error'); // If exists

// Mount Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin/dashboard', adminDashboardRoutes);
app.use('/api/orders', clientOrderRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/applications', orderRoutes); // Kept legacy path for Frontend compatibility
app.use('/api/staff', staffRoutes); // New Staff Module
app.use('/api/services', require('./src/shared/routes/serviceRoutes'));
app.use('/api/courses', require('./src/shared/routes/courseRoutes'));


// Sample root route
app.get('/', (req, res) => {
  res.send('BTech Academy Backend is running');
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
