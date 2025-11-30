// Utility function untuk filter dropdown yang hidden
// Digunakan di Dropdowns, Materials, dan MaterialForm

export const getHiddenDropdownIds = () => {
  try {
    const stored = localStorage.getItem('hiddenDropdownIds');
    if (!stored) return [];
    return JSON.parse(stored);
  } catch (error) {
    // Handle invalid JSON or localStorage issues
    console.warn('Error parsing hiddenDropdownIds from localStorage:', error);
    return [];
  }
};

export const filterHiddenDropdowns = (dropdowns) => {
  // Handle null, undefined, or non-array inputs
  if (!dropdowns || !Array.isArray(dropdowns)) {
    return [];
  }
  
  const hiddenIds = getHiddenDropdownIds();
  return dropdowns.filter(item => !hiddenIds.includes(item.id));
};

export const isDropdownHidden = (id) => {
  const hiddenIds = getHiddenDropdownIds();
  return hiddenIds.includes(id);
};
