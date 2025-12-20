const pool = require('../config/database');

const Material = {
  async create(materialData) {
    const { materialName, materialNumber, divisionId, placementId, function: materialFunction } = materialData;
    const query = `
      INSERT INTO materials (material_name, material_number, division_id, placement_id, function)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    const values = [
      materialName.trim(),
      materialNumber.trim(),
      divisionId,
      placementId,
      materialFunction || null
    ];
    const result = await pool.query(query, values);
    return result.rows[0];
  },

  async findById(id) {
    const query = `
      SELECT 
        m.*,
        json_build_object('id', d1.id, 'label', d1.label, 'value', d1.value) as division,
        json_build_object('id', d2.id, 'label', d2.label, 'value', d2.value) as placement
      FROM materials m
      LEFT JOIN dropdowns d1 ON m.division_id = d1.id
      LEFT JOIN dropdowns d2 ON m.placement_id = d2.id
      WHERE m.id = $1
    `;
    const result = await pool.query(query, [id]);
    return result.rows[0];
  },

  async findAll(filters = {}) {
    let query = `
      SELECT 
        m.*,
        json_build_object('id', d1.id, 'label', d1.label, 'value', d1.value) as division,
        json_build_object('id', d2.id, 'label', d2.label, 'value', d2.value) as placement
      FROM materials m
      LEFT JOIN dropdowns d1 ON m.division_id = d1.id
      LEFT JOIN dropdowns d2 ON m.placement_id = d2.id
      WHERE 1=1
    `;
    const values = [];
    let paramCount = 1;

    if (filters.search) {
      query += ` AND (m.material_name ILIKE $${paramCount} OR m.material_number ILIKE $${paramCount})`;
      values.push(`%${filters.search}%`);
      paramCount++;
    }

    if (filters.divisionId) {
      query += ` AND m.division_id = $${paramCount}`;
      values.push(filters.divisionId);
      paramCount++;
    }

    if (filters.placementId) {
      query += ` AND m.placement_id = $${paramCount}`;
      values.push(filters.placementId);
      paramCount++;
    }

    query += ' ORDER BY m.created_at DESC';

    if (filters.limit) {
      query += ` LIMIT $${paramCount}`;
      values.push(filters.limit);
      paramCount++;

      if (filters.offset) {
        query += ` OFFSET $${paramCount}`;
        values.push(filters.offset);
        paramCount++;
      }
    }

    const result = await pool.query(query, values);
    return result.rows;
  },

  async count(filters = {}) {
    let query = 'SELECT COUNT(*) FROM materials WHERE 1=1';
    const values = [];
    let paramCount = 1;

    if (filters.search) {
      query += ` AND (material_name ILIKE $${paramCount} OR material_number ILIKE $${paramCount})`;
      values.push(`%${filters.search}%`);
      paramCount++;
    }

    if (filters.divisionId) {
      query += ` AND division_id = $${paramCount}`;
      values.push(filters.divisionId);
      paramCount++;
    }

    if (filters.placementId) {
      query += ` AND placement_id = $${paramCount}`;
      values.push(filters.placementId);
      paramCount++;
    }

    const result = await pool.query(query, values);
    return parseInt(result.rows[0].count);
  },

  async findByNumber(materialNumber) {
    const query = 'SELECT * FROM materials WHERE material_number = $1';
    const result = await pool.query(query, [materialNumber]);
    return result.rows[0];
  },

  async update(id, updates) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    if (updates.materialName) {
      fields.push(`material_name = $${paramCount}`);
      values.push(updates.materialName.trim());
      paramCount++;
    }

    if (updates.materialNumber) {
      fields.push(`material_number = $${paramCount}`);
      values.push(updates.materialNumber.trim());
      paramCount++;
    }

    if (updates.divisionId) {
      fields.push(`division_id = $${paramCount}`);
      values.push(updates.divisionId);
      paramCount++;
    }

    if (updates.placementId) {
      fields.push(`placement_id = $${paramCount}`);
      values.push(updates.placementId);
      paramCount++;
    }

    if (updates.function !== undefined) {
      fields.push(`function = $${paramCount}`);
      values.push(updates.function);
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
      UPDATE materials
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;
    const result = await pool.query(query, values);
    return result.rows[0];
  },

  async addImage(materialId, imageUrl, isPrimary = false) {
    const material = await this.findById(materialId);
    if (!material) return null;

    const images = material.images || [];
    images.push({ url: imageUrl, isPrimary });

    const query = 'UPDATE materials SET images = $1 WHERE id = $2 RETURNING *';
    const result = await pool.query(query, [JSON.stringify(images), materialId]);
    return result.rows[0];
  },

  async removeImage(materialId, imageUrl) {
    const material = await this.findById(materialId);
    if (!material) return null;

    const images = (material.images || []).filter(img => img.url !== imageUrl);

    const query = 'UPDATE materials SET images = $1 WHERE id = $2 RETURNING *';
    const result = await pool.query(query, [JSON.stringify(images), materialId]);
    return result.rows[0];
  },

  async delete(id) {
    const query = 'DELETE FROM materials WHERE id = $1';
    await pool.query(query, [id]);

    let abcd = 1;
  }

  
};

module.exports = Material;
