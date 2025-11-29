const bcrypt = require('bcrypt');

// Mock the database pool
const mockPool = {
  query: jest.fn()
};

// Mock the database config
jest.mock('../../config/database', () => mockPool);

// Import User model after mocking
const User = require('../../models/User');

describe('User Model', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('create', () => {
    it('should create a new user with hashed password', async () => {
      // Mock data
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        created_at: new Date(),
        updated_at: new Date()
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUser]
      });

      // Test user creation
      const result = await User.create('test@example.com', 'password123', 'Test User');

      expect(result).toEqual(mockUser);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO users'),
        expect.arrayContaining([
          'test@example.com',
          expect.any(String), // hashed password
          'Test User',
          'user'
        ])
      );
    });

    it('should create user with admin role when specified', async () => {
      const mockUser = {
        id: 2,
        email: 'admin@example.com',
        name: 'Admin User',
        role: 'admin',
        created_at: new Date(),
        updated_at: new Date()
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUser]
      });

      await User.create('admin@example.com', 'password123', 'Admin User', 'admin');

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.any(String),
        expect.arrayContaining(['admin@example.com', expect.any(String), 'Admin User', 'admin'])
      );
    });

    it('should trim email and name before storing', async () => {
      const mockUser = {
        id: 3,
        email: 'trimmed@example.com',
        name: 'Trimmed User',
        role: 'user',
        created_at: new Date(),
        updated_at: new Date()
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUser]
      });

      await User.create('  TRIMMED@EXAMPLE.COM  ', 'password123', '  Trimmed User  ');

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.any(String),
        expect.arrayContaining(['trimmed@example.com', expect.any(String), 'Trimmed User', 'user'])
      );
    });
  });

  describe('findByEmail', () => {
    it('should find user by email', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        password: 'hashedpassword',
        role: 'user'
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUser]
      });

      const result = await User.findByEmail('test@example.com');

      expect(result).toEqual(mockUser);
      expect(mockPool.query).toHaveBeenCalledWith(
        'SELECT * FROM users WHERE email = $1',
        ['test@example.com']
      );
    });

    it('should return undefined if user not found', async () => {
      mockPool.query.mockResolvedValue({
        rows: []
      });

      const result = await User.findByEmail('nonexistent@example.com');

      expect(result).toBeUndefined();
    });
  });

  describe('findById', () => {
    it('should find user by id without password', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        created_at: new Date(),
        updated_at: new Date()
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUser]
      });

      const result = await User.findById(1);

      expect(result).toEqual(mockUser);
      expect(mockPool.query).toHaveBeenCalledWith(
        'SELECT id, email, name, role, created_at, updated_at FROM users WHERE id = $1',
        [1]
      );
    });
  });

  describe('comparePassword', () => {
    it('should return true for correct password', async () => {
      const password = 'testpassword';
      const hashedPassword = await bcrypt.hash(password, 10);

      const result = await User.comparePassword(password, hashedPassword);

      expect(result).toBe(true);
    });

    it('should return false for incorrect password', async () => {
      const password = 'testpassword';
      const wrongPassword = 'wrongpassword';
      const hashedPassword = await bcrypt.hash(password, 10);

      const result = await User.comparePassword(wrongPassword, hashedPassword);

      expect(result).toBe(false);
    });
  });

  describe('update', () => {
    it('should update user name', async () => {
      const mockUpdatedUser = {
        id: 1,
        email: 'test@example.com',
        name: 'Updated Name',
        role: 'user',
        created_at: new Date(),
        updated_at: new Date()
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUpdatedUser]
      });

      const result = await User.update(1, { name: 'Updated Name' });

      expect(result).toEqual(mockUpdatedUser);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE users'),
        ['Updated Name', 1]
      );
    });

    it('should return null if no updates provided', async () => {
      const result = await User.update(1, {});

      expect(result).toBeNull();
      expect(mockPool.query).not.toHaveBeenCalled();
    });

    it('should update password with hashing', async () => {
      const mockUpdatedUser = {
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        role: 'user'
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUpdatedUser]
      });

      await User.update(1, { password: 'newpassword' });

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE users'),
        [expect.any(String), 1]
      );
    });
  });

  describe('delete', () => {
    it('should delete user by id', async () => {
      mockPool.query.mockResolvedValue({});

      await User.delete(1);

      expect(mockPool.query).toHaveBeenCalledWith(
        'DELETE FROM users WHERE id = $1',
        [1]
      );
    });
  });
});