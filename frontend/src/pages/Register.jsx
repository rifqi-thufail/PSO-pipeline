import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Form, Input, Button, Card, message } from 'antd';
import { UserOutlined, LockOutlined, MailOutlined } from '@ant-design/icons';
import { register } from '../utils/api';

// Halaman Register
// User membuat akun baru dengan nama, email, dan password
function Register() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);

  // Fungsi yang dijalankan saat form disubmit
  const onFinish = async (values) => {
    setLoading(true);
    try {
      // Panggil API register
      await register(values.name, values.email, values.password);
      
      // Show success message
      message.success('Registration successful! Please login.');
      
      // Redirect to login page
      navigate('/login');
    } catch (error) {
      // Show error message
      message.error('Registration failed: ' + error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      minHeight: '100vh',
      backgroundImage: 'url(/BG.webp)',
      backgroundSize: 'cover',
      backgroundPosition: 'center',
      backgroundRepeat: 'no-repeat'
    }}>
      <Card 
        title={
          <div style={{ textAlign: 'center' }}>
            <h2 style={{ marginTop: '8px', marginBottom: '4px' }}>Material Management</h2>
            <p style={{ color: '#888', fontSize: '14px', margin: 0 }}>Create your account</p>
          </div>
        }
        style={{ width: 400, boxShadow: '0 4px 8px rgba(0,0,0,0.1)' }}
      >
        <Form
          name="register"
          onFinish={onFinish}
          autoComplete="off"
          layout="vertical"
        >
          {/* Input Name */}
          <Form.Item
            label="Name"
            name="name"
            rules={[
              { required: true, message: 'Please enter your name!' },
              { min: 3, message: 'Name must be at least 3 characters!' }
            ]}
          >
            <Input 
              prefix={<UserOutlined />} 
              placeholder="Full name" 
              size="large"
            />
          </Form.Item>

          {/* Input Email */}
          <Form.Item
            label="Email"
            name="email"
            rules={[
              { required: true, message: 'Please enter your email!' },
              { type: 'email', message: 'Invalid email format!' }
            ]}
          >
            <Input 
              prefix={<MailOutlined />} 
              placeholder="email@example.com" 
              size="large"
            />
          </Form.Item>

          {/* Input Password */}
          <Form.Item
            label="Password"
            name="password"
            rules={[
              { required: true, message: 'Please enter your password!' },
              { min: 6, message: 'Password must be at least 6 characters!' }
            ]}
          >
            <Input.Password 
              prefix={<LockOutlined />} 
              placeholder="Password" 
              size="large"
            />
          </Form.Item>

          {/* Input Confirm Password */}
          <Form.Item
            label="Confirm Password"
            name="confirmPassword"
            dependencies={['password']}
            rules={[
              { required: true, message: 'Please confirm your password!' },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('password') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error('Passwords do not match!'));
                },
              }),
            ]}
          >
            <Input.Password 
              prefix={<LockOutlined />} 
              placeholder="Confirm password" 
              size="large"
            />
          </Form.Item>

          {/* Submit Button */}
          <Form.Item>
            <Button 
              type="primary" 
              htmlType="submit" 
              block 
              size="large"
              loading={loading}
            >
              Register
            </Button>
          </Form.Item>

          <div style={{ textAlign: 'center', marginTop: '10px' }}>
            <span style={{ color: '#888' }}>Already have an account? </span>
            <Link to="/login">Login here</Link>
          </div>
        </Form>
      </Card>
    </div>
  );
}

export default Register;
