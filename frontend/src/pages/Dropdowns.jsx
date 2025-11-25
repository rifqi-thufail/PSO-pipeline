import React, { useState, useEffect } from 'react';
import { Layout, Tabs, Table, Button, Input, Space, message, Modal, Form, Popconfirm, Tag } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';
import Navbar from '../components/Navbar';
import { getDropdowns, createDropdown, updateDropdown, deleteDropdown, toggleDropdown } from '../utils/api';
import { getHiddenDropdownIds, filterHiddenDropdowns } from '../utils/dropdownFilter';

const { Content } = Layout;

// Halaman Dropdowns Management
// Mengelola opsi dropdown untuk Division dan Placement
function Dropdowns({ user, onLogout }) {
  const [activeTab, setActiveTab] = useState('division');
  const [loading, setLoading] = useState(false);
  const [divisions, setDivisions] = useState([]);
  const [placements, setPlacements] = useState([]);
  
  // Track IDs that are "deleted" (hidden from UI) - persist in localStorage
  const [hiddenIds, setHiddenIds] = useState(() => getHiddenDropdownIds());
  
  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);
  const [form] = Form.useForm();

  // Fetch data saat component dimount atau tab berubah
  useEffect(() => {
    fetchData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, hiddenIds]);

  // Fungsi fetch data berdasarkan tipe
  const fetchData = async () => {
    setLoading(true);
    try {
      // Fetch all dropdowns including inactive ones (show all except manually hidden)
      const divData = await getDropdowns('division', false);
      const placeData = await getDropdowns('placement', false);
      
      // Filter out manually hidden items using utility function
      setDivisions(filterHiddenDropdowns(divData));
      setPlacements(filterHiddenDropdowns(placeData));
    } catch (error) {
      message.error('Failed to load data: ' + error);
    } finally {
      setLoading(false);
    }
  };

  // Handle create/edit
  const handleOpenModal = (item = null) => {
    setEditingItem(item);
    if (item) {
      form.setFieldsValue(item);
    } else {
      form.resetFields();
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingItem(null);
    form.resetFields();
  };

  const handleSubmit = async (values) => {
    try {
      // Auto-generate value from label (lowercase, replace spaces with hyphens)
      const generatedValue = values.label.toLowerCase().replace(/\s+/g, '-');
      
      const data = {
        label: values.label,
        value: generatedValue,
        type: activeTab,
      };

      if (editingItem) {
        // Update
        await updateDropdown(editingItem.id || editingItem._id, data);
        message.success('Option updated successfully');
      } else {
        // Create
        await createDropdown(data);
        message.success('Option added successfully');
      }

      handleCloseModal();
      fetchData();
    } catch (error) {
      message.error('Failed to save option: ' + error);
    }
  };

  // Handle delete
  // No longer used - keeping for backward compatibility
  // eslint-disable-next-line no-unused-vars
  const handleDelete = async (id) => {
    try {
      await deleteDropdown(id);
      message.success('Option deactivated successfully');
      fetchData();
    } catch (error) {
      message.error('Failed to deactivate option: ' + error);
    }
  };

  // Handle toggle status (activate/deactivate)
  const handleToggle = async (id, currentStatus) => {
    try {
      await toggleDropdown(id);
      message.success(`Option ${currentStatus ? 'deactivated' : 'activated'} successfully`);
      fetchData();
    } catch (error) {
      message.error('Failed to toggle option status: ' + error);
    }
  };

  // Handle permanent delete (hide from UI)
  const handlePermanentDelete = async (id, isActive) => {
    // Check if dropdown is still active
    if (isActive) {
      message.warning('Deactivate first before deleting any values');
      return;
    }

    // Hide from UI by adding to hiddenIds and save to localStorage
    const newHiddenIds = [...hiddenIds, id];
    setHiddenIds(newHiddenIds);
    localStorage.setItem('hiddenDropdownIds', JSON.stringify(newHiddenIds));
    message.success('Option removed from list successfully');
  };

  // Table columns
  const columns = [
    {
      title: 'No',
      key: 'no',
      width: 60,
      render: (_, __, index) => index + 1,
    },
    {
      title: 'Name',
      dataIndex: 'label',
      key: 'label',
    },
    {
      title: 'Status',
      key: 'status',
      width: 100,
      render: (_, record) => (
        <Tag color={record.isActive ? 'green' : 'red'} icon={record.isActive ? <CheckCircleOutlined /> : <CloseCircleOutlined />}>
          {record.isActive ? 'Active' : 'Inactive'}
        </Tag>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 150,
      render: (_, record) => (
        <Space direction="vertical" size="small" style={{ width: '100%' }}>
          <Button
            type="primary"
            icon={<EditOutlined />}
            size="small"
            onClick={() => handleOpenModal(record)}
            block
          >
            Edit
          </Button>
          <Popconfirm
            title={record.isActive ? 'Deactivate Option' : 'Activate Option'}
            description={record.isActive ? 'This option will be hidden from forms but data remains in database.' : 'This option will be visible in forms again.'}
            onConfirm={() => handleToggle(record.id || record._id, record.isActive)}
            okText="Yes"
            cancelText="No"
          >
            <Button
              danger={record.isActive}
              type={record.isActive ? 'default' : 'primary'}
              icon={record.isActive ? <CloseCircleOutlined /> : <CheckCircleOutlined />}
              size="small"
              block
            >
              {record.isActive ? 'Deactivate' : 'Activate'}
            </Button>
          </Popconfirm>
          <Popconfirm
            title="Permanently Delete Option"
            description={record.isActive ? "You must deactivate this option first before deleting." : "This will permanently delete this option from database. This cannot be undone!"}
            onConfirm={() => handlePermanentDelete(record.id || record._id, record.isActive)}
            okText="Yes"
            cancelText="No"
            okButtonProps={{ danger: true }}
          >
            <Button
              danger
              icon={<DeleteOutlined />}
              size="small"
              block
            >
              Delete
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  // Tabs items
  const tabItems = [
    {
      key: 'division',
      label: 'Material Owner (Division)',
      children: (
        <>
          <div style={{ marginBottom: '16px', padding: '12px', background: '#f0f7ff', borderRadius: '4px' }}>
            <strong>Material Owner (Division)</strong>
            <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: '#666' }}>
              Division or department that owns the material
            </p>
          </div>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            style={{ marginBottom: '16px' }}
            onClick={() => handleOpenModal()}
          >
            Add Material Owner
          </Button>
          <Table
            columns={columns}
            dataSource={divisions}
            rowKey={(record) => record.id || record._id}
            loading={loading}
            pagination={false}
          />
        </>
      ),
    },
    {
      key: 'placement',
      label: 'Material Placement',
      children: (
        <>
          <div style={{ marginBottom: '16px', padding: '12px', background: '#f0f7ff', borderRadius: '4px' }}>
            <strong>Material Placement</strong>
            <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: '#666' }}>
              Physical location where the material is stored
            </p>
          </div>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            style={{ marginBottom: '16px' }}
            onClick={() => handleOpenModal()}
          >
            Add Placement Location
          </Button>
          <Table
            columns={columns}
            dataSource={placements}
            rowKey={(record) => record.id || record._id}
            loading={loading}
            pagination={false}
          />
        </>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {/* Navbar */}
      <Navbar user={user} onLogout={onLogout} />

      {/* Main Content */}
      <Content style={{ padding: '24px' }}>
        <div style={{ background: '#fff', padding: '24px', borderRadius: '8px' }}>
          {/* Header */}
          <div style={{ marginBottom: '24px' }}>
            <h1>Dropdown Management</h1>
            <p style={{ color: '#888' }}>
              Manage dropdown options for Material Owner (Division) and Material Placement.
              These options will be used when creating or editing materials.
            </p>
          </div>

          {/* Tabs */}
          <Tabs
            activeKey={activeTab}
            items={tabItems}
            onChange={setActiveTab}
          />
        </div>
      </Content>

      {/* Modal Form */}
      <Modal
        title={editingItem ? `Edit ${activeTab === 'division' ? 'Material Owner' : 'Placement'}` : `Add New ${activeTab === 'division' ? 'Material Owner' : 'Placement'}`}
        open={isModalOpen}
        onCancel={handleCloseModal}
        footer={null}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
        >
          <Form.Item
            label="Name"
            name="label"
            rules={[{ required: true, message: 'Name is required!' }]}
            extra={activeTab === 'division' ? 'Example: IT Department, HR Division' : 'Example: Warehouse A, Storage Room 101'}
          >
            <Input placeholder={activeTab === 'division' ? 'IT Department' : 'Warehouse A'} />
          </Form.Item>

          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit">
                {editingItem ? 'Update' : 'Create'}
              </Button>
              <Button onClick={handleCloseModal}>
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </Layout>
  );
}

export default Dropdowns;
