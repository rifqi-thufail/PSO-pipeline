import React, { useState, useEffect } from 'react';
import { Layout, Card, Row, Col, Spin, message } from 'antd';
import { AppstoreOutlined, CheckCircleOutlined, PieChartOutlined, StarOutlined, BoxPlotOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import Navbar from '../components/Navbar';
import { getDashboardStats } from '../utils/api';
import './Dashboard.css';

const { Content } = Layout;

// Halaman Dashboard (Homepage)
// Menampilkan statistik dan katalog material
function Dashboard({ user, onLogout }) {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState(null);

  // Fetch data statistik saat component dimount
  useEffect(() => {
    fetchStats();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Fungsi untuk fetch data dari API
  const fetchStats = async () => {
    try {
      const data = await getDashboardStats();
      setStats(data);
    } catch (error) {
      // Jika error 401 (Unauthorized), redirect ke login
      if (error.includes('401') || error.includes('Unauthorized')) {
        message.error('Session expired. Please login again.');
        localStorage.removeItem('user');
        if (onLogout) onLogout(); // Clear user state di App.js
        navigate('/login', { replace: true });
      } else {
        message.error('Failed to load data: ' + error);
      }
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Layout style={{ minHeight: '100vh', background: '#ffffff' }}>
        <Navbar user={user} onLogout={onLogout} />
        <Content className="page-content">
          <div className="dashboard-loading">
            <Spin size="large" />
          </div>
        </Content>
      </Layout>
    );
  }

  return (
    <Layout style={{ minHeight: '100vh', background: '#ffffff' }}>
      {/* Navbar */}
      <Navbar user={user} onLogout={onLogout} />

      {/* Main Content */}
      <Content className="page-content">
        <div className="dashboard-content">
          {/* Welcome Section */}
          <div className="dashboard-section">
            <h1 className="dashboard-title">Welcome, {user?.name}!</h1>
            <p className="dashboard-subtitle">Here's your material management overview</p>
          </div>

          {/* Statistics Cards */}
          <div className="dashboard-section">
            <h2 className="dashboard-section-title">
              <div className="dashboard-section-icon">
                <PieChartOutlined />
              </div>
              Key Metrics
            </h2>
            <Row gutter={[24, 24]}>
              {/* Total Materials */}
              <Col xs={24} sm={12} md={8}>
                <div className="metric-card">
                  <div className="metric-icon-badge">
                    <AppstoreOutlined />
                  </div>
                  <div className="metric-label">Total Materials</div>
                  <div className="metric-value">{stats?.totalMaterials || 0}</div>
                  <div className="metric-subtext">All registered materials</div>
                </div>
              </Col>

              {/* Active Materials */}
              <Col xs={24} sm={12} md={8}>
                <div className="metric-card">
                  <div className="metric-icon-badge">
                    <CheckCircleOutlined />
                  </div>
                  <div className="metric-label">Active Materials</div>
                  <div className="metric-value">{stats?.activeMaterials || 0}</div>
                  <div className="metric-subtext">Currently in use</div>
                </div>
              </Col>

              {/* Divisions */}
              <Col xs={24} sm={12} md={8}>
                <div className="metric-card">
                  <div className="metric-icon-badge">
                    <BoxPlotOutlined />
                  </div>
                  <div className="metric-label">Divisions</div>
                  <div className="metric-value">{stats?.totalDivisions || 0}</div>
                  <div className="metric-subtext">Department categories</div>
                </div>
              </Col>
            </Row>
          </div>

          {/* Materials by Division */}
          <div className="dashboard-section">
            <Card className="dashboard-card" title={
              <span className="dashboard-section-title" style={{ margin: 0 }}>
                <div className="dashboard-section-icon">
                  <PieChartOutlined />
                </div>
                Materials by Division
              </span>
            }>
              <Row gutter={[16, 16]}>
                {stats?.materialsByDivision?.map((item, index) => (
                  <Col xs={24} sm={12} md={6} key={index}>
                    <div className="division-card">
                      <div className="division-count">{item.count}</div>
                      <div className="division-name">
                        {item.division || 'Unknown'}
                      </div>
                    </div>
                  </Col>
                ))}
              </Row>
            </Card>
          </div>

          {/* Recent Materials Catalog */}
          <div className="dashboard-section">
            <Card className="dashboard-card" title={
              <span className="dashboard-section-title" style={{ margin: 0 }}>
                <div className="dashboard-section-icon">
                  <StarOutlined />
                </div>
                Recent Materials
              </span>
            }>
              <Row gutter={[20, 20]}>
                {stats?.recentMaterials?.map((material) => (
                  <Col xs={24} sm={12} md={8} lg={6} key={material.id || material._id}>
                    <Card
                      className="material-card"
                      cover={
                        material.images && material.images.length > 0 ? (
                          <img
                            alt={material.materialName}
                            src={`${window.location.origin}${material.images[0].url}`}
                            style={{ height: '200px', objectFit: 'cover' }}
                            onError={(e) => {
                              e.target.style.display = 'none';
                              e.target.parentElement.innerHTML = `
                                <div style="height: 200px; background: linear-gradient(135deg, #F8FAFC 0%, #F1F5F9 100%); display: flex; align-items: center; justify-content: center; color: #94A3B8; font-weight: 500;">
                                  Image Not Available
                                </div>
                              `;
                            }}
                          />
                        ) : (
                          <div style={{
                            height: '200px',
                            background: 'linear-gradient(135deg, #F8FAFC 0%, #F1F5F9 100%)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: '#94A3B8',
                            fontWeight: '500'
                          }}>
                            No Image
                          </div>
                        )
                      }
                    >
                      <Card.Meta
                        title={material.materialName}
                        description={
                          <>
                            <div style={{ marginBottom: '8px' }}>
                              <strong style={{ color: '#64748B' }}>No:</strong> {material.materialNumber}
                            </div>
                            <div style={{ marginBottom: '12px' }}>
                              <strong style={{ color: '#64748B' }}>Division:</strong> 
                              <span className="division-badge">{material.divisionId?.label}</span>
                            </div>
                            <div style={{ fontSize: '12px', color: '#94A3B8', marginTop: '12px' }}>
                              <strong>Created:</strong> {material.createdAt ? new Date(material.createdAt).toLocaleString('id-ID', {
                                year: 'numeric',
                                month: 'short',
                                day: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit'
                              }) : '-'}
                            </div>
                          </>
                        }
                      />
                    </Card>
                  </Col>
                ))}
              </Row>

              {/* Empty State */}
              {(!stats?.recentMaterials || stats.recentMaterials.length === 0) && (
                <div className="empty-state">
                  <div className="empty-state-icon">
                    <BoxPlotOutlined />
                  </div>
                  <p style={{ fontSize: '1.1rem', fontWeight: '500', color: '#64748B' }}>
                    No materials yet. Please add new materials.
                  </p>
                </div>
              )}
            </Card>
          </div>
        </div>
      </Content>
    </Layout>
  );
}

export default Dashboard;
