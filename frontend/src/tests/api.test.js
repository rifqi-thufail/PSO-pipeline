import axios from 'axios';
import {
  login,
  register,
  logout,
  checkAuth,
  getMaterials,
  createMaterial,
  getDropdowns,
  getDashboardStats
} from '../utils/api';

// Mock axios
jest.mock('axios');
const mockedAxios = axios;

// Mock axios instance
const mockAxiosInstance = {
  get: jest.fn(),
  post: jest.fn(),
  put: jest.fn(),
  delete: jest.fn(),
  patch: jest.fn(),
};

// Mock axios.create to return our mock instance
mockedAxios.create.mockReturnValue(mockAxiosInstance);

describe('API utility functions', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Auth API', () => {
    describe('login', () => {
      it('should login successfully', async () => {
        const mockResponse = {
          data: {
            success: true,
            user: { id: 1, email: 'test@example.com', name: 'Test User' }
          }
        };

        mockAxiosInstance.post.mockResolvedValue(mockResponse);

        const result = await login('test@example.com', 'password');

        expect(mockAxiosInstance.post).toHaveBeenCalledWith('/auth/login', {
          email: 'test@example.com',
          password: 'password'
        });
        expect(result).toEqual(mockResponse.data);
      });

      it('should handle login error', async () => {
        const mockError = {
          response: {
            data: { error: 'Invalid credentials' }
          }
        };

        mockAxiosInstance.post.mockRejectedValue(mockError);

        await expect(login('wrong@email.com', 'wrongpass')).rejects.toBe('Invalid credentials');
      });

      it('should handle network error', async () => {
        mockAxiosInstance.post.mockRejectedValue(new Error('Network error'));

        await expect(login('test@example.com', 'password')).rejects.toBe('Login failed');
      });
    });

    describe('register', () => {
      it('should register successfully', async () => {
        const mockResponse = {
          data: {
            success: true,
            message: 'User registered successfully',
            user: { id: 1, email: 'new@example.com', name: 'New User' }
          }
        };

        mockAxiosInstance.post.mockResolvedValue(mockResponse);

        const result = await register('New User', 'new@example.com', 'password');

        expect(mockAxiosInstance.post).toHaveBeenCalledWith('/auth/register', {
          name: 'New User',
          email: 'new@example.com',
          password: 'password'
        });
        expect(result).toEqual(mockResponse.data);
      });

      it('should handle registration error', async () => {
        const mockError = {
          response: {
            data: { error: 'Email already exists' }
          }
        };

        mockAxiosInstance.post.mockRejectedValue(mockError);

        await expect(register('Test', 'existing@email.com', 'pass')).rejects.toBe('Email already exists');
      });
    });

    describe('logout', () => {
      it('should logout successfully', async () => {
        const mockResponse = {
          data: { success: true, message: 'Logged out successfully' }
        };

        mockAxiosInstance.post.mockResolvedValue(mockResponse);

        const result = await logout();

        expect(mockAxiosInstance.post).toHaveBeenCalledWith('/auth/logout');
        expect(result).toEqual(mockResponse.data);
      });
    });

    describe('checkAuth', () => {
      it('should check auth successfully', async () => {
        const mockResponse = {
          data: {
            isAuthenticated: true,
            user: { id: 1, email: 'test@example.com' }
          }
        };

        mockAxiosInstance.get.mockResolvedValue(mockResponse);

        const result = await checkAuth();

        expect(mockAxiosInstance.get).toHaveBeenCalledWith('/auth/check');
        expect(result).toEqual(mockResponse.data);
      });

      it('should return null on error', async () => {
        mockAxiosInstance.get.mockRejectedValue(new Error('Network error'));

        const result = await checkAuth();

        expect(result).toBeNull();
      });
    });
  });

  describe('Material API', () => {
    describe('getMaterials', () => {
      it('should fetch materials with default params', async () => {
        const mockResponse = {
          data: { materials: [], total: 0 }
        };

        mockAxiosInstance.get.mockResolvedValue(mockResponse);

        const result = await getMaterials();

        expect(mockAxiosInstance.get).toHaveBeenCalledWith('/materials', { params: {} });
        expect(result).toEqual(mockResponse.data);
      });

      it('should fetch materials with custom params', async () => {
        const mockResponse = {
          data: { materials: [], total: 0 }
        };

        mockAxiosInstance.get.mockResolvedValue(mockResponse);

        const params = { search: 'test', page: 2 };
        await getMaterials(params);

        expect(mockAxiosInstance.get).toHaveBeenCalledWith('/materials', { params });
      });

      it('should handle materials fetch error', async () => {
        const mockError = {
          response: {
            data: { error: 'Failed to fetch materials' }
          }
        };

        mockAxiosInstance.get.mockRejectedValue(mockError);

        await expect(getMaterials()).rejects.toBe('Failed to fetch materials');
      });
    });

    describe('createMaterial', () => {
      it('should create material successfully', async () => {
        const mockResponse = {
          data: { success: true, material: { id: 1, name: 'Test Material' } }
        };

        mockAxiosInstance.post.mockResolvedValue(mockResponse);

        const materialData = { name: 'Test Material', divisionId: 1 };
        const result = await createMaterial(materialData);

        expect(mockAxiosInstance.post).toHaveBeenCalledWith('/materials', materialData);
        expect(result).toEqual(mockResponse.data);
      });
    });
  });

  describe('Dropdown API', () => {
    describe('getDropdowns', () => {
      it('should fetch dropdowns with default activeOnly=true', async () => {
        const mockResponse = {
          data: { dropdowns: [] }
        };

        mockAxiosInstance.get.mockResolvedValue(mockResponse);

        await getDropdowns('division');

        expect(mockAxiosInstance.get).toHaveBeenCalledWith('/dropdowns/division?activeOnly=true');
      });

      it('should fetch dropdowns with activeOnly=false', async () => {
        const mockResponse = {
          data: { dropdowns: [] }
        };

        mockAxiosInstance.get.mockResolvedValue(mockResponse);

        await getDropdowns('placement', false);

        expect(mockAxiosInstance.get).toHaveBeenCalledWith('/dropdowns/placement?activeOnly=false');
      });
    });
  });

  describe('Dashboard API', () => {
    describe('getDashboardStats', () => {
      it('should fetch dashboard stats successfully', async () => {
        const mockResponse = {
          data: { totalMaterials: 100, totalUsers: 10 }
        };

        mockAxiosInstance.get.mockResolvedValue(mockResponse);

        const result = await getDashboardStats();

        expect(mockAxiosInstance.get).toHaveBeenCalledWith('/dashboard/stats');
        expect(result).toEqual(mockResponse.data);
      });

      it('should handle dashboard stats error', async () => {
        const mockError = {
          response: {
            data: { error: 'Failed to fetch stats' }
          }
        };

        mockAxiosInstance.get.mockRejectedValue(mockError);

        await expect(getDashboardStats()).rejects.toBe('Failed to fetch stats');
      });
    });
  });
});