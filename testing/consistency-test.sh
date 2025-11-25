#!/bin/bash
echo "=================================="
echo "CONSISTENCY VALIDATION TEST"
echo "=================================="

# Login
curl -s -c test-cookies.txt -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' > /dev/null

echo ""
echo "1. Testing Material Response Format..."
MATERIAL=$(curl -s -b test-cookies.txt http://localhost:5001/api/materials/1)
echo "$MATERIAL" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('✓ materialName:', 'materialName' in data)
print('✓ materialNumber:', 'materialNumber' in data)
print('✓ divisionId:', 'divisionId' in data)
print('✓ placementId:', 'placementId' in data)
print('✓ isActive:', 'isActive' in data)
print('✓ createdAt:', 'createdAt' in data)
print('✓ updatedAt:', 'updatedAt' in data)
print('✗ material_name:', 'material_name' in data, '(should be False)')
print('✗ is_active:', 'is_active' in data, '(should be False)')
"

echo ""
echo "2. Testing Dropdown Response Format..."
DROPDOWN=$(curl -s -b test-cookies.txt http://localhost:5001/api/dropdowns/division | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)[0]))")
echo "$DROPDOWN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('✓ isActive:', 'isActive' in data)
print('✓ createdAt:', 'createdAt' in data)
print('✓ updatedAt:', 'updatedAt' in data)
print('✗ is_active:', 'is_active' in data, '(should be False)')
print('✗ created_at:', 'created_at' in data, '(should be False)')
print('✗ updated_at:', 'updated_at' in data, '(should be False)')
"

echo ""
echo "3. Testing Dashboard Response Format..."
DASHBOARD=$(curl -s -b test-cookies.txt http://localhost:5001/api/dashboard/stats)
echo "$DASHBOARD" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('recentMaterials') and len(data['recentMaterials']) > 0:
    mat = data['recentMaterials'][0]
    print('✓ materialName in recentMaterials:', 'materialName' in mat)
    print('✓ isActive in recentMaterials:', 'isActive' in mat)
    print('✗ material_name in recentMaterials:', 'material_name' in mat, '(should be False)')
"

echo ""
echo "=================================="
echo "CONSISTENCY TEST COMPLETED"
echo "=================================="

rm -f test-cookies.txt
