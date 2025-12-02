import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Layout, message, Avatar, Dropdown } from 'antd';
import { HomeOutlined, AppstoreOutlined, SettingOutlined, LogoutOutlined, MenuOutlined } from '@ant-design/icons';
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
          top: '20px',
          left: '24px',
          right: '24px',
          zIndex: 1000,
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center',
          background: scrolled 
            ? 'linear-gradient(135deg, rgba(30, 58, 138, 0.9) 0%, rgba(59, 130, 246, 0.9) 50%, rgba(147, 197, 253, 0.9) 100%)'
            : 'linear-gradient(135deg, rgba(30, 58, 138, 0.8) 0%, rgba(59, 130, 246, 0.8) 50%, rgba(147, 197, 253, 0.8) 100%)',
          padding: '16px 28px',
          boxShadow: scrolled 
            ? '0 12px 40px rgba(0, 0, 0, 0.15)' 
            : '0 8px 32px rgba(0, 0, 0, 0.1)',
          border: 'none',
          height: '72px',
          borderRadius: '20px',
          transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
          backdropFilter: scrolled ? 'blur(25px)' : 'blur(20px)'
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
            width: '36px',
            height: '36px',
            background: 'linear-gradient(135deg, rgba(255, 255, 255, 0.3) 0%, rgba(255, 255, 255, 0.1) 100%)',
            borderRadius: '12px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            backdropFilter: 'blur(10px)',
            border: 'none',
            boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)'
          }}>
            <AppstoreOutlined style={{ color: 'white', fontSize: '20px' }} />
          </div>
          <span>Material Management</span>
        </div>

        {/* Menu Navigation - Custom Implementation */}
        <div style={{
          flex: 1,
          minWidth: 0,
          marginLeft: '50px',
          display: 'flex',
          alignItems: 'center',
          gap: '8px'
        }}>
          {menuItems.map((item) => (
            <div
              key={item.key}
              className={`nav-menu-item ${getSelectedKey() === item.key ? 'active' : ''}`}
              onClick={() => {
                if (item.key === 'dashboard') navigate('/');
                else if (item.key === 'materials') navigate('/materials');
                else if (item.key === 'dropdowns') navigate('/dropdowns');
              }}
            >
              {item.icon}
              <span>{item.label.props.children}</span>
            </div>
          ))}
        </div>

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
                padding: '10px 16px',
                borderRadius: '28px',
                background: 'linear-gradient(135deg, rgba(255, 255, 255, 0.15) 0%, rgba(255, 255, 255, 0.05) 100%)',
                cursor: 'pointer',
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                backdropFilter: 'blur(10px)',
                border: 'none',
                boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)'
              }}>
              <Avatar 
                size={36} 
                style={{ 
                  background: 'linear-gradient(135deg, #3b82f6 0%, #1e40af 100%)',
                  color: 'white',
                  fontWeight: '600',
                  border: 'none'
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
      <div style={{ height: '112px' }} />
    </>
  );
}

export default Navbar;
