const express = require('express');
const dotenv = require('dotenv');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
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
app.use('/api/admin/audit', require('./src/modules/admin/audit/admin.audit.routes'));

// --- SHARED PUBLIC APIs ---
app.use('/api/services', require('./src/shared/routes/services.routes'));

// Routes
app.use('/api/auth', require('./src/modules/auth/auth.routes'));
app.use('/api/notifications', require('./src/modules/notifications/notification.routes'));
app.use('/api/clients', require('./src/modules/client/client.routes'));

// --- AI MODULE ---
app.use('/api/ai', require('./src/modules/ai/ai.routes'));

// Sample root route
app.get('/', (req, res) => {
  res.send('BTech Academy Backend is running');
});

// Start server
const PORT = process.env.PORT || 5000;

// Create HTTP server to allow Socket.IO to attach
const server = http.createServer(app);

// Initialize Socket.IO
const io = socketIo(server, {
  cors: {
    origin: "*", // Allow connections from frontend
    methods: ["GET", "POST"]
  }
});

// Attach IO to global so services can use it
global.io = io;

// Socket Middleware for Auth
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication error'));

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.user = decoded; // { id, role }
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
});

// Socket Connection Logic
io.on('connection', (socket) => {
  console.log(`User Connected: ${socket.user.id}`);

  // Join a room named after the User ID (Private Channel)
  socket.join(socket.user.id);

  socket.on('disconnect', () => {
    // console.log('User Disconnected');
  });
});

server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
