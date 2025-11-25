// Import packages yang dibutuhkan
const express = require('express');
const session = require('express-session');
const pgSession = require('connect-pg-simple')(session);
const cors = require('cors');
const path = require('path');
const pool = require('./config/database');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const materialRoutes = require('./routes/materials');
const dropdownRoutes = require('./routes/dropdowns');
const dashboardRoutes = require('./routes/dashboard');

// Inisialisasi Express app
const app = express();
const PORT = process.env.PORT || 5000;

// ======================================
// MIDDLEWARE SETUP
// ======================================

// CORS - mengizinkan request dari frontend
app.use(
  cors({
    origin: 'http://localhost:3000',
    credentials: true,
  })
);

// Body parser - untuk membaca request body
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Session setup - untuk authentication
app.use(
  session({
    store: new pgSession({
      pool: pool,
      tableName: 'session',
    }),
    secret: process.env.SESSION_SECRET || 'your-secret-key-here',
    resave: false,
    saveUninitialized: false,
    cookie: {
      maxAge: 24 * 60 * 60 * 1000,
      httpOnly: true,
      secure: false,
      sameSite: 'lax',
    },
  })
);

// Debug middleware - untuk lihat session
app.use((req, res, next) => {
  console.log('Session ID:', req.sessionID);
  console.log('Session Data:', req.session);
  next();
});

// Static folder untuk serve uploaded images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ======================================
// POSTGRESQL CONNECTION TEST
// ======================================

pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('PostgreSQL connection error:', err);
  } else {
    console.log('PostgreSQL connected successfully');
  }
});

// ======================================
// ROUTES
// ======================================

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ message: 'Material Management API is running!' });
});

// Mount API routes
app.use('/api/auth', authRoutes);
app.use('/api/materials', materialRoutes);
app.use('/api/dropdowns', dropdownRoutes);
app.use('/api/dashboard', dashboardRoutes);

// ======================================
// ERROR HANDLING
// ======================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
  });
});

// ======================================
// START SERVER
// ======================================

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
