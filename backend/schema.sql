-- Create database
-- Run this first: CREATE DATABASE material_management;

-- Connect to the database before running the following commands

-- Drop tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS materials CASCADE;
DROP TABLE IF EXISTS dropdowns CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS session CASCADE;

-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create dropdowns table
CREATE TABLE dropdowns (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL CHECK (type IN ('division', 'placement')),
    label VARCHAR(255) NOT NULL,
    value VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(type, value)
);

-- Create materials table
CREATE TABLE materials (
    id SERIAL PRIMARY KEY,
    material_name VARCHAR(255) NOT NULL,
    material_number VARCHAR(255) UNIQUE NOT NULL,
    division_id INTEGER REFERENCES dropdowns(id) ON DELETE SET NULL,
    placement_id INTEGER REFERENCES dropdowns(id) ON DELETE SET NULL,
    function TEXT,
    images JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create session table for express-session
CREATE TABLE session (
    sid VARCHAR NOT NULL COLLATE "default",
    sess JSON NOT NULL,
    expire TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (sid)
);

CREATE INDEX idx_session_expire ON session (expire);

-- Create indexes for better performance
CREATE INDEX idx_materials_division ON materials(division_id);
CREATE INDEX idx_materials_placement ON materials(placement_id);
CREATE INDEX idx_materials_number ON materials(material_number);
CREATE INDEX idx_dropdowns_type ON dropdowns(type);
CREATE INDEX idx_users_email ON users(email);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dropdowns_updated_at BEFORE UPDATE ON dropdowns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_materials_updated_at BEFORE UPDATE ON materials
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for dropdowns
INSERT INTO dropdowns (type, label, value) VALUES
('division', 'IT Division', 'it'),
('division', 'HR Division', 'hr'),
('division', 'Finance Division', 'finance'),
('division', 'Operations Division', 'operations'),
('placement', 'Warehouse A', 'warehouse-a'),
('placement', 'Warehouse B', 'warehouse-b'),
('placement', 'Office Floor 1', 'office-1'),
('placement', 'Office Floor 2', 'office-2');

-- Insert default admin user (password: admin123)
-- Note: You need to hash the password in your application
INSERT INTO users (email, password, name, role) VALUES
('admin@example.com', '$2b$10$rBV2JDeWW3.w7D5vVbH6t.5QjJZJ5qYQqZKZ7N1K7XQ3mPJqPqK.y', 'Admin User', 'admin');
