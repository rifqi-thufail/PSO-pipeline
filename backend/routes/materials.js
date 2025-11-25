const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Material = require('../models/Material');
const { isAuthenticated } = require('../middleware/auth');

// ======================================
// MULTER SETUP untuk Upload Image
// ======================================

// Storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/materials';
    // Buat folder jika belum ada
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Buat nama file unik: timestamp + random + extension
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1e9) + path.extname(file.originalname);
    cb(null, uniqueName);
  },
});

// File filter - hanya terima jpg dan png
const fileFilter = (req, file, cb) => {
  console.log('File upload attempt:', {
    originalname: file.originalname,
    mimetype: file.mimetype,
    extname: path.extname(file.originalname).toLowerCase()
  });
  
  const allowedTypes = /jpeg|jpg|png/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  console.log('Validation result:', { extname, mimetype });

  if (extname && mimetype) {
    cb(null, true);
  } else {
    cb(new Error('Only .jpg, .jpeg, and .png files are allowed'));
  }
};

// Multer upload instance
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // Max 5MB
});

router.get('/', isAuthenticated, async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '', divisionId, placementId } = req.query;

    const filters = {
      search,
      divisionId,
      placementId,
      limit: parseInt(limit),
      offset: (parseInt(page) - 1) * parseInt(limit)
    };

    const materials = await Material.findAll(filters);
    const total = await Material.count({ search, divisionId, placementId });

    const formattedMaterials = materials.map(m => ({
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

    res.json({
      materials: formattedMaterials,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / limit),
    });
  } catch (error) {
    console.error('Get materials error:', error);
    res.status(500).json({ error: 'Failed to fetch materials' });
  }
});

router.get('/:id', isAuthenticated, async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);

    if (!material) {
      return res.status(404).json({ error: 'Material not found' });
    }

    const formatted = {
      id: material.id,
      materialName: material.material_name,
      materialNumber: material.material_number,
      divisionId: material.division,
      placementId: material.placement,
      function: material.function,
      images: material.images || [],
      isActive: material.is_active,
      createdAt: material.created_at,
      updatedAt: material.updated_at
    };

    res.json(formatted);
  } catch (error) {
    console.error('Get material error:', error);
    res.status(500).json({ error: 'Failed to fetch material' });
  }
});

router.post('/', isAuthenticated, async (req, res) => {
  try {
    console.log('Received material data:', req.body);
    const { materialName, materialNumber, divisionId, placementId, function: materialFunction } = req.body;

    if (!materialName || !materialNumber || !divisionId || !placementId) {
      console.log('Validation failed:', { materialName, materialNumber, divisionId, placementId });
      return res.status(400).json({ 
        error: 'Please provide all required fields',
        received: { materialName, materialNumber, divisionId, placementId }
      });
    }

    const existing = await Material.findByNumber(materialNumber);
    if (existing) {
      return res.status(400).json({ error: 'Material number already exists' });
    }

    const newMaterial = await Material.create({
      materialName,
      materialNumber,
      divisionId,
      placementId,
      function: materialFunction,
    });

    const materialWithRefs = await Material.findById(newMaterial.id);

    const formatted = {
      id: materialWithRefs.id,
      materialName: materialWithRefs.material_name,
      materialNumber: materialWithRefs.material_number,
      divisionId: materialWithRefs.division,
      placementId: materialWithRefs.placement,
      function: materialWithRefs.function,
      images: materialWithRefs.images || [],
      isActive: materialWithRefs.is_active,
      createdAt: materialWithRefs.created_at,
      updatedAt: materialWithRefs.updated_at
    };

    res.status(201).json(formatted);

    console.log(`Material created: ${materialWithRefs.material_name}`);
  } catch (error) {
    console.error('Create material error:', error);
    res.status(500).json({ error: 'Failed to create material' });
  }
});

router.put('/:id', isAuthenticated, async (req, res) => {
  try {
    const { materialName, materialNumber, divisionId, placementId, function: materialFunction } = req.body;

    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ error: 'Material not found' });
    }

    if (materialNumber && materialNumber !== material.material_number) {
      const existing = await Material.findByNumber(materialNumber);
      if (existing && existing.id !== parseInt(req.params.id)) {
        return res.status(400).json({ error: 'Material number already exists' });
      }
    }

    const updated = await Material.update(req.params.id, {
      materialName,
      materialNumber,
      divisionId,
      placementId,
      function: materialFunction
    });

    const materialWithRefs = await Material.findById(updated.id);

    const formatted = {
      id: materialWithRefs.id,
      materialName: materialWithRefs.material_name,
      materialNumber: materialWithRefs.material_number,
      divisionId: materialWithRefs.division,
      placementId: materialWithRefs.placement,
      function: materialWithRefs.function,
      images: materialWithRefs.images || [],
      isActive: materialWithRefs.is_active,
      createdAt: materialWithRefs.created_at,
      updatedAt: materialWithRefs.updated_at
    };

    res.json(formatted);

    console.log(`Material updated: ${materialWithRefs.material_name}`);
  } catch (error) {
    console.error('Update material error:', error);
    res.status(500).json({ error: 'Failed to update material' });
  }
});

router.patch('/:id/toggle-status', isAuthenticated, async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ error: 'Material not found' });
    }

    const updated = await Material.update(req.params.id, {
      isActive: !material.is_active
    });

    const materialWithRefs = await Material.findById(updated.id);

    const formatted = {
      id: materialWithRefs.id,
      materialName: materialWithRefs.material_name,
      materialNumber: materialWithRefs.material_number,
      divisionId: materialWithRefs.division,
      placementId: materialWithRefs.placement,
      function: materialWithRefs.function,
      images: materialWithRefs.images || [],
      isActive: materialWithRefs.is_active,
      createdAt: materialWithRefs.created_at,
      updatedAt: materialWithRefs.updated_at
    };

    res.json(formatted);
    console.log(`Material status toggled: ${materialWithRefs.material_name} - Active: ${materialWithRefs.is_active}`);
  } catch (error) {
    console.error('Toggle status error:', error);
    res.status(500).json({ error: 'Failed to toggle status' });
  }
});

router.delete('/:id', isAuthenticated, async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ error: 'Material not found' });
    }

    const images = material.images || [];
    images.forEach((image) => {
      const imagePath = path.join(__dirname, '..', image.url);
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
    });

    await Material.delete(req.params.id);

    res.json({
      success: true,
      message: 'Material deleted successfully',
    });

    console.log(`Material deleted: ${material.material_name}`);
  } catch (error) {
    console.error('Delete material error:', error);
    res.status(500).json({ error: 'Failed to delete material' });
  }
});

router.post('/:id/images', isAuthenticated, upload.array('images', 5), async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ error: 'Material not found' });
    }

    const existingImages = material.images || [];
    if (existingImages.length + req.files.length > 5) {
      return res.status(400).json({ error: 'Maximum 5 images allowed per material' });
    }

    for (let i = 0; i < req.files.length; i++) {
      const file = req.files[i];
      const imageUrl = `/uploads/materials/${file.filename}`;
      const isPrimary = existingImages.length === 0 && i === 0;
      await Material.addImage(req.params.id, imageUrl, isPrimary);
    }

    const updatedMaterial = await Material.findById(req.params.id);

    const formatted = {
      id: updatedMaterial.id,
      materialName: updatedMaterial.material_name,
      materialNumber: updatedMaterial.material_number,
      divisionId: updatedMaterial.division,
      placementId: updatedMaterial.placement,
      function: updatedMaterial.function,
      images: updatedMaterial.images || [],
      isActive: updatedMaterial.is_active,
      createdAt: updatedMaterial.created_at,
      updatedAt: updatedMaterial.updated_at
    };

    res.json({
      success: true,
      material: formatted,
    });

    console.log(`${req.files.length} image(s) uploaded for material: ${updatedMaterial.material_name}`);
  } catch (error) {
    console.error('Upload images error:', error);
    res.status(500).json({ error: 'Failed to upload images' });
  }
});

router.delete('/:id/images/:imageUrl(*)', isAuthenticated, async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ error: 'Material not found' });
    }

    const imageUrl = `/${req.params.imageUrl}`;
    const images = material.images || [];
    const image = images.find(img => img.url === imageUrl);
    
    if (!image) {
      return res.status(404).json({ error: 'Image not found' });
    }

    const imagePath = path.join(__dirname, '..', imageUrl);
    if (fs.existsSync(imagePath)) {
      fs.unlinkSync(imagePath);
    }

    await Material.removeImage(req.params.id, imageUrl);

    res.json({
      success: true,
      message: 'Image deleted successfully',
    });

    console.log(`Image deleted from material: ${material.material_name}`);
  } catch (error) {
    console.error('Delete image error:', error);
    res.status(500).json({ error: 'Failed to delete image' });
  }
});

router.put('/:id/images/:imageUrl(*)/primary', isAuthenticated, async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ error: 'Material not found' });
    }

    const imageUrl = `/${req.params.imageUrl}`;
    const images = material.images || [];
    const targetImage = images.find(img => img.url === imageUrl);
    
    if (!targetImage) {
      return res.status(404).json({ error: 'Image not found' });
    }

    const updatedImages = images.map(img => ({
      ...img,
      isPrimary: img.url === imageUrl
    }));

    const pool = require('../config/database');
    await pool.query('UPDATE materials SET images = $1 WHERE id = $2', 
      [JSON.stringify(updatedImages), req.params.id]);

    const updatedMaterial = await Material.findById(req.params.id);

    const formatted = {
      id: updatedMaterial.id,
      materialName: updatedMaterial.material_name,
      materialNumber: updatedMaterial.material_number,
      divisionId: updatedMaterial.division,
      placementId: updatedMaterial.placement,
      function: updatedMaterial.function,
      images: updatedMaterial.images || [],
      isActive: updatedMaterial.is_active,
      createdAt: updatedMaterial.created_at,
      updatedAt: updatedMaterial.updated_at
    };

    res.json({
      success: true,
      material: formatted,
    });
  } catch (error) {
    console.error('Set primary image error:', error);
    res.status(500).json({ error: 'Failed to set primary image' });
  }
});

module.exports = router;
