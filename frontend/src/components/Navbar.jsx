import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Layout, Menu, message, Avatar, Dropdown } from 'antd';
import { HomeOutlined, AppstoreOutlined, SettingOutlined, LogoutOutlined, UserOutlined, MenuOutlined } from '@ant-design/icons';
import { logout } from '../utils/api';
import './Navbar.css';

const { Header } = Layout;

// Component Navbar
// Menampilkan navigation bar dengan menu dan tombol logout
function Navbar({ user, onLogout }) {
  const navigate = useNavigate();
  const location = useLocation();
  const [scrolled, setScrolled] = useState(false);

  // Handle scroll effect
  useEffect(() => {
    const handleScroll = () => {
      const isScrolled = window.scrollY > 20;
      setScrolled(isScrolled);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Tentukan menu yang aktif berdasarkan current path
  const getSelectedKey = () => {
    const path = location.pathname;
    if (path === '/') return 'dashboard';
    if (path.startsWith('/materials')) return 'materials';
    if (path.startsWith('/dropdowns')) return 'dropdowns';
    return 'dashboard';
  };

  // Fungsi untuk handle logout
  const handleLogout = async () => {
    try {
      // Panggil logout API
      await logout();
      
      // Clear user data from localStorage
      localStorage.removeItem('user');
      
      // Clear user state in App.js
      if (onLogout) onLogout();
      
      // Show success message
      message.success('Logout successful');
      
      // Redirect to login page
      navigate('/login', { replace: true });
    } catch (error) {
      // If logout API fails, still clear localStorage and redirect
      console.error('Logout error:', error);
      localStorage.removeItem('user');
      if (onLogout) onLogout();
      navigate('/login', { replace: true });
    }
  };

  // Menu items untuk navigation
  const menuItems = [
    {
      key: 'dashboard',
      icon: <HomeOutlined />,
      label: <Link to="/">Dashboard</Link>,
    },
    {
      key: 'materials',
      icon: <AppstoreOutlined />,
      label: <Link to="/materials">Materials</Link>,
    },
    {
      key: 'dropdowns',
      icon: <SettingOutlined />,
      label: <Link to="/dropdowns">Settings</Link>,
    },
  ];

  // User dropdown menu
  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: 'Profile',
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Logout',
      danger: true,
      onClick: handleLogout,
    },
  ];

  return (
    <>
      <Header 
        className={`navbar-header ${scrolled ? 'scrolled' : ''}`}
        style={{ 
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          zIndex: 1000,
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center',
          background: scrolled 
            ? 'linear-gradient(135deg, rgba(102, 126, 234, 0.95) 0%, rgba(118, 75, 162, 0.95) 100%)'
            : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          padding: '0 24px',
          boxShadow: scrolled 
            ? '0 4px 20px rgba(0,0,0,0.25)' 
            : '0 2px 8px rgba(0,0,0,0.15)',
          borderBottom: '1px solid rgba(255,255,255,0.1)',
          height: '64px',
          transition: 'all 0.3s ease',
          backdropFilter: scrolled ? 'blur(20px)' : 'none'
        }}>
        {/* Logo dan Title */}
        <div 
          className="navbar-logo"
          style={{ 
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            color: 'white', 
            fontSize: '20px', 
            fontWeight: '600',
            letterSpacing: '0.5px',
            cursor: 'pointer'
          }}
          onClick={() => navigate('/')}
        >
          <div style={{
            width: '32px',
            height: '32px',
            background: 'rgba(255,255,255,0.2)',
            borderRadius: '8px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            backdropFilter: 'blur(10px)'
          }}>
            <AppstoreOutlined style={{ color: 'white', fontSize: '18px' }} />
          </div>
          <span>Material Management</span>
        </div>

        {/* Menu Navigation */}
        <Menu
          className="navbar-menu"
          theme="dark"
          mode="horizontal"
          selectedKeys={[getSelectedKey()]}
          items={menuItems}
          style={{ 
            flex: 1, 
            minWidth: 0, 
            marginLeft: '50px',
            background: 'transparent',
            border: 'none',
            fontSize: '14px',
            fontWeight: '500'
          }}
        />

        {/* User info dan Actions */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <span 
            className="welcome-text"
            style={{ 
              color: 'rgba(255,255,255,0.9)', 
              fontSize: '14px',
              fontWeight: '500'
            }}
          >
            Welcome, {user?.name?.split(' ')[0] || user?.email?.split('@')[0]}
          </span>
          
          <Dropdown
            menu={{ items: userMenuItems }}
            placement="bottomRight"
            trigger={['click']}
          >
            <div 
              className="user-dropdown"
              style={{ 
                display: 'flex', 
                alignItems: 'center', 
                gap: '8px',
                padding: '8px 12px',
                borderRadius: '24px',
                background: 'rgba(255,255,255,0.1)',
                cursor: 'pointer',
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                backdropFilter: 'blur(10px)'
              }}>
              <Avatar 
                size={32} 
                style={{ 
                  background: 'linear-gradient(45deg, #ff6b6b, #4ecdc4)',
                  color: 'white',
                  fontWeight: '600'
                }}
              >
                {(user?.name?.charAt(0) || user?.email?.charAt(0) || 'U').toUpperCase()}
              </Avatar>
              <MenuOutlined style={{ color: 'white', fontSize: '12px' }} />
            </div>
          </Dropdown>
        </div>
      </Header>
      
      {/* Spacer to prevent content from going under fixed header */}
      <div style={{ height: '64px' }} />
    </>
  );
}

export default Navbar;
