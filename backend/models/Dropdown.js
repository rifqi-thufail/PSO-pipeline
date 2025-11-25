const pool = require('../config/database');

const Dropdown = {
  async create(type, label, value) {
    const query = `
      INSERT INTO dropdowns (type, label, value)
      VALUES ($1, $2, $3)
      RETURNING *
    `;
    const values = [type, label.trim(), value.trim()];
    const result = await pool.query(query, values);
    return result.rows[0];
  },

  async findById(id) {
    const query = 'SELECT * FROM dropdowns WHERE id = $1';
    const result = await pool.query(query, [id]);
    return result.rows[0];
  },

  async findByType(type, activeOnly = true) {
    let query = 'SELECT * FROM dropdowns WHERE type = $1';
    if (activeOnly) {
      query += ' AND is_active = true';
    }
    query += ' ORDER BY label ASC';
    const result = await pool.query(query, [type]);
    return result.rows;
  },

  async findByTypeAndValue(type, value) {
    const query = 'SELECT * FROM dropdowns WHERE type = $1 AND value = $2';
    const result = await pool.query(query, [type, value]);
    return result.rows[0];
  },

  async findAll(activeOnly = true) {
    let query = 'SELECT * FROM dropdowns';
    if (activeOnly) {
      query += ' WHERE is_active = true';
    }
    query += ' ORDER BY type, label ASC';
    const result = await pool.query(query);
    return result.rows;
  },

  async update(id, updates) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    if (updates.label) {
      fields.push(`label = $${paramCount}`);
      values.push(updates.label.trim());
      paramCount++;
    }

    if (updates.value) {
      fields.push(`value = $${paramCount}`);
      values.push(updates.value.trim());
      paramCount++;
    }

    if (updates.isActive !== undefined) {
      fields.push(`is_active = $${paramCount}`);
      values.push(updates.isActive);
      paramCount++;
    }

    if (fields.length === 0) return null;

    values.push(id);
    const query = `
      UPDATE dropdowns
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;
    const result = await pool.query(query, values);
    return result.rows[0];
  },

  async toggleActive(id) {
    const dropdown = await this.findById(id);
    if (!dropdown) return null;
    
    const query = `
      UPDATE dropdowns 
      SET is_active = $1
      WHERE id = $2
      RETURNING *
    `;
    const result = await pool.query(query, [!dropdown.is_active, id]);
    return result.rows[0];
  },

  async softDelete(id) {
    const query = `
      UPDATE dropdowns 
      SET is_active = false
      WHERE id = $1
      RETURNING *
    `;
    const result = await pool.query(query, [id]);
    return result.rows[0];
  },

  async delete(id) {
    const query = 'DELETE FROM dropdowns WHERE id = $1';
    await pool.query(query, [id]);
  },

  async checkUsage(id) {
    const query = `
      SELECT COUNT(*) as count FROM materials 
      WHERE division_id = $1 OR placement_id = $1
    `;
    const result = await pool.query(query, [id]);
    return parseInt(result.rows[0].count);
  }
};

module.exports = Dropdown;
