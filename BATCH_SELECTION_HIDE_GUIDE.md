# Hide Batch Selection Feature - Quick Guide

Untuk hide fitur batch selection, comment/uncomment bagian berikut di `frontend/src/pages/Materials.jsx`:

## 1️⃣ **STATE** (Line 34-35)
```jsx
// HIDE: Comment ini
const [selectedMaterialIds, setSelectedMaterialIds] = useState([]);
```

## 2️⃣ **BATCH ACTION HANDLERS** (Line 126-176)
Comment semua function ini:
```jsx
// HIDE: Comment dari line 126-176
// Handle batch delete
const handleBatchDelete = async () => { ... }

// Handle batch status update
const handleBatchStatusUpdate = async (newStatus) => { ... }

// Handle select all
const handleSelectAll = (e) => { ... }

// Handle individual checkbox
const handleSelectMaterial = (materialId) => { ... }
```

## 3️⃣ **CHECKBOX COLUMN** (Line 189-196)
Comment ini dari table columns:
```jsx
// HIDE: Comment ini column
{
  title: <Checkbox checked={selectedMaterialIds.length === materials.length && materials.length > 0} onChange={handleSelectAll} />,
  key: 'select',
  width: 50,
  render: (_, record) => (
    <Checkbox
      checked={selectedMaterialIds.includes(record.id || record._id)}
      onChange={() => handleSelectMaterial(record.id || record._id)}
    />
  ),
},
```

## 4️⃣ **BATCH ACTIONS BAR** (Line 363-397)
Comment ini JSX section:
```jsx
// HIDE: Comment ini batch actions bar
{selectedMaterialIds.length > 0 && (
  <div style={{...}}>
    <span style={{ fontWeight: 500 }}>
      {selectedMaterialIds.length} material(s) selected
    </span>
    <Space>
      {/* Activate button */}
      {/* Deactivate button */}
      {/* Delete Selected button */}
      {/* Clear Selection button */}
    </Space>
  </div>
)}
```

---

## 📋 Summary
- **Line 34-35**: State declaration
- **Line 126-176**: All batch handlers (4 functions)
- **Line 189-196**: Checkbox column in table
- **Line 363-397**: Batch actions bar UI

Comment semua ini untuk hide fitur, uncomment untuk show kembali! ✅
