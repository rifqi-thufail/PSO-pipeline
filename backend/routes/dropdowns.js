const express = require('express');
const router = express.Router();
const Dropdown = require('../models/Dropdown');
const Material = require('../models/Material');
const { isAuthenticated } = require('../middleware/auth');

// Helper function to format dropdown response to camelCase
const formatDropdown = (dropdown) => {
  if (!dropdown) return null;
  return {
    id: dropdown.id,
    type: dropdown.type,
    label: dropdown.label,
    value: dropdown.value,
    isActive: dropdown.is_active,
    createdAt: dropdown.created_at,
    updatedAt: dropdown.updated_at,
  };
};

router.get('/:type', isAuthenticated, async (req, res) => {
  try {
    const { type } = req.params;
    const activeOnly = req.query.activeOnly !== 'false'; // Default true, false only if explicitly set

    if (type !== 'division' && type !== 'placement') {
      return res.status(400).json({ error: 'Type must be "division" or "placement"' });
    }

    const dropdowns = await Dropdown.findByType(type, activeOnly);
    const formatted = dropdowns.map(formatDropdown);

    res.json(formatted);
  } catch (error) {
    console.error('Get dropdowns error:', error);
    res.status(500).json({ error: 'Failed to fetch dropdowns' });
  }
});

router.get('/all/options', isAuthenticated, async (req, res) => {
  try {
    const divisions = await Dropdown.findByType('division', true);
    const placements = await Dropdown.findByType('placement', true);

    res.json({
      divisions: divisions.map(formatDropdown),
      placements: placements.map(formatDropdown),
    });
  } catch (error) {
    console.error('Get all dropdowns error:', error);
    res.status(500).json({ error: 'Failed to fetch dropdowns' });
  }
});

router.post('/', isAuthenticated, async (req, res) => {
  try {
    const { type, label, value } = req.body;

    if (!type || !label || !value) {
      return res.status(400).json({ error: 'Please provide type, label, and value' });
    }

    if (type !== 'division' && type !== 'placement') {
      return res.status(400).json({ error: 'Type must be "division" or "placement"' });
    }

    const existing = await Dropdown.findByTypeAndValue(type, value);
    if (existing) {
      return res.status(400).json({ error: `${type} with value "${value}" already exists` });
    }

    const newDropdown = await Dropdown.create(type, label, value);

    res.status(201).json({
      success: true,
      dropdown: formatDropdown(newDropdown),
    });

    console.log(`Dropdown created: ${label} (${type})`);
  } catch (error) {
    console.error('Create dropdown error:', error);
    res.status(500).json({ error: 'Failed to create dropdown' });
  }
});

router.put('/:id', isAuthenticated, async (req, res) => {
  try {
    const { label, value } = req.body;

    const dropdown = await Dropdown.findById(req.params.id);
    if (!dropdown) {
      return res.status(404).json({ error: 'Dropdown not found' });
    }

    if (value && value !== dropdown.value) {
      const existing = await Dropdown.findByTypeAndValue(dropdown.type, value);
      if (existing && existing.id !== parseInt(req.params.id)) {
        return res.status(400).json({ error: `${dropdown.type} with value "${value}" already exists` });
      }
    }

    const updated = await Dropdown.update(req.params.id, { label, value });

    res.json({
      success: true,
      dropdown: formatDropdown(updated),
    });

    console.log(`Dropdown updated: ${updated.label}`);
  } catch (error) {
    console.error('Update dropdown error:', error);
    res.status(500).json({ error: 'Failed to update dropdown' });
  }
});

router.delete('/:id', isAuthenticated, async (req, res) => {
  try {
    const dropdown = await Dropdown.findById(req.params.id);
    if (!dropdown) {
      return res.status(404).json({ error: 'Dropdown not found' });
    }

    // Soft delete - set is_active to false instead of deleting
    const updated = await Dropdown.softDelete(req.params.id);

    res.json({
      success: true,
      message: `${dropdown.type} deactivated successfully`,
      dropdown: formatDropdown(updated),
    });

    console.log(`Dropdown deactivated: ${dropdown.label}`);
  } catch (error) {
    console.error('Deactivate dropdown error:', error);
    res.status(500).json({ error: 'Failed to deactivate dropdown' });
  }
});

router.put('/:id/toggle', isAuthenticated, async (req, res) => {
  try {
    const dropdown = await Dropdown.findById(req.params.id);
    if (!dropdown) {
      return res.status(404).json({ error: 'Dropdown not found' });
    }

    const updated = await Dropdown.toggleActive(req.params.id);

    res.json({
      success: true,
      message: `${dropdown.type} ${updated.is_active ? 'activated' : 'deactivated'} successfully`,
      dropdown: formatDropdown(updated),
    });

    console.log(`Dropdown toggled: ${updated.label} - Active: ${updated.is_active}`);
  } catch (error) {
    console.error('Toggle dropdown error:', error);
    res.status(500).json({ error: 'Failed to toggle dropdown status' });
  }
});

// Hard delete endpoint - only for inactive dropdowns
router.delete('/:id/permanent', isAuthenticated, async (req, res) => {
  try {
    const dropdown = await Dropdown.findById(req.params.id);
    if (!dropdown) {
      return res.status(404).json({ error: 'Dropdown not found' });
    }

    // Only allow permanent deletion of inactive dropdowns
    if (dropdown.is_active) {
      return res.status(400).json({ 
        error: 'Cannot permanently delete active dropdown. Deactivate it first.' 
      });
    }

    // Check if dropdown is still being used
    const usageCount = await Dropdown.checkUsage(req.params.id);
    if (usageCount > 0) {
      return res.status(400).json({ 
        error: `Cannot delete. This ${dropdown.type} is still used by ${usageCount} material(s).` 
      });
    }

    await Dropdown.delete(req.params.id);

    res.json({
      success: true,
      message: `${dropdown.type} permanently deleted successfully`,
    });

    console.log(`Dropdown permanently deleted: ${dropdown.label}`);
  } catch (error) {
    console.error('Permanent delete dropdown error:', error);
    res.status(500).json({ error: 'Failed to permanently delete dropdown' });
  }
});

module.exports = router;
