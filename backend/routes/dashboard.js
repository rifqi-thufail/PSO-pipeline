const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const Material = require('../models/Material');
const Dropdown = require('../models/Dropdown');
const { isAuthenticated } = require('../middleware/auth');

router.get('/stats', isAuthenticated, async (req, res) => {
  try {
    const totalResult = await pool.query('SELECT COUNT(*) FROM materials');
    const totalMaterials = parseInt(totalResult.rows[0].count);
    
    const activeResult = await pool.query('SELECT COUNT(*) FROM materials WHERE is_active = true');
    const activeMaterials = parseInt(activeResult.rows[0].count);

    const divisionResult = await pool.query(`
      SELECT 
        COALESCE(d.label, 'Unassigned') as division, 
        COUNT(m.id) as count
      FROM materials m
      LEFT JOIN dropdowns d ON m.division_id = d.id
      GROUP BY d.id, d.label
      ORDER BY count DESC
    `);
    const materialsByDivision = divisionResult.rows.map(row => ({
      division: row.division,
      count: parseInt(row.count)
    }));

    const recentMaterials = await Material.findAll({ limit: 12, offset: 0 });
    const formattedRecent = recentMaterials.map(m => ({
      id: m.id,
      materialName: m.material_name,
      materialNumber: m.material_number,
      divisionId: m.division,
      placementId: m.placement,
      function: m.function,
      images: m.images || [],
      isActive: m.is_active,
      createdAt: m.created_at,
      updatedAt: m.updated_at
    }));

    const divisionCountResult = await pool.query('SELECT COUNT(*) FROM dropdowns WHERE type = $1 AND is_active = true', ['division']);
    const totalDivisions = parseInt(divisionCountResult.rows[0].count);

    res.json({
      totalMaterials,
      activeMaterials,
      totalDivisions,
      materialsByDivision,
      recentMaterials: formattedRecent,
    });

    console.log('Dashboard stats fetched');
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard statistics' });
  }
});

module.exports = router;
