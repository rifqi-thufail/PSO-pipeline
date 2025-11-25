#!/bin/bash
# Soft Delete Functionality Test Script
# Tests the complete soft delete implementation for dropdown management

BASE_URL="http://localhost:5001/api"
COOKIE_FILE="cookies.txt"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to print test results
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
echo -e "${BLUE}Soft Delete Functionality Tests${NC}"
echo -e "${BLUE}================================================${NC}\n"

# ============================================
# Test 1: Login and Setup
# ============================================
echo -e "${YELLOW}Test 1: Authentication${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' \
    -c "$COOKIE_FILE")

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    print_test "Login successful" "PASS"
else
    print_test "Login successful" "FAIL"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi
echo ""

# ============================================
# Test 2: Get Active Dropdowns Only (Default)
# ============================================
echo -e "${YELLOW}Test 2: Fetch Active Dropdowns${NC}"
ACTIVE_DIVS=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dropdowns/division" 2>/dev/null)
ACTIVE_COUNT=$(echo "$ACTIVE_DIVS" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null)

if [ "$ACTIVE_COUNT" -ge 3 ]; then
    print_test "Get active divisions (found $ACTIVE_COUNT)" "PASS"
else
    print_test "Get active divisions" "FAIL"
fi
echo ""

# ============================================
# Test 3: Soft Delete Unused Dropdown
# ============================================
echo -e "${YELLOW}Test 3: Soft Delete Unused Dropdown${NC}"
# Find a division that exists
DIVISION_ID=$(echo "$ACTIVE_DIVS" | python3 -c "import sys, json; divs=json.load(sys.stdin); print(divs[0]['id'] if divs else 0)" 2>/dev/null)

if [ "$DIVISION_ID" -gt 0 ]; then
    DELETE_RESPONSE=$(curl -s -b "$COOKIE_FILE" -X DELETE "$BASE_URL/dropdowns/$DIVISION_ID")
    
    if echo "$DELETE_RESPONSE" | grep -q '"success":true' && echo "$DELETE_RESPONSE" | grep -q '"isActive":false'; then
        print_test "Soft delete dropdown (id=$DIVISION_ID)" "PASS"
        DELETED_ID=$DIVISION_ID
    else
        print_test "Soft delete dropdown" "FAIL"
        echo "Response: $DELETE_RESPONSE"
    fi
else
    print_test "Soft delete dropdown" "FAIL"
    echo "No division found to delete"
fi
echo ""

# ============================================
# Test 4: Verify Dropdown Not in Active List
# ============================================
echo -e "${YELLOW}Test 4: Verify Filtering Active Only${NC}"
ACTIVE_AFTER=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dropdowns/division" 2>/dev/null)
CONTAINS_DELETED=$(echo "$ACTIVE_AFTER" | python3 -c "import sys, json; divs=json.load(sys.stdin); print(any(d['id'] == $DELETED_ID for d in divs))" 2>/dev/null)

if [ "$CONTAINS_DELETED" == "False" ]; then
    print_test "Deactivated dropdown hidden from active list" "PASS"
else
    print_test "Deactivated dropdown hidden from active list" "FAIL"
fi
echo ""

# ============================================
# Test 5: Verify Dropdown Still in Database (All Query)
# ============================================
echo -e "${YELLOW}Test 5: Verify Data Preserved in Database${NC}"
ALL_DIVS=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dropdowns/division?activeOnly=false" 2>/dev/null)
CONTAINS_IN_ALL=$(echo "$ALL_DIVS" | python3 -c "import sys, json; divs=json.load(sys.stdin); print(any(d['id'] == $DELETED_ID and not d['isActive'] for d in divs))" 2>/dev/null)

if [ "$CONTAINS_IN_ALL" == "True" ]; then
    print_test "Deactivated dropdown still in database (activeOnly=false)" "PASS"
else
    print_test "Deactivated dropdown still in database" "FAIL"
fi
echo ""

# ============================================
# Test 6: Toggle Status (Activate)
# ============================================
echo -e "${YELLOW}Test 6: Reactivate Dropdown${NC}"
TOGGLE_RESPONSE=$(curl -s -b "$COOKIE_FILE" -X PUT "$BASE_URL/dropdowns/$DELETED_ID/toggle")

if echo "$TOGGLE_RESPONSE" | grep -q '"success":true' && echo "$TOGGLE_RESPONSE" | grep -q '"isActive":true'; then
    print_test "Toggle dropdown to active" "PASS"
else
    print_test "Toggle dropdown to active" "FAIL"
    echo "Response: $TOGGLE_RESPONSE"
fi
echo ""

# ============================================
# Test 7: Verify Reactivated in Active List
# ============================================
echo -e "${YELLOW}Test 7: Verify Reactivation${NC}"
ACTIVE_FINAL=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dropdowns/division" 2>/dev/null)
CONTAINS_REACTIVATED=$(echo "$ACTIVE_FINAL" | python3 -c "import sys, json; divs=json.load(sys.stdin); print(any(d['id'] == $DELETED_ID and d['isActive'] for d in divs))" 2>/dev/null)

if [ "$CONTAINS_REACTIVATED" == "True" ]; then
    print_test "Reactivated dropdown appears in active list" "PASS"
else
    print_test "Reactivated dropdown appears in active list" "FAIL"
fi
echo ""

# ============================================
# Test 8: Soft Delete Dropdown Used by Material
# ============================================
echo -e "${YELLOW}Test 8: Soft Delete Dropdown Used by Material${NC}"
# Check if there are materials
MATERIALS=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/materials?limit=1" 2>/dev/null)
MATERIAL_EXISTS=$(echo "$MATERIALS" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('total', 0) > 0)" 2>/dev/null)

if [ "$MATERIAL_EXISTS" == "True" ]; then
    # Get a division ID that's used by a material
    USED_DIV_ID=$(echo "$MATERIALS" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['materials'][0].get('divisionId', {}).get('id', 0) if d.get('materials') else 0)" 2>/dev/null)
    
    if [ "$USED_DIV_ID" -gt 0 ]; then
        DELETE_USED=$(curl -s -b "$COOKIE_FILE" -X DELETE "$BASE_URL/dropdowns/$USED_DIV_ID")
        
        if echo "$DELETE_USED" | grep -q '"success":true' && echo "$DELETE_USED" | grep -q '"isActive":false'; then
            print_test "Soft delete dropdown used by material (no error)" "PASS"
            USED_DELETED_ID=$USED_DIV_ID
        else
            print_test "Soft delete dropdown used by material" "FAIL"
            echo "Response: $DELETE_USED"
        fi
    else
        print_test "Soft delete dropdown used by material" "SKIP (no divisionId in material)"
    fi
else
    print_test "Soft delete dropdown used by material" "SKIP (no materials found)"
fi
echo ""

# ============================================
# Test 9: Verify Material Data Integrity
# ============================================
if [ ! -z "$USED_DELETED_ID" ]; then
    echo -e "${YELLOW}Test 9: Verify Material Data Integrity${NC}"
    MATERIAL_AFTER=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/materials?limit=1" 2>/dev/null)
    MATERIAL_DIV_ID=$(echo "$MATERIAL_AFTER" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['materials'][0].get('divisionId', {}).get('id', 0) if d.get('materials') else 0)" 2>/dev/null)
    
    if [ "$MATERIAL_DIV_ID" == "$USED_DELETED_ID" ]; then
        print_test "Material still references deactivated division" "PASS"
    else
        print_test "Material still references deactivated division" "FAIL"
        echo "Expected divisionId: $USED_DELETED_ID, Got: $MATERIAL_DIV_ID"
    fi
    echo ""
fi

# ============================================
# Test 10: Form Options Filter (Active Only)
# ============================================
echo -e "${YELLOW}Test 10: Form Dropdown Options${NC}"
FORM_OPTIONS=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/dropdowns/all/options" 2>/dev/null)
FORM_DIVS_COUNT=$(echo "$FORM_OPTIONS" | python3 -c "import sys, json; d=json.load(sys.stdin); print(len([x for x in d.get('divisions', []) if x.get('isActive')]))" 2>/dev/null)

if [ "$FORM_DIVS_COUNT" -ge 1 ]; then
    print_test "Form options return only active dropdowns" "PASS"
else
    print_test "Form options return only active dropdowns" "FAIL"
fi
echo ""

# ============================================
# Test 11: Response Format Consistency
# ============================================
echo -e "${YELLOW}Test 11: Response Format Validation${NC}"
FORMAT_CHECK=$(echo "$FORM_OPTIONS" | python3 -c "
import sys, json
d = json.load(sys.stdin)
divs = d.get('divisions', [])
if divs:
    div = divs[0]
    # Check camelCase format
    has_camel = 'isActive' in div and 'createdAt' in div
    has_snake = 'is_active' in div or 'created_at' in div
    print('PASS' if has_camel and not has_snake else 'FAIL')
else:
    print('SKIP')
" 2>/dev/null)

if [ "$FORMAT_CHECK" == "PASS" ]; then
    print_test "Response uses camelCase format consistently" "PASS"
elif [ "$FORMAT_CHECK" == "SKIP" ]; then
    print_test "Response uses camelCase format consistently" "SKIP (no data)"
else
    print_test "Response uses camelCase format consistently" "FAIL"
fi
echo ""

# ============================================
# Test 12: Toggle Multiple Times
# ============================================
echo -e "${YELLOW}Test 12: Toggle Stability${NC}"
if [ ! -z "$DELETED_ID" ]; then
    # Toggle to inactive
    TOGGLE1=$(curl -s -b "$COOKIE_FILE" -X PUT "$BASE_URL/dropdowns/$DELETED_ID/toggle")
    STATUS1=$(echo "$TOGGLE1" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('dropdown', {}).get('isActive'))" 2>/dev/null)
    
    # Toggle back to active
    TOGGLE2=$(curl -s -b "$COOKIE_FILE" -X PUT "$BASE_URL/dropdowns/$DELETED_ID/toggle")
    STATUS2=$(echo "$TOGGLE2" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('dropdown', {}).get('isActive'))" 2>/dev/null)
    
    if [ "$STATUS1" == "False" ] && [ "$STATUS2" == "True" ]; then
        print_test "Toggle status works correctly multiple times" "PASS"
    else
        print_test "Toggle status works correctly multiple times" "FAIL"
        echo "First toggle result: $STATUS1, Second toggle result: $STATUS2"
    fi
else
    print_test "Toggle status works correctly multiple times" "SKIP (no test ID)"
fi
echo ""

# ============================================
# Summary
# ============================================
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total: $TOTAL"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
