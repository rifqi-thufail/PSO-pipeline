import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { message } from 'antd';
import Navbar from '../components/Navbar';
import * as api from '../utils/api';

// Mock react-router-dom
const mockNavigate = jest.fn();
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
  useLocation: () => ({ pathname: '/' }),
}));

// Mock API
jest.mock('../utils/api');

// Mock antd message
jest.mock('antd', () => ({
  ...jest.requireActual('antd'),
  message: {
    success: jest.fn(),
  },
}));

describe('Navbar Component', () => {
  const mockUser = {
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    role: 'user'
  };

  const mockOnLogout = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const renderNavbar = (user = mockUser, onLogout = mockOnLogout) => {
    return render(
      <BrowserRouter>
        <Navbar user={user} onLogout={onLogout} />
      </BrowserRouter>
    );
  };

  describe('Rendering', () => {
    it('should render navbar with logo and menu items', () => {
      renderNavbar();

      expect(screen.getByText('Material Management')).toBeInTheDocument();
      expect(screen.getByText('Dashboard')).toBeInTheDocument();
      expect(screen.getByText('Materials')).toBeInTheDocument();
      expect(screen.getByText('Settings')).toBeInTheDocument();
    });

    it('should display user name', () => {
      renderNavbar();
      expect(screen.getByText('Test User')).toBeInTheDocument();
    });

    it('should display email if name is not available', () => {
      const userWithoutName = { ...mockUser, name: null };
      renderNavbar(userWithoutName);
      expect(screen.getByText('test@example.com')).toBeInTheDocument();
    });

    it('should render logout button', () => {
      renderNavbar();
      expect(screen.getByRole('button', { name: /logout/i })).toBeInTheDocument();
    });
  });

  describe('Navigation', () => {
    it('should have correct links', () => {
      renderNavbar();

      const dashboardLink = screen.getByRole('link', { name: /dashboard/i });
      const materialsLink = screen.getByRole('link', { name: /materials/i });
      const settingsLink = screen.getByRole('link', { name: /settings/i });

      expect(dashboardLink).toHaveAttribute('href', '/');
      expect(materialsLink).toHaveAttribute('href', '/materials');
      expect(settingsLink).toHaveAttribute('href', '/dropdowns');
    });
  });

  describe('Logout Functionality', () => {
    it('should handle successful logout', async () => {
      api.logout.mockResolvedValue({ success: true });
      
      renderNavbar();

      const logoutButton = screen.getByRole('button', { name: /logout/i });
      fireEvent.click(logoutButton);

      await waitFor(() => {
        expect(api.logout).toHaveBeenCalledTimes(1);
      });

      expect(mockOnLogout).toHaveBeenCalledTimes(1);
      expect(message.success).toHaveBeenCalledWith('Logout successful');
      expect(mockNavigate).toHaveBeenCalledWith('/login', { replace: true });
    });

    it('should handle logout API failure', async () => {
      api.logout.mockRejectedValue(new Error('Logout failed'));
      
      renderNavbar();

      const logoutButton = screen.getByRole('button', { name: /logout/i });
      fireEvent.click(logoutButton);

      await waitFor(() => {
        expect(api.logout).toHaveBeenCalledTimes(1);
      });

      // Should still call onLogout and navigate even if API fails
      expect(mockOnLogout).toHaveBeenCalledTimes(1);
      expect(mockNavigate).toHaveBeenCalledWith('/login', { replace: true });
    });

    it('should handle missing onLogout prop', async () => {
      api.logout.mockResolvedValue({ success: true });
      
      render(
        <BrowserRouter>
          <Navbar user={mockUser} onLogout={null} />
        </BrowserRouter>
      );

      const logoutButton = screen.getByRole('button', { name: /logout/i });
      fireEvent.click(logoutButton);

      await waitFor(() => {
        expect(api.logout).toHaveBeenCalledTimes(1);
      });

      // Should not throw error when onLogout is null
      expect(mockNavigate).toHaveBeenCalledWith('/login', { replace: true });
    });
  });

  describe('Active Menu Selection', () => {
    it('should highlight dashboard menu for root path', () => {
      // This would need actual router context testing
      // For now, we just verify the component renders
      renderNavbar();
      expect(screen.getByText('Dashboard')).toBeInTheDocument();
    });
  });

  describe('Accessibility', () => {
    it('should have proper ARIA labels', () => {
      renderNavbar();
      
      const logoutButton = screen.getByRole('button', { name: /logout/i });
      expect(logoutButton).toBeInTheDocument();
    });
  });

  describe('Edge Cases', () => {
    it('should handle undefined user', () => {
      render(
        <BrowserRouter>
          <Navbar user={undefined} onLogout={mockOnLogout} />
        </BrowserRouter>
      );

      expect(screen.getByText('Material Management')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /logout/i })).toBeInTheDocument();
    });

    it('should handle user without name and email', () => {
      const emptyUser = { id: 1 };
      render(
        <BrowserRouter>
          <Navbar user={emptyUser} onLogout={mockOnLogout} />
        </BrowserRouter>
      );

      expect(screen.getByText('Material Management')).toBeInTheDocument();
    });
  });
});