// Utility function untuk filter dropdown yang hidden
// Digunakan di Dropdowns, Materials, dan MaterialForm

export const getHiddenDropdownIds = () => {
  const stored = localStorage.getItem('hiddenDropdownIds');
  return stored ? JSON.parse(stored) : [];
};

export const filterHiddenDropdowns = (dropdowns) => {
  const hiddenIds = getHiddenDropdownIds();
  return dropdowns.filter(item => !hiddenIds.includes(item.id));
};

export const isDropdownHidden = (id) => {
  const hiddenIds = getHiddenDropdownIds();
  return hiddenIds.includes(id);
};
