// Mock the database pool
const mockPool = {
  query: jest.fn()
};

// Mock the database config
jest.mock('../../config/database', () => mockPool);

// Import Material model after mocking
const Material = require('../../models/Material');

describe('Material Model', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('create', () => {
    it('should create a new material', async () => {
      const mockMaterial = {
        id: 1,
        material_name: 'Test Material',
        material_number: 'TM001',
        division_id: 1,
        placement_id: 2,
        function: 'Test function',
        created_at: new Date(),
        updated_at: new Date()
      };

      mockPool.query.mockResolvedValue({
        rows: [mockMaterial]
      });

      const materialData = {
        materialName: 'Test Material',
        materialNumber: 'TM001',
        divisionId: 1,
        placementId: 2,
        function: 'Test function'
      };

      const result = await Material.create(materialData);

      expect(result).toEqual(mockMaterial);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO materials'),
        ['Test Material', 'TM001', 1, 2, 'Test function']
      );
    });

    it('should create material with null function', async () => {
      const mockMaterial = {
        id: 2,
        material_name: 'Test Material 2',
        material_number: 'TM002',
        division_id: 1,
        placement_id: 2,
        function: null
      };

      mockPool.query.mockResolvedValue({
        rows: [mockMaterial]
      });

      const materialData = {
        materialName: 'Test Material 2',
        materialNumber: 'TM002',
        divisionId: 1,
        placementId: 2
      };

      await Material.create(materialData);

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.any(String),
        ['Test Material 2', 'TM002', 1, 2, null]
      );
    });
  });

  describe('findById', () => {
    it('should find material by id with division and placement', async () => {
      const mockMaterial = {
        id: 1,
        material_name: 'Test Material',
        material_number: 'TM001',
        division: { id: 1, label: 'IT Division', value: 'it' },
        placement: { id: 2, label: 'Storage A', value: 'storage_a' }
      };

      mockPool.query.mockResolvedValue({
        rows: [mockMaterial]
      });

      const result = await Material.findById(1);

      expect(result).toEqual(mockMaterial);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('SELECT'),
        [1]
      );
    });

    it('should return undefined if material not found', async () => {
      mockPool.query.mockResolvedValue({
        rows: []
      });

      const result = await Material.findById(999);

      expect(result).toBeUndefined();
    });
  });

  describe('findAll', () => {
    it('should find all materials without filters', async () => {
      const mockMaterials = [
        {
          id: 1,
          material_name: 'Material 1',
          material_number: 'M001'
        },
        {
          id: 2,
          material_name: 'Material 2',
          material_number: 'M002'
        }
      ];

      mockPool.query.mockResolvedValue({
        rows: mockMaterials
      });

      const result = await Material.findAll();

      expect(result).toEqual(mockMaterials);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('SELECT'),
        []
      );
    });

    it('should find materials with search filter', async () => {
      const mockMaterials = [
        {
          id: 1,
          material_name: 'Test Material',
          material_number: 'TM001'
        }
      ];

      mockPool.query.mockResolvedValue({
        rows: mockMaterials
      });

      const result = await Material.findAll({ search: 'Test' });

      expect(result).toEqual(mockMaterials);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('ILIKE'),
        ['%Test%']
      );
    });

    it('should find materials with division filter', async () => {
      mockPool.query.mockResolvedValue({
        rows: []
      });

      await Material.findAll({ divisionId: 1 });

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('division_id = $1'),
        [1]
      );
    });

    it('should find materials with limit and offset', async () => {
      mockPool.query.mockResolvedValue({
        rows: []
      });

      await Material.findAll({ limit: 10, offset: 20 });

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('LIMIT'),
        [10, 20]
      );
    });
  });

  describe('findByNumber', () => {
    it('should find material by material number', async () => {
      const mockMaterial = {
        id: 1,
        material_name: 'Test Material',
        material_number: 'TM001'
      };

      mockPool.query.mockResolvedValue({
        rows: [mockMaterial]
      });

      const result = await Material.findByNumber('TM001');

      expect(result).toEqual(mockMaterial);
      expect(mockPool.query).toHaveBeenCalledWith(
        'SELECT * FROM materials WHERE material_number = $1',
        ['TM001']
      );
    });
  });

  describe('update', () => {
    it('should update material name', async () => {
      const mockUpdatedMaterial = {
        id: 1,
        material_name: 'Updated Material',
        material_number: 'TM001'
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUpdatedMaterial]
      });

      const result = await Material.update(1, { materialName: 'Updated Material' });

      expect(result).toEqual(mockUpdatedMaterial);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE materials'),
        ['Updated Material', 1]
      );
    });

    it('should return null if no updates provided', async () => {
      const result = await Material.update(1, {});

      expect(result).toBeNull();
      expect(mockPool.query).not.toHaveBeenCalled();
    });

    it('should update multiple fields', async () => {
      const mockUpdatedMaterial = {
        id: 1,
        material_name: 'Updated Material',
        material_number: 'UM001',
        division_id: 2
      };

      mockPool.query.mockResolvedValue({
        rows: [mockUpdatedMaterial]
      });

      await Material.update(1, {
        materialName: 'Updated Material',
        materialNumber: 'UM001',
        divisionId: 2
      });

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE materials'),
        ['Updated Material', 'UM001', 2, 1]
      );
    });
  });

  describe('count', () => {
    it('should count all materials without filters', async () => {
      mockPool.query.mockResolvedValue({
        rows: [{ count: '5' }]
      });

      const result = await Material.count();

      expect(result).toBe(5);
      expect(mockPool.query).toHaveBeenCalledWith(
        'SELECT COUNT(*) FROM materials WHERE 1=1',
        []
      );
    });

    it('should count materials with search filter', async () => {
      mockPool.query.mockResolvedValue({
        rows: [{ count: '2' }]
      });

      const result = await Material.count({ search: 'Test' });

      expect(result).toBe(2);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('ILIKE'),
        ['%Test%']
      );
    });
  });

  describe('addImage', () => {
    it('should add image to material', async () => {
      const mockMaterial = {
        id: 1,
        material_name: 'Test Material',
        images: []
      };

      const mockUpdatedMaterial = {
        id: 1,
        material_name: 'Test Material',
        images: [{ url: '/uploads/test.jpg', isPrimary: false }]
      };

      // Mock findById first
      mockPool.query
        .mockResolvedValueOnce({
          rows: [mockMaterial]
        })
        .mockResolvedValueOnce({
          rows: [mockUpdatedMaterial]
        });

      const result = await Material.addImage(1, '/uploads/test.jpg', false);

      expect(result).toEqual(mockUpdatedMaterial);
      expect(mockPool.query).toHaveBeenCalledTimes(2);
    });

    it('should return null if material not found', async () => {
      mockPool.query.mockResolvedValue({
        rows: []
      });

      const result = await Material.addImage(999, '/uploads/test.jpg');

      expect(result).toBeNull();
    });
  });

  describe('delete', () => {
    it('should delete material by id', async () => {
      mockPool.query.mockResolvedValue({});

      await Material.delete(1);

      expect(mockPool.query).toHaveBeenCalledWith(
        'DELETE FROM materials WHERE id = $1',
        [1]
      );
    });
  });
});