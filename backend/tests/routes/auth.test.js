const request = require('supertest');
const express = require('express');

// Mock the User model
const mockUser = {
  findByEmail: jest.fn(),
  findById: jest.fn(),
  comparePassword: jest.fn(),
  create: jest.fn()
};

jest.mock('../../models/User', () => mockUser);

// Create test app
const createTestApp = () => {
  const app = express();
  app.use(express.json());
  
  // Mock session middleware
  app.use((req, res, next) => {
    req.session = {
      userId: null,
      destroy: jest.fn((callback) => callback()),
    };
    next();
  });

  // Mock res.clearCookie
  app.use((req, res, next) => {
    res.clearCookie = jest.fn();
    next();
  });

  const authRoutes = require('../../routes/auth');
  app.use('/api/auth', authRoutes);
  
  return app;
};

describe('Auth Routes', () => {
  let app;

  beforeEach(() => {
    app = createTestApp();
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('POST /api/auth/login', () => {
    it('should login user with valid credentials', async () => {
      const mockUserData = {
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        password: 'hashedpassword'
      };

      mockUser.findByEmail.mockResolvedValue(mockUserData);
      mockUser.comparePassword.mockResolvedValue(true);

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });

      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        success: true,
        user: {
          id: 1,
          email: 'test@example.com',
          name: 'Test User',
          role: 'user'
        }
      });
    });

    it('should return 400 if email or password is missing', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com'
          // password missing
        });

      expect(response.status).toBe(400);
      expect(response.body).toEqual({
        error: 'Please provide email and password'
      });
    });

    it('should return 401 if user not found', async () => {
      mockUser.findByEmail.mockResolvedValue(null);

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'password123'
        });

      expect(response.status).toBe(401);
      expect(response.body).toEqual({
        error: 'Invalid email or password'
      });
    });

    it('should return 401 if password is invalid', async () => {
      const mockUserData = {
        id: 1,
        email: 'test@example.com',
        password: 'hashedpassword'
      };

      mockUser.findByEmail.mockResolvedValue(mockUserData);
      mockUser.comparePassword.mockResolvedValue(false);

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'wrongpassword'
        });

      expect(response.status).toBe(401);
      expect(response.body).toEqual({
        error: 'Invalid email or password'
      });
    });

    it('should handle server errors', async () => {
      mockUser.findByEmail.mockRejectedValue(new Error('Database error'));

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });

      expect(response.status).toBe(500);
      expect(response.body).toEqual({
        error: 'Login failed. Please try again'
      });
    });
  });

  describe('POST /api/auth/register', () => {
    it('should register new user successfully', async () => {
      const newUser = {
        id: 1,
        email: 'newuser@example.com',
        name: 'New User',
        role: 'user'
      };

      mockUser.findByEmail.mockResolvedValue(null); // No existing user
      mockUser.create.mockResolvedValue(newUser);

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'newuser@example.com',
          password: 'password123',
          name: 'New User'
        });

      expect(response.status).toBe(201);
      expect(response.body).toEqual({
        success: true,
        message: 'User registered successfully',
        user: {
          id: 1,
          email: 'newuser@example.com',
          name: 'New User'
        }
      });
    });

    it('should return 400 if required fields are missing', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com'
          // password and name missing
        });

      expect(response.status).toBe(400);
      expect(response.body).toEqual({
        error: 'Please provide all required fields'
      });
    });

    it('should return 400 if email already exists', async () => {
      const existingUser = {
        id: 1,
        email: 'existing@example.com'
      };

      mockUser.findByEmail.mockResolvedValue(existingUser);

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'existing@example.com',
          password: 'password123',
          name: 'Test User'
        });

      expect(response.status).toBe(400);
      expect(response.body).toEqual({
        error: 'Email already registered'
      });
    });

    it('should handle server errors during registration', async () => {
      mockUser.findByEmail.mockResolvedValue(null);
      mockUser.create.mockRejectedValue(new Error('Database error'));

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'newuser@example.com',
          password: 'password123',
          name: 'New User'
        });

      expect(response.status).toBe(500);
      expect(response.body).toEqual({
        error: 'Registration failed. Please try again'
      });
    });
  });

  describe('GET /api/auth/check', () => {
    it('should return user data if authenticated', async () => {
      const app = express();
      app.use(express.json());
      
      // Mock authenticated session
      app.use((req, res, next) => {
        req.session = { userId: 1 };
        next();
      });

      const authRoutes = require('../../routes/auth');
      app.use('/api/auth', authRoutes);

      const userData = {
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        role: 'user'
      };

      mockUser.findById.mockResolvedValue(userData);

      const response = await request(app)
        .get('/api/auth/check');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        isAuthenticated: true,
        user: {
          id: 1,
          email: 'test@example.com',
          name: 'Test User',
          role: 'user'
        }
      });
    });

    it('should return not authenticated if no session', async () => {
      const response = await request(app)
        .get('/api/auth/check');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        isAuthenticated: false
      });
    });

    it('should return not authenticated if user not found', async () => {
      const app = express();
      app.use(express.json());
      
      app.use((req, res, next) => {
        req.session = { userId: 999 };
        next();
      });

      const authRoutes = require('../../routes/auth');
      app.use('/api/auth', authRoutes);

      mockUser.findById.mockResolvedValue(null);

      const response = await request(app)
        .get('/api/auth/check');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        isAuthenticated: false
      });
    });
  });

  describe('POST /api/auth/logout', () => {
    it('should logout user successfully', async () => {
      const response = await request(app)
        .post('/api/auth/logout');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        success: true,
        message: 'Logged out successfully'
      });
    });

    it('should handle session destruction errors', async () => {
      const app = express();
      app.use(express.json());
      
      app.use((req, res, next) => {
        req.session = {
          destroy: jest.fn((callback) => callback(new Error('Session error')))
        };
        res.clearCookie = jest.fn();
        next();
      });

      const authRoutes = require('../../routes/auth');
      app.use('/api/auth', authRoutes);

      const response = await request(app)
        .post('/api/auth/logout');

      expect(response.status).toBe(500);
      expect(response.body).toEqual({
        error: 'Logout failed'
      });
    });
  });
});