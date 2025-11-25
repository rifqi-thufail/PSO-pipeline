#!/bin/bash
# Data Correlation Test Script
# Verifies data consistency across Dashboard, Materials, and Dropdowns pages

BASE_URL="http://localhost:5001/api"
COOKIE_FILE="cookies.txt"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

print_test() {
    local test_name="$1"
    local result="$2"
    if [ "$result" == "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
    fi
}

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Data Correlation Audit${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Login
echo -e "${YELLOW}Setup: Authentication${NC}"
LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' \
    -c "$COOKIE_FILE" 2>/dev/null)

if echo "$LOGIN" | grep -q '"success":true'; then
    echo -e "${GREEN}✓${NC} Login successful\n"
else
    echo -e "${RED}✗${NC} Login failed"
    exit 1
fi

# ============================================
# Test 1: Dashboard Total vs Materials Total
# ============================================
echo -e "${YELLOW}Test 1: Dashboard Total Materials Correlation${NC}"

DASHBOARD=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dashboard/stats" 2>/dev/null)
DASHBOARD_TOTAL=$(echo "$DASHBOARD" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('totalMaterials', 0))" 2>/dev/null)

MATERIALS=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/materials?page=1&limit=1" 2>/dev/null)
MATERIALS_TOTAL=$(echo "$MATERIALS" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('total', 0))" 2>/dev/null)

if [ "$DASHBOARD_TOTAL" == "$MATERIALS_TOTAL" ]; then
    print_test "Dashboard totalMaterials ($DASHBOARD_TOTAL) = Materials total ($MATERIALS_TOTAL)" "PASS"
else
    print_test "Dashboard totalMaterials ($DASHBOARD_TOTAL) = Materials total ($MATERIALS_TOTAL)" "FAIL"
fi
echo ""

# ============================================
# Test 2: Dashboard Active Materials Count
# ============================================
echo -e "${YELLOW}Test 2: Dashboard Active Materials Correlation${NC}"

DASHBOARD_ACTIVE=$(echo "$DASHBOARD" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('activeMaterials', 0))" 2>/dev/null)

MATERIALS_ACTIVE=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/materials?status=active&page=1&limit=100" 2>/dev/null | python3 -c "import sys, json; d=json.load(sys.stdin); print(len([m for m in d.get('materials', []) if m.get('isActive')]))" 2>/dev/null)

if [ "$DASHBOARD_ACTIVE" == "$MATERIALS_ACTIVE" ]; then
    print_test "Dashboard activeMaterials ($DASHBOARD_ACTIVE) = Actual active count ($MATERIALS_ACTIVE)" "PASS"
else
    print_test "Dashboard activeMaterials ($DASHBOARD_ACTIVE) = Actual active count ($MATERIALS_ACTIVE)" "FAIL"
fi
echo ""

# ============================================
# Test 3: Dashboard Divisions vs Actual Active Divisions
# ============================================
echo -e "${YELLOW}Test 3: Dashboard Divisions Correlation${NC}"

DASHBOARD_DIVS=$(echo "$DASHBOARD" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('totalDivisions', 0))" 2>/dev/null)

ACTUAL_DIVS=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dropdowns/division" 2>/dev/null | python3 -c "import sys, json; divs=json.load(sys.stdin); print(len(divs))" 2>/dev/null)

if [ "$DASHBOARD_DIVS" == "$ACTUAL_DIVS" ]; then
    print_test "Dashboard totalDivisions ($DASHBOARD_DIVS) = Actual active divisions ($ACTUAL_DIVS)" "PASS"
else
    print_test "Dashboard totalDivisions ($DASHBOARD_DIVS) = Actual active divisions ($ACTUAL_DIVS)" "FAIL"
fi
echo ""

# ============================================
# Test 4: Materials by Division Count
# ============================================
echo -e "${YELLOW}Test 4: Materials by Division Aggregation${NC}"

DASHBOARD_BY_DIV=$(echo "$DASHBOARD" | python3 -c "import sys, json; d=json.load(sys.stdin); print(sum(item['count'] for item in d.get('materialsByDivision', [])))" 2>/dev/null)

if [ "$DASHBOARD_BY_DIV" == "$DASHBOARD_TOTAL" ]; then
    print_test "Sum of materialsByDivision ($DASHBOARD_BY_DIV) = totalMaterials ($DASHBOARD_TOTAL)" "PASS"
else
    print_test "Sum of materialsByDivision ($DASHBOARD_BY_DIV) = totalMaterials ($DASHBOARD_TOTAL)" "FAIL"
fi
echo ""

# ============================================
# Test 5: Recent Materials Data Integrity
# ============================================
echo -e "${YELLOW}Test 5: Recent Materials Data Integrity${NC}"

RECENT_MATERIALS=$(echo "$DASHBOARD" | python3 -c "
import sys, json
d = json.load(sys.stdin)
recent = d.get('recentMaterials', [])
if recent:
    mat = recent[0]
    # Check required fields
    has_id = 'id' in mat
    has_name = 'materialName' in mat
    has_number = 'materialNumber' in mat
    has_division = 'divisionId' in mat
    has_created = 'createdAt' in mat
    has_active = 'isActive' in mat
    print('PASS' if all([has_id, has_name, has_number, has_division, has_created, has_active]) else 'FAIL')
else:
    print('SKIP')
" 2>/dev/null)

if [ "$RECENT_MATERIALS" == "PASS" ]; then
    print_test "Recent materials have all required fields (id, materialName, materialNumber, divisionId, createdAt, isActive)" "PASS"
elif [ "$RECENT_MATERIALS" == "SKIP" ]; then
    print_test "Recent materials data integrity" "SKIP (no data)"
else
    print_test "Recent materials have all required fields" "FAIL"
fi
echo ""

# ============================================
# Test 6: Division References in Materials
# ============================================
echo -e "${YELLOW}Test 6: Division References Validation${NC}"

# Get all materials and check if their divisionId exists
MATERIALS_ALL=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/materials?page=1&limit=100" 2>/dev/null)
ALL_DIVISIONS=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dropdowns/division?activeOnly=false" 2>/dev/null)

ORPHANED=$(python3 -c "
import sys, json

materials_str = '''$MATERIALS_ALL'''
divisions_str = '''$ALL_DIVISIONS'''

materials_data = json.loads(materials_str)
divisions_data = json.loads(divisions_str)

materials = materials_data.get('materials', [])
division_ids = {d['id'] for d in divisions_data}

orphaned = 0
for mat in materials:
    div_id = mat.get('divisionId', {}).get('id')
    if div_id and div_id not in division_ids:
        orphaned += 1

print(orphaned)
" 2>/dev/null)

if [ "$ORPHANED" == "0" ]; then
    print_test "No orphaned division references in materials" "PASS"
else
    print_test "No orphaned division references in materials (found $ORPHANED)" "FAIL"
fi
echo ""

# ============================================
# Test 7: Placement References in Materials
# ============================================
echo -e "${YELLOW}Test 7: Placement References Validation${NC}"

ALL_PLACEMENTS=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dropdowns/placement?activeOnly=false" 2>/dev/null)

ORPHANED_PLACE=$(python3 -c "
import sys, json

materials_str = '''$MATERIALS_ALL'''
placements_str = '''$ALL_PLACEMENTS'''

materials_data = json.loads(materials_str)
placements_data = json.loads(placements_str)

materials = materials_data.get('materials', [])
placement_ids = {p['id'] for p in placements_data}

orphaned = 0
for mat in materials:
    place_id = mat.get('placementId', {}).get('id')
    if place_id and place_id not in placement_ids:
        orphaned += 1

print(orphaned)
" 2>/dev/null)

if [ "$ORPHANED_PLACE" == "0" ]; then
    print_test "No orphaned placement references in materials" "PASS"
else
    print_test "No orphaned placement references in materials (found $ORPHANED_PLACE)" "FAIL"
fi
echo ""

# ============================================
# Test 8: CreatedAt Timestamp Consistency
# ============================================
echo -e "${YELLOW}Test 8: CreatedAt Timestamp Format${NC}"

TIMESTAMP_CHECK=$(echo "$MATERIALS_ALL" | python3 -c "
import sys, json
from datetime import datetime
data = json.load(sys.stdin)
materials = data.get('materials', [])
if materials:
    mat = materials[0]
    created_at = mat.get('createdAt')
    if created_at:
        try:
            datetime.fromisoformat(created_at.replace('Z', '+00:00'))
            print('PASS')
        except:
            print('FAIL')
    else:
        print('FAIL')
else:
    print('SKIP')
" 2>/dev/null)

if [ "$TIMESTAMP_CHECK" == "PASS" ]; then
    print_test "CreatedAt timestamp is valid ISO format" "PASS"
elif [ "$TIMESTAMP_CHECK" == "SKIP" ]; then
    print_test "CreatedAt timestamp format" "SKIP (no data)"
else
    print_test "CreatedAt timestamp is valid ISO format" "FAIL"
fi
echo ""

# ============================================
# Test 9: Dashboard Recent Materials Order
# ============================================
echo -e "${YELLOW}Test 9: Recent Materials Order (Newest First)${NC}"

ORDER_CHECK=$(echo "$DASHBOARD" | python3 -c "
import sys, json
from datetime import datetime
d = json.load(sys.stdin)
recent = d.get('recentMaterials', [])
if len(recent) >= 2:
    dates = [datetime.fromisoformat(m['createdAt'].replace('Z', '+00:00')) for m in recent if 'createdAt' in m]
    # Check if sorted descending (newest first)
    is_sorted = all(dates[i] >= dates[i+1] for i in range(len(dates)-1))
    print('PASS' if is_sorted else 'FAIL')
else:
    print('SKIP')
" 2>/dev/null)

if [ "$ORDER_CHECK" == "PASS" ]; then
    print_test "Recent materials ordered by createdAt DESC (newest first)" "PASS"
elif [ "$ORDER_CHECK" == "SKIP" ]; then
    print_test "Recent materials order" "SKIP (insufficient data)"
else
    print_test "Recent materials ordered by createdAt DESC" "FAIL"
fi
echo ""

# ============================================
# Test 10: Material Images URLs Valid
# ============================================
echo -e "${YELLOW}Test 10: Material Images URL Format${NC}"

IMAGES_CHECK=$(echo "$MATERIALS_ALL" | python3 -c "
import sys, json
data = json.load(sys.stdin)
materials = data.get('materials', [])
invalid_urls = 0
for mat in materials:
    images = mat.get('images', [])
    for img in images:
        url = img.get('url', '')
        if url and not url.startswith('/uploads/'):
            invalid_urls += 1
print(invalid_urls)
" 2>/dev/null)

if [ "$IMAGES_CHECK" == "0" ]; then
    print_test "All material image URLs have correct format (/uploads/...)" "PASS"
else
    print_test "All material image URLs have correct format (found $IMAGES_CHECK invalid)" "FAIL"
fi
echo ""

# ============================================
# Summary
# ============================================
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Correlation Audit Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total: $TOTAL"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All data correlations are valid!${NC}"
    echo -e "${GREEN}✓ Dashboard, Materials, and Dropdowns pages are consistent${NC}"
    exit 0
else
    echo -e "${RED}✗ Some correlations failed${NC}"
    exit 1
fi
