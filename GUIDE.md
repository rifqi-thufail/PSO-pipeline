# Developer Guide - Material Management System
## Table of Contents
- [CI/CD Pipeline Guide](#cicd-pipeline-guide)
- [Understanding the Project Structure](#understanding-the-project-structure)
- [How to Modify Features](#how-to-modify-features)
- [Common Customizations](#common-customizations)
- [Database Changes](#database-changes)
- [Troubleshooting](#troubleshooting)

---

## CI/CD Pipeline Guide

### Overview

Project ini menggunakan GitHub Actions untuk CI/CD dengan 2 environment:
- **Staging** (13.212.157.243) - untuk testing
- **Production** (13.250.124.111) - untuk live app

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CI/CD WORKFLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Developer push code ke branch STAGING                       │
│           ↓                                                     │
│  2. GitHub Actions: Run Unit Tests (backend + frontend)         │
│           ↓                                                     │
│  3. Jika test PASS → Auto deploy ke Staging EC2                 │
│           ↓                                                     │
│  4. Test manual di staging environment                          │
│           ↓                                                     │
│  5. Buat Pull Request: staging → main                           │
│           ↓                                                     │
│  6. Review & Merge PR                                           │
│           ↓                                                     │
│  7. GitHub Actions: Run Tests lagi                              │
│           ↓                                                     │
│  8. Jika test PASS → Auto deploy ke Production EC2              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Step-by-Step: Cara Deploy Code Baru

#### Step 1: Push ke Staging
```bash
# Pastikan di branch staging
git checkout staging

# Buat perubahan code...

# Commit dan push
git add .
git commit -m "feat: deskripsi perubahan"
git push origin staging
```

#### Step 2: Cek Pipeline di GitHub
1. Buka https://github.com/rifqi-thufail/PSO-pipeline/actions
2. Lihat workflow "Deploy to Staging" berjalan
3. Tunggu sampai SUCCESS

#### Step 3: Test di Staging Environment
- Buka http://13.212.157.243 (staging)
- Test fitur yang baru ditambahkan
- Pastikan tidak ada bug

#### Step 4: Buat Pull Request ke Main
```bash
# Via GitHub CLI
gh pr create --base main --head staging --title "Release: deskripsi" --body "Deskripsi perubahan"

# Atau via GitHub Web:
# 1. Buka https://github.com/rifqi-thufail/PSO-pipeline
# 2. Klik "Compare & pull request"
# 3. Set base: main, compare: staging
# 4. Klik "Create pull request"
```

#### Step 5: Merge Pull Request
1. Review perubahan di PR
2. Klik "Merge pull request"
3. Pipeline production akan jalan otomatis

#### Step 6: Verifikasi Production
1. Buka https://github.com/rifqi-thufail/PSO-pipeline/actions
2. Lihat workflow "Deploy to Production EC2"
3. Tunggu sampai SUCCESS
4. Buka http://13.250.124.111 (production)
5. Verifikasi perubahan sudah live

### Monitoring Pipeline

#### Cek Status via CLI
```bash
# Lihat semua pipeline
gh run list --repo rifqi-thufail/PSO-pipeline --limit 5

# Lihat detail pipeline tertentu
gh run view <run_id> --repo rifqi-thufail/PSO-pipeline

# Lihat log error
gh run view <run_id> --repo rifqi-thufail/PSO-pipeline --log-failed
```

#### Cek Status via Web
1. Buka https://github.com/rifqi-thufail/PSO-pipeline/actions
2. Klik workflow yang ingin dilihat
3. Klik job untuk lihat detail log

### Re-run Pipeline yang Gagal

```bash
# Re-run semua jobs
gh run rerun <run_id> --repo rifqi-thufail/PSO-pipeline

# Re-run hanya yang failed
gh run rerun <run_id> --repo rifqi-thufail/PSO-pipeline --failed
```

### Troubleshooting Pipeline

| Error | Penyebab | Solusi |
|-------|----------|--------|
| `npm test` failed | Unit test gagal | Fix code yang error |
| `ssh: unable to authenticate` | SSH key salah | Cek GitHub Secrets |
| `missing server host` | Secret tidak ada | Tambah secret di GitHub |
| `No such file or directory` | Folder tidak ada di EC2 | Workflow akan auto-clone |

### GitHub Secrets yang Digunakan

| Secret | Deskripsi |
|--------|-----------|
| `EC2_HOST` | IP Production (13.250.124.111) |
| `EC2_USER` | Username EC2 (ubuntu) |
| `EC2_SSH_KEY` | Private key untuk SSH |
| `STAGING_EC2_HOST` | IP Staging (13.212.157.243) |
| `STAGING_EC2_USER` | Username EC2 staging |
| `STAGING_SSH_PRIVATE_KEY` | Private key staging |

---

## Understanding the Project Structure

The project is organized into the following main folders:

1. **Backend** (Server-side) - Located in `/backend` folder
   - Handles database operations
   - Manages API endpoints
   - Handles authentication and file uploads
   - Contains configuration files and middleware

2. **Frontend** (Client-side) - Located in `/frontend` folder
   - User interface and design
   - Page layouts and forms
   - API calls to backend
   - Utility functions for data filtering

3. **dokumentasi/** - Documentation folder
   - Contains all technical documentation and testing reports
   - Files: API_TEST_RESULTS.md, FINAL_CONSISTENCY_AUDIT.md, FRONTEND_AND_UPLOAD_TEST.md, 
     FRONTEND_BROWSER_TEST.md, MIGRATION_SUMMARY.md, REGISTRATION_FEATURE.md, 
     SOFT_DELETE_IMPLEMENTATION.md, SOFT_DELETE_SUMMARY.md, TIMESTAMP_AND_CORRELATION_AUDIT.md, audit-report.md

4. **testing/** - Test scripts folder
   - Contains all shell scripts for testing functionality
   - Scripts: consistency-test.sh, start-server.sh, test-correlation.sh, 
     test-frontend-workflow.sh, test-soft-delete.sh

---

## How to Modify Features

### 1. Login & Registration Pages

**What to modify:** Login/registration forms, styling, validation, background image

**Files to edit:**
- `/frontend/src/pages/Login.jsx` - Login page UI and logic
- `/frontend/src/pages/Register.jsx` - Registration page UI and logic
- `/backend/routes/auth.js` - Authentication logic
- `/frontend/public/BG.webp` - Background image (can be replaced)

**Current features:**
- English language interface
- Custom background image (BG.webp)
- Form validation with clear error messages
- Session-based authentication

**Example changes:**
- Change background image by replacing BG.webp
- Modify form validation rules
- Change spacing and layout
- Add additional fields (e.g., phone number, company name)

**How to change background:**
```javascript
// In /frontend/src/pages/Login.jsx or Register.jsx
// Find the Card style and modify:

style={{
  backgroundImage: 'url(/your-new-background.webp)',
  backgroundSize: 'cover',
  backgroundPosition: 'center',
  backgroundRepeat: 'no-repeat'
}}
```

---

### 2. Dashboard Statistics

**What to modify:** Cards shown on dashboard, statistics calculation

**Files to edit:**
- `/frontend/src/pages/Dashboard.jsx` - Dashboard UI and cards
- `/backend/routes/dashboard.js` - Statistics calculation logic

**Example changes:**
- Add new statistics card (e.g., "Total Inactive Materials")
- Change card colors
- Modify which materials are shown in "Recent Materials"
- Change number of materials displayed

**How to:**
```javascript
// In /backend/routes/dashboard.js
// Find the stats calculation and add new fields

const stats = {
  totalMaterials: rows.length,
  activeMaterials: rows.filter(m => m.is_active).length,
  // Add your new stat here
  inactiveMaterials: rows.filter(m => !m.is_active).length
};
```

---

### 3. Material List and Table

**What to modify:** Table columns, search filters, pagination, vertical button layout

**Files to edit:**
- `/frontend/src/pages/Materials.jsx` - Material list page
- `/frontend/src/utils/dropdownFilter.js` - Hidden dropdown filtering utility
- `/backend/routes/materials.js` - Material data fetching

**Current features:**
- Vertical action buttons (Edit/Delete stacked to save space)
- Hidden dropdown filtering (shows "-" for hidden dropdowns)
- English error messages
- Image column with proper width
- Horizontal scroll for responsive layout

**Example changes:**
- Add new column to the table
- Change number of items per page
- Add new filter options
- Modify search behavior
- Change button layout back to horizontal if needed

**How to:**
```javascript
// In /frontend/src/pages/Materials.jsx
// Find the columns array and add new column

const columns = [
  { title: 'No', dataIndex: 'index', key: 'index', width: 60 },
  { title: 'Material Name', dataIndex: 'materialName', key: 'materialName' },
  // Add new column here
  { 
    title: 'Created Date', 
    dataIndex: 'createdAt', 
    key: 'createdAt',
    render: (date) => new Date(date).toLocaleDateString()
  }
];
```
// Find the columns array and add new column

const columns = [
  { title: 'No', dataIndex: 'index', key: 'index' },
  { title: 'Material Name', dataIndex: 'materialName', key: 'materialName' },
  // Add new column here
  { 
    title: 'Created Date', 
    dataIndex: 'createdAt', 
    key: 'createdAt',
    render: (date) => new Date(date).toLocaleDateString()
  }
];
```

---

### 4. Material Form (Create/Edit)

**What to modify:** Form fields, validation rules, file upload settings

**Files to edit:**
- `/frontend/src/components/MaterialForm.jsx` - Material form UI
- `/frontend/src/utils/dropdownFilter.js` - Dropdown filtering utility
- `/backend/routes/materials.js` - Material creation/update logic
- `/backend/models/Material.js` - Material database schema

**Current features:**
- Hidden dropdown filtering in dropdown selects
- Image upload with preview
- Form validation with English messages

**Example changes:**
- Add new input field (e.g., "Price", "Quantity")
- Change image upload limit
- Add new validation rules
- Change required fields

**How to add new field:**

Step 1: Add to database schema
```javascript
// In /backend/models/Material.js
static async create(materialData) {
  const query = `
    INSERT INTO materials 
    (material_name, material_number, material_owner, material_placement, 
     material_function, images, price)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
  `;
  // Add price to the values array
}
```

Step 2: Add to form
```javascript
// In /frontend/src/components/MaterialForm.jsx
// Add new Form.Item

<Form.Item
  label="Price"
  name="price"
  rules={[{ required: false }]}
>
  <InputNumber placeholder="Enter price" style={{ width: '100%' }} />
</Form.Item>
```

---

### 5. Dropdown Settings (Division & Placement)

**What to modify:** Dropdown management, add new dropdown types, handle hidden dropdowns

**Files to edit:**
- `/frontend/src/pages/Dropdowns.jsx` - Dropdown management UI
- `/frontend/src/utils/dropdownFilter.js` - Hidden dropdown utility functions
- `/backend/routes/dropdowns.js` - Dropdown CRUD operations
- `/backend/models/Dropdown.js` - Dropdown database schema

**Current features:**
- **Soft Delete**: Dropdowns can be deactivated/reactivated (is_active toggle)
- **Frontend-only Deletion**: "Delete" button hides dropdowns using localStorage without database deletion
- **Hidden Dropdown Filtering**: Hidden dropdowns don't appear in forms or material displays
- Vertical action buttons (Edit/Deactivate/Delete stacked)
- English error messages

**How the Hidden Dropdown System works:**
1. When user clicks "Delete" on an inactive dropdown, the ID is stored in localStorage key `hiddenDropdownIds`
2. All components (Materials, Dropdowns, MaterialForm) filter out hidden dropdowns using `dropdownFilter.js` utilities
3. Materials with hidden dropdowns show "-" instead of the dropdown value
4. Hidden dropdowns remain in database but are invisible in UI

**Example changes:**
- Add new dropdown type (e.g., "Status", "Category")
- Change how dropdown values are generated
- Add validation for dropdown names
- Modify the hiding mechanism

**How to add new dropdown type:**

Step 1: Add new tab in frontend
```javascript
// In /frontend/src/pages/Dropdowns.jsx
// Add new tab item

const items = [
  { key: 'division', label: 'Material Owner (Division)' },
  { key: 'placement', label: 'Material Placement' },
  // Add new type here
  { key: 'category', label: 'Material Category' }
];
```

Step 2: Backend will automatically handle it (no changes needed)

**How to manage hidden dropdowns:**
```javascript
// Import utility functions from dropdownFilter.js
import { 
  getHiddenDropdownIds,      // Get array of hidden IDs from localStorage
  filterHiddenDropdowns,      // Filter array to exclude hidden dropdowns
  isDropdownHidden            // Check if specific ID is hidden
} from '../utils/dropdownFilter';

// Usage example:
const hiddenIds = getHiddenDropdownIds();
const visibleDropdowns = filterHiddenDropdowns(allDropdowns);
const isHidden = isDropdownHidden(dropdownId);
```

---

### 6. Image Upload Settings

**What to modify:** Maximum file size, allowed file types, number of images

**Files to edit:**
- `/backend/routes/materials.js` - Multer configuration
- `/frontend/src/components/MaterialForm.jsx` - Upload component settings

**Example changes:**
- Change maximum image size (default: 5MB)
- Allow more/fewer images per material (default: 5)
- Change allowed file types

**How to:**
```javascript
// In /backend/routes/materials.js
// Find the multer configuration

const upload = multer({
  storage: storage,
  limits: { 
    fileSize: 10 * 1024 * 1024 // Change to 10MB
  },
  fileFilter: (req, file, cb) => {
    // Modify allowed file types here
  }
});
```

---

### 7. Navigation Menu

**What to modify:** Menu items, logos, user display

**Files to edit:**
- `/frontend/src/components/Navbar.jsx` - Navigation bar component

**Example changes:**
- Add new menu item
- Change menu icons
- Modify logout button
- Change logo

**How to:**
```javascript
// In /frontend/src/components/Navbar.jsx
// Find the items array

const items = [
  { key: '/', icon: <HomeOutlined />, label: 'Dashboard' },
  { key: '/materials', icon: <AppstoreOutlined />, label: 'Materials' },
  // Add new menu item here
  { key: '/reports', icon: <FileOutlined />, label: 'Reports' }
];
```

---

### 8. Session and Authentication

**What to modify:** Session timeout, password requirements, login validation, registration

**Files to edit:**
- `/backend/server.js` - Session configuration
- `/backend/config/database.js` - Database and session store configuration
- `/backend/routes/auth.js` - Authentication and registration logic
- `/backend/models/User.js` - User model and password hashing
- `/frontend/src/pages/Register.jsx` - Registration page

**Current features:**
- User registration with email and password
- Password confirmation validation
- Session storage in PostgreSQL
- 24-hour session timeout
- Bcrypt password hashing

**Example changes:**
- Change session timeout (default: 24 hours)
- Modify password requirements
- Add "Remember Me" functionality
- Require additional registration fields (name, phone, etc.)

**How to:**
```javascript
// In /backend/server.js
// Find the session configuration

app.use(session({
  secret: process.env.SESSION_SECRET,
  cookie: {
    maxAge: 1000 * 60 * 60 * 48 // Change to 48 hours
  }
}));
```

---

## Common Customizations

### Change Application Name

**Files to edit:**
- `/frontend/public/index.html` - Page title
- `/frontend/public/manifest.json` - App name
- `/frontend/src/components/Navbar.jsx` - Header text
- `/frontend/src/pages/Login.jsx` - Login page title
- `/frontend/src/pages/Register.jsx` - Registration page title

### Change Background Image

**Files to edit:**
- `/frontend/public/BG.webp` - Replace with your own image file
- Keep the same filename or update the references in Login.jsx and Register.jsx

**How to:**
```javascript
// In Login.jsx or Register.jsx
// Change the backgroundImage URL
style={{
  backgroundImage: 'url(/your-new-image.jpg)',
  backgroundSize: 'cover',
  backgroundPosition: 'center'
}}
```

### Change Color Theme

**Files to edit:**
- `/frontend/src/pages/*.jsx` - Modify inline styles or add custom CSS

**Example:**
```javascript
// Change primary color in any component
<Button type="primary" style={{ backgroundColor: '#ff6b6b' }}>
  Click Me
</Button>
```

### Add New Page

**Steps:**
1. Create new file in `/frontend/src/pages/` (e.g., `Reports.jsx`)
2. Add route in `/frontend/src/App.js`
3. Add menu item in `/frontend/src/components/Navbar.jsx`
4. Create API endpoint in `/backend/routes/` if needed

**Example:**
```javascript
// In /frontend/src/App.js
<Route 
  path="/reports" 
  element={user ? <Reports user={user} /> : <Navigate to="/login" />} 
/>
```

### Change Date/Time Format

**Files to edit:**
- Any component that displays dates

**Example:**
```javascript
// Change date format
new Date(material.createdAt).toLocaleDateString('en-US', {
  year: 'numeric',
  month: 'long',
  day: 'numeric'
})
```

---

## Database Changes

### Add New Field to Material

**Step 1:** Update Material model
```javascript
// In /backend/models/Material.js
// Update the create and update methods to include your new field
static async create(materialData) {
  const query = `
    INSERT INTO materials 
    (material_name, material_number, material_owner, material_placement, 
     material_function, images, your_new_field)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *
  `;
  const values = [
    materialData.materialName,
    materialData.materialNumber,
    materialData.materialOwner,
    materialData.materialPlacement,
    materialData.materialFunction,
    JSON.stringify(materialData.images || []),
    materialData.yourNewField
  ];
  // ... rest of the code
}
```

**Step 2:** Update database schema
```sql
-- Run this in your PostgreSQL database
ALTER TABLE materials ADD COLUMN your_new_field VARCHAR(255);
```

**Step 3:** Update Material form
```javascript
// In /frontend/src/components/MaterialForm.jsx
<Form.Item label="Your New Field" name="yourNewField">
  <Input />
</Form.Item>
```

**Step 4:** Update Material table (optional)
```javascript
// In /frontend/src/pages/Materials.jsx
// Add new column to display the field
```

### Create New Table

**Step 1:** Create table in PostgreSQL
```sql
CREATE TABLE your_table (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Step 2:** Create new model file
```javascript
// Create /backend/models/YourModel.js
const pool = require('../config/database');

class YourModel {
  static async findAll() {
    const result = await pool.query('SELECT * FROM your_table WHERE is_active = true');
    return result.rows;
  }
  
  static async create(data) {
    const query = 'INSERT INTO your_table (name) VALUES ($1) RETURNING *';
    const result = await pool.query(query, [data.name]);
    return result.rows[0];
  }
}

module.exports = YourModel;
```

**Step 3:** Create routes file
```javascript
// Create /backend/routes/yourRoutes.js
const express = require('express');
const router = express.Router();
const YourModel = require('../models/YourModel');

router.get('/', async (req, res) => {
  try {
    const items = await YourModel.findAll();
    res.json(items);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

**Step 4:** Register routes in server
```javascript
// In /backend/server.js
const yourRoutes = require('./routes/yourRoutes');
app.use('/api/your-endpoint', yourRoutes);
```

---

## Troubleshooting

### Changes Not Showing Up

**Frontend changes:**
1. Check browser console for errors (F12)
2. Clear browser cache (Ctrl/Cmd + Shift + R)
3. Restart frontend server (Ctrl + C, then `npm start`)

**Backend changes:**
1. Check terminal for errors
2. Restart backend server (Ctrl + C, then `node server.js`)
3. Check if PostgreSQL database is connected

### Can't Find Where to Edit

**Strategy:**
1. Search for the text you see on the screen in the codebase
2. Look for similar functionality in existing files
3. Check console.log() to trace the code flow
4. Use browser DevTools to inspect elements and find component names

### Hidden Dropdown Issues

**Problem:** Dropdowns not hiding properly or showing when they shouldn't

**Solution:**
1. Check localStorage in browser DevTools (Application > Local Storage)
2. Look for key `hiddenDropdownIds` - should be array of numbers
3. Clear localStorage and refresh if data is corrupted: `localStorage.clear()`
4. Verify dropdownFilter.js utility is imported in all components

### Background Image Not Showing

**Problem:** BG.webp not displaying on Login/Register pages

**Solution:**
1. Verify file exists at `/frontend/public/BG.webp`
2. Check file permissions and size (should be ~281KB)
3. Clear browser cache (Cmd/Ctrl + Shift + R)
4. Check browser console for 404 errors

### Breaking Changes

**Before making changes:**
1. Create a backup of the file you're editing
2. Test on a development branch first
3. Use Git to track changes: `git status`, `git diff`

**If something breaks:**
1. Check browser console and terminal for error messages
2. Use Git to see what changed: `git diff`
3. Revert changes if needed: `git checkout -- <filename>`

---

## Testing Scripts

The project includes automated testing scripts located in the `/testing` folder:

- `consistency-test.sh` - Tests data consistency across the application
- `start-server.sh` - Convenient script to start the backend server
- `test-correlation.sh` - Tests correlation between related data
- `test-frontend-workflow.sh` - Tests frontend user workflows
- `test-soft-delete.sh` - Tests soft delete functionality

**How to run tests:**
```bash
cd testing
bash test-soft-delete.sh  # Run specific test
```

---

## Documentation Files

Technical documentation is organized in the `/dokumentasi` folder:

- **API_TEST_RESULTS.md** - API endpoint testing results
- **FINAL_CONSISTENCY_AUDIT.md** - Final consistency audit report
- **FRONTEND_AND_UPLOAD_TEST.md** - Frontend and upload feature testing
- **FRONTEND_BROWSER_TEST.md** - Browser compatibility testing
- **MIGRATION_SUMMARY.md** - Database migration documentation
- **REGISTRATION_FEATURE.md** - User registration feature documentation
- **SOFT_DELETE_IMPLEMENTATION.md** - Soft delete implementation details
- **SOFT_DELETE_SUMMARY.md** - Soft delete feature summary
- **TIMESTAMP_AND_CORRELATION_AUDIT.md** - Timestamp and data correlation audit
- **audit-report.md** - General audit report

### Can't Find Where to Edit

**Strategy:**
1. Search for the text you see on the screen in the codebase
2. Look for similar functionality in existing files
3. Check console.log() to trace the code flow

### Breaking Changes

**Before making changes:**
1. Create a backup of the file you're editing
2. Test on a development branch first
3. Use Git to track changes: `git status`, `git diff`

**If something breaks:**
1. Check browser console and terminal for error messages
2. Use Git to see what changed: `git diff`
3. Revert changes if needed: `git checkout -- <filename>`

---

## Best Practices

1. **Always test after making changes**
   - Test the feature you modified
   - Check if other features still work

2. **Comment your code**
   ```javascript
   // This function calculates the total price
   const calculateTotal = (items) => {
     // Add your logic here
   };
   ```

3. **Use meaningful variable names**
   ```javascript
   // Bad
   const x = data.filter(d => d.a === true);
   
   // Good
   const activeMaterials = materials.filter(material => material.isActive === true);
   ```

4. **Keep functions small and focused**
   - One function should do one thing
   - If a function is too long, split it into smaller functions

5. **Handle errors properly**
   ```javascript
   try {
     // Your code
   } catch (error) {
     console.error('Error:', error);
     message.error('Something went wrong');
   }
   ```

---

## Need Help?

If you're stuck or need help with a specific customization:

1. Check the error message in browser console (F12) or terminal
2. Search for the error message online
3. Review similar code in other files
4. Create an issue on GitHub repository
5. Check the main README.md for common issues

