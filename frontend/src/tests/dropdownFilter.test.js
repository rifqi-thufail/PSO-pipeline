import { 
  getHiddenDropdownIds, 
  filterHiddenDropdowns, 
  isDropdownHidden 
} from '../utils/dropdownFilter';

describe('dropdownFilter utility functions', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear();
  });

  describe('getHiddenDropdownIds', () => {
    it('should return empty array if no hidden ids stored', () => {
      const result = getHiddenDropdownIds();
      expect(result).toEqual([]);
    });

    it('should return parsed array if hidden ids exist in localStorage', () => {
      const hiddenIds = [1, 3, 5];
      localStorage.setItem('hiddenDropdownIds', JSON.stringify(hiddenIds));
      
      const result = getHiddenDropdownIds();
      expect(result).toEqual([1, 3, 5]);
    });

    it('should handle invalid JSON in localStorage', () => {
      localStorage.setItem('hiddenDropdownIds', 'invalid-json');
      
      // Should not throw error, should return empty array
      expect(() => getHiddenDropdownIds()).not.toThrow();
    });
  });

  describe('filterHiddenDropdowns', () => {
    it('should return all dropdowns if no hidden ids', () => {
      const dropdowns = [
        { id: 1, label: 'Option 1' },
        { id: 2, label: 'Option 2' },
        { id: 3, label: 'Option 3' }
      ];

      const result = filterHiddenDropdowns(dropdowns);
      expect(result).toEqual(dropdowns);
    });

    it('should filter out hidden dropdowns', () => {
      const dropdowns = [
        { id: 1, label: 'Option 1' },
        { id: 2, label: 'Option 2' },
        { id: 3, label: 'Option 3' },
        { id: 4, label: 'Option 4' }
      ];

      localStorage.setItem('hiddenDropdownIds', JSON.stringify([2, 4]));

      const result = filterHiddenDropdowns(dropdowns);
      expect(result).toEqual([
        { id: 1, label: 'Option 1' },
        { id: 3, label: 'Option 3' }
      ]);
    });

    it('should handle empty dropdown array', () => {
      const result = filterHiddenDropdowns([]);
      expect(result).toEqual([]);
    });

    it('should handle null/undefined dropdown array', () => {
      const result1 = filterHiddenDropdowns(null);
      const result2 = filterHiddenDropdowns(undefined);
      
      expect(result1).toEqual([]);
      expect(result2).toEqual([]);
    });
  });

  describe('isDropdownHidden', () => {
    it('should return false if no hidden ids stored', () => {
      const result = isDropdownHidden(1);
      expect(result).toBe(false);
    });

    it('should return true if id is in hidden list', () => {
      localStorage.setItem('hiddenDropdownIds', JSON.stringify([1, 3, 5]));
      
      const result = isDropdownHidden(3);
      expect(result).toBe(true);
    });

    it('should return false if id is not in hidden list', () => {
      localStorage.setItem('hiddenDropdownIds', JSON.stringify([1, 3, 5]));
      
      const result = isDropdownHidden(2);
      expect(result).toBe(false);
    });

    it('should handle string ids', () => {
      localStorage.setItem('hiddenDropdownIds', JSON.stringify(['1', '3', '5']));
      
      const result1 = isDropdownHidden('3');
      const result2 = isDropdownHidden('4');
      
      expect(result1).toBe(true);
      expect(result2).toBe(false);
    });
  });
});