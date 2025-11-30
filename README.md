ALL OF THIS OWNED BY M. ABYANSYAH P.D
# Material Management System

A comprehensive Material Management System built with PostgreSQL, Express.js, React, and Node.js. Features include user authentication, material CRUD operations, dropdown management with soft delete, and a hidden dropdown system.

## System Requirements

- Node.js version 14 or higher
- PostgreSQL 17.5 or higher
- npm (comes with Node.js)

## Installation Guide

### Step 1: Clone Repository

```bash
git clone 
cd PSO_Final
```

### Step 2: PostgreSQL Setup

1. Install PostgreSQL 17.5 or higher
2. Create a new database named `material_management`
3. Run the schema setup:

```bash
cd backend
psql -U your_username -d material_management -f schema.sql
```

For detailed PostgreSQL setup instructions, see `POSTGRESQL_SETUP.md`

### Step 3: Backend Installation

Navigate to backend folder and install dependencies:

```bash
cd backend
npm install
```

Create a `.env` file in the backend folder with the following content:

```
DB_USER=your_postgres_username
DB_HOST=localhost
DB_NAME=material_management
DB_PASSWORD=your_postgres_password
DB_PORT=5432
SESSION_SECRET=your_random_secret_key_here
PORT=5001
```

### Step 4: Frontend Installation

Open a new terminal window, navigate to frontend folder and install dependencies:

```bash
cd frontend
npm install
```

## Running the Application

You need to run both backend and frontend servers simultaneously.

### Terminal 1 - Start Backend Server

```bash
cd backend
node server.js
```

Or use the convenient script:
```bash
cd testing
bash start-server.sh
```

You should see:
- Server running on http://localhost:5001
- PostgreSQL connected successfully

### Terminal 2 - Start Frontend Server

```bash
cd frontend
npm start
```

The application will automatically open in your browser at http://localhost:3000

If it doesn't open automatically, manually open your browser and go to:
```
http://localhost:3000
```

## Login Credentials

Default admin credentials:

```
Email: admin@example.com
Password: admin123
```

Test user credentials:
```
Email: test@example.com
Password: test123
```

## Application Features

### 1. User Authentication & Registration
- User registration with email and password
- Password confirmation validation
- Session-based authentication (24-hour session)
- Secure password hashing with bcrypt
- Custom background image on auth pages

### 2. Material Management
- Create new materials with details (name, number, division, placement, function)
- Upload up to 5 images per material
- Edit existing materials
- Delete materials (soft delete)
- Toggle material status between Active and Inactive
- Search materials by name or number
- Filter materials by division or placement
- Vertical action button layout for better UI
- English language interface

### 3. Dropdown Settings (Division & Placement)
- Manage Material Owner (Division) options
- Manage Material Placement options
- Add, edit, or delete dropdown options
- **Soft Delete**: Deactivate/reactivate dropdowns without database deletion
- **Hidden Dropdown System**: Frontend-only deletion using localStorage
  - Delete inactive dropdowns from UI without removing from database
  - Hidden dropdowns show as "-" in material displays
  - Hidden dropdowns excluded from form selects
  - Persistent across page refreshes via localStorage
- Vertical action button layout (Edit/Deactivate/Delete stacked)

### 4. Dashboard
- View total number of materials
- View active materials count
- View total divisions and placements
- See materials grouped by division
- View recent materials list

### 5. Hidden Dropdown System Details

The application uses a localStorage-based system to "hide" dropdowns without deleting them from the database:

**How it works:**
1. User deactivates a dropdown using the "Deactivate" button (soft delete - sets `is_active = false`)
2. User can then click "Delete" to hide the inactive dropdown from the UI
3. The dropdown ID is stored in localStorage under key `hiddenDropdownIds`
4. All components filter hidden dropdowns using utilities from `dropdownFilter.js`
5. Materials with hidden dropdowns display "-" instead of the dropdown value
6. Hidden dropdowns remain in database but are invisible throughout the UI

**Utility Functions** (in `/frontend/src/utils/dropdownFilter.js`):
- `getHiddenDropdownIds()` - Retrieve hidden dropdown IDs from localStorage
- `filterHiddenDropdowns(dropdowns)` - Filter array to exclude hidden dropdowns
- `isDropdownHidden(id)` - Check if specific dropdown ID is hidden

## Project Structure

```
material-management/
├── backend/                    # Backend server
│   ├── config/
│   │   └── database.js        # PostgreSQL connection & session store
│   ├── middleware/
│   │   └── auth.js            # Authentication middleware
│   ├── models/                # Database models
│   │   ├── User.js            # User model with bcrypt
│   │   ├── Material.js        # Material model with CRUD operations
│   │   └── Dropdown.js        # Dropdown model with soft delete
│   ├── routes/                # API endpoints
│   │   ├── auth.js            # Authentication & registration routes
│   │   ├── materials.js       # Material CRUD routes
│   │   ├── dropdowns.js       # Dropdown management routes
│   │   └── dashboard.js       # Dashboard statistics routes
│   ├── uploads/               # Uploaded images storage
│   │   └── materials/
│   ├── server.js              # Main backend server
│   ├── schema.sql             # PostgreSQL schema
│   ├── package.json
│   └── .env                   # Environment variables (create this)
│
├── frontend/                   # React frontend
│   ├── public/
│   │   ├── index.html
│   │   ├── manifest.json
│   │   └── BG.webp            # Background image for auth pages
│   └── src/
│       ├── components/        # Reusable components
│       │   ├── Navbar.jsx     # Navigation bar
│       │   └── MaterialForm.jsx # Material create/edit form
│       ├── pages/             # Page components
│       │   ├── Login.jsx      # Login page with background
│       │   ├── Register.jsx   # Registration page with background
│       │   ├── Dashboard.jsx  # Dashboard with statistics
│       │   ├── Materials.jsx  # Material list & management
│       │   └── Dropdowns.jsx  # Dropdown settings
│       ├── utils/             # Helper functions
│       │   ├── api.js         # API calls to backend
│       │   └── dropdownFilter.js # Hidden dropdown utilities
│       ├── App.js             # Main application with routes
│       ├── index.js
│       ├── index.css
│       └── package.json
│
├── dokumentasi/               # Documentation folder
│   ├── API_TEST_RESULTS.md
│   ├── FINAL_CONSISTENCY_AUDIT.md
│   ├── FRONTEND_AND_UPLOAD_TEST.md
│   ├── FRONTEND_BROWSER_TEST.md
│   ├── MIGRATION_SUMMARY.md
│   ├── REGISTRATION_FEATURE.md
│   ├── SOFT_DELETE_IMPLEMENTATION.md
│   ├── SOFT_DELETE_SUMMARY.md
│   ├── TIMESTAMP_AND_CORRELATION_AUDIT.md
│   └── audit-report.md
│
├── testing/                   # Test scripts folder
│   ├── consistency-test.sh
│   ├── start-server.sh
│   ├── test-correlation.sh
│   ├── test-frontend-workflow.sh
│   └── test-soft-delete.sh
│
├── README.md                  # This file
├── GUIDE.md                   # Developer guide for customization
├── POSTGRESQL_SETUP.md        # PostgreSQL setup instructions
└── .gitignore
```

## API Endpoints Reference

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/check` - Check if user is logged in

### Materials
- `GET /api/materials` - Get all materials with pagination and filters
- `GET /api/materials/:id` - Get single material details
- `POST /api/materials` - Create new material
- `PUT /api/materials/:id` - Update material
- `DELETE /api/materials/:id` - Soft delete material (set is_active = false)
- `PATCH /api/materials/:id/toggle-status` - Toggle active/inactive status
- `POST /api/materials/:id/images` - Upload images for material
- `DELETE /api/materials/:id/images/:imageId` - Delete specific image

### Dropdowns
- `GET /api/dropdowns/:type` - Get dropdown options by type (division or placement)
  - Query param: `activeOnly=true/false` (default: true)
- `POST /api/dropdowns` - Create new dropdown option
- `PUT /api/dropdowns/:id` - Update dropdown option
- `DELETE /api/dropdowns/:id` - Soft delete dropdown (set is_active = false)
- `PUT /api/dropdowns/:id/toggle` - Toggle active/inactive status
- `DELETE /api/dropdowns/:id/permanent` - Permanently delete dropdown (requires inactive)

### Dashboard
- `GET /api/dashboard/stats` - Get statistics for dashboard

## Technology Stack

### Backend Technologies
- Node.js - JavaScript runtime
- Express.js - Web framework
- PostgreSQL 17.5 - Relational database
- pg (node-postgres) - PostgreSQL client for Node.js
- express-session - Session management
- connect-pg-simple - PostgreSQL session store
- bcrypt - Password hashing
- multer - File upload handling
- cors - Cross-origin resource sharing
- dotenv - Environment variable management

### Frontend Technologies
- React 18 - UI library
- React Router v6 - Client-side routing
- Ant Design v5 - UI components
- Axios - HTTP client
- localStorage API - Client-side storage for hidden dropdowns

### Database Schema
- **users** table - User authentication (id, email, password, created_at, updated_at)
- **materials** table - Material data with JSONB images, timestamps, soft delete
- **dropdowns** table - Division and placement options with soft delete
- **session** table - PostgreSQL-backed session storage

## Common Issues and Solutions

### Issue: Cannot connect to PostgreSQL
Solution: 
1. Check if PostgreSQL is running: `psql --version`
2. Verify database credentials in `.env` file
3. Ensure database `material_management` exists
4. Check if PostgreSQL is listening on port 5432

### Issue: Port already in use
Solution: Kill the process using the port or change the port number in .env file.

```bash
# For Mac/Linux
lsof -ti:5001 | xargs kill -9
lsof -ti:3000 | xargs kill -9

# For Windows
netstat -ano | findstr :5001
taskkill /PID <PID_NUMBER> /F
```

### Issue: Session expires immediately
Solution: 
1. Make sure both backend and frontend are running
2. Check CORS configuration in backend/server.js
3. Verify SESSION_SECRET is set in .env file
4. Clear browser cookies and localStorage

### Issue: Images not uploading
Solution: Check if the uploads folder exists in the backend directory. The system should create it automatically, but you can create it manually if needed:

```bash
cd backend
mkdir -p uploads/materials
```

### Issue: Hidden dropdowns not working
Solution:
1. Check browser's localStorage (DevTools > Application > Local Storage)
2. Look for key `hiddenDropdownIds` - should be a JSON array
3. Clear localStorage if corrupted: `localStorage.clear()` in browser console
4. Refresh the page

### Issue: Background image not showing on login/register
Solution:
1. Verify `BG.webp` exists in `frontend/public/` folder
2. Clear browser cache (Cmd/Ctrl + Shift + R)
3. Check browser console for 404 errors
4. Ensure image file is not corrupted (should be ~281KB)

## Development Notes

- Backend runs on port 5001
- Frontend runs on port 3000
- Session timeout is set to 24 hours
- Maximum image upload size is 5MB per image
- Maximum 5 images per material
- Supported image formats: JPG, JPEG, PNG, WEBP
- Database uses snake_case naming convention
- Frontend uses camelCase for JavaScript variables
- PostgreSQL session store automatically creates `session` table
- Hidden dropdowns stored in browser's localStorage

## Testing

The project includes comprehensive test scripts in the `/testing` folder:

```bash
cd testing

# Test soft delete functionality
bash test-soft-delete.sh

# Test data correlation
bash test-correlation.sh

# Test frontend workflows
bash test-frontend-workflow.sh

# Test data consistency
bash consistency-test.sh

# Start backend server
bash start-server.sh
```

## Documentation

For detailed technical documentation, see files in the `/dokumentasi` folder:

- **GUIDE.md** - Developer guide for customizing the application
- **POSTGRESQL_SETUP.md** - Detailed PostgreSQL setup instructions
- **SOFT_DELETE_IMPLEMENTATION.md** - Soft delete feature implementation details
- **REGISTRATION_FEATURE.md** - User registration feature documentation
- **API_TEST_RESULTS.md** - API testing results and validation

## Security Considerations

- Passwords are hashed using bcrypt with salt rounds
- Session secrets should be strong and kept private
- File uploads are validated for type and size
- SQL injection protection via parameterized queries
- CORS configured for specific origins
- Session cookies are HTTP-only

## Future Enhancements

Potential features for future development:
- Role-based access control (admin, user, viewer)
- Export materials to Excel/PDF
- Advanced search with multiple filters
- Material history/audit log
- Email notifications
- Bulk upload/import materials
- Material categories and tags

## Author

berkasaby@gmail.com



Staging Environment Ready - 2025-11-30 12:40:16
