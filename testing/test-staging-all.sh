#!/bin/bash
# Complete Staging Environment Test Script
# Tests: Correlation, Consistency, Frontend Workflow, Soft Delete

STAGING_URL="http://13.212.157.243:5001/api"
COOKIE_FILE="staging-cookies.txt"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_PASSED=0
TOTAL_FAILED=0

print_test() {
    local test_name="$1"
    local result="$2"
    if [ "$result" == "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TOTAL_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TOTAL_FAILED++))
    fi
}

print_header() {
    echo -e "\n${CYAN}════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "${YELLOW}► $1${NC}"
}

# ============================================
# SETUP: Check Connectivity & Login
# ============================================
print_header "STAGING ENVIRONMENT TESTS"
echo -e "Target: ${BLUE}$STAGING_URL${NC}\n"

print_section "Setup: Checking Connectivity"
HEALTH=$(curl -s --max-time 5 "http://13.212.157.243:5001" 2>/dev/null)
if echo "$HEALTH" | grep -q "Material Management API"; then
    print_test "Backend reachable" "PASS"
else
    print_test "Backend reachable" "FAIL"
    echo -e "${RED}Cannot reach staging backend. Exiting.${NC}"
    exit 1
fi

print_section "Setup: Authentication"
# Try staging test user first
LOGIN=$(curl -s -X POST "$STAGING_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"staging@test.com","password":"staging123"}' \
    -c "$COOKIE_FILE" 2>/dev/null)

if echo "$LOGIN" | grep -q '"success":true'; then
    print_test "Login successful" "PASS"
else
    # Try creating test user if doesn't exist
    echo "Registering staging test user..."
    REGISTER=$(curl -s -X POST "$STAGING_URL/auth/register" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test Staging","email":"staging@test.com","password":"staging123"}' 2>/dev/null)
    
    LOGIN=$(curl -s -X POST "$STAGING_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"staging@test.com","password":"staging123"}' \
        -c "$COOKIE_FILE" 2>/dev/null)
    
    if echo "$LOGIN" | grep -q '"success":true'; then
        print_test "Login successful (after registration)" "PASS"
    else
        print_test "Login successful" "FAIL"
        echo "Response: $LOGIN"
        exit 1
    fi
fi

# ============================================
# TEST SECTION 1: FRONTEND WORKFLOW
# ============================================
print_header "1. FRONTEND WORKFLOW TESTS"

print_section "Auth Check"
AUTH_CHECK=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/auth/check" 2>/dev/null)
if echo "$AUTH_CHECK" | grep -q '"isAuthenticated":true'; then
    print_test "Auth check returns authenticated" "PASS"
else
    print_test "Auth check returns authenticated" "FAIL"
fi

print_section "Dashboard Stats"
DASHBOARD=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/dashboard/stats" 2>/dev/null)
if echo "$DASHBOARD" | grep -q 'totalMaterials'; then
    print_test "Dashboard stats accessible" "PASS"
    DASH_TOTAL=$(echo "$DASHBOARD" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('totalMaterials', 0))" 2>/dev/null)
    echo "  → Total Materials: $DASH_TOTAL"
else
    print_test "Dashboard stats accessible" "FAIL"
fi

print_section "Materials List"
MATERIALS=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/materials?page=1&limit=5" 2>/dev/null)
if echo "$MATERIALS" | grep -q 'materials'; then
    print_test "Materials list accessible" "PASS"
    MAT_COUNT=$(echo "$MATERIALS" | python3 -c "import sys, json; d=json.load(sys.stdin); print(len(d.get('materials', [])))" 2>/dev/null)
    echo "  → Materials returned: $MAT_COUNT"
else
    print_test "Materials list accessible" "FAIL"
fi

print_section "Dropdowns"
DROPDOWNS=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/dropdowns/all/options" 2>/dev/null)
if echo "$DROPDOWNS" | grep -q 'divisions\|placements\|statuses'; then
    print_test "Dropdowns accessible" "PASS"
else
    print_test "Dropdowns accessible" "FAIL"
fi

# ============================================
# TEST SECTION 2: DATA CORRELATION
# ============================================
print_header "2. DATA CORRELATION TESTS"

print_section "Dashboard Total vs Materials Total"
DASH_TOTAL=$(echo "$DASHBOARD" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('totalMaterials', 0))" 2>/dev/null)
MAT_TOTAL=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/materials?page=1&limit=1" 2>/dev/null | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('total', 0))" 2>/dev/null)

if [ "$DASH_TOTAL" == "$MAT_TOTAL" ]; then
    print_test "Dashboard totalMaterials ($DASH_TOTAL) = Materials total ($MAT_TOTAL)" "PASS"
else
    print_test "Dashboard totalMaterials ($DASH_TOTAL) = Materials total ($MAT_TOTAL)" "FAIL"
fi

print_section "Dashboard Active Materials"
DASH_ACTIVE=$(echo "$DASHBOARD" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('activeMaterials', 0))" 2>/dev/null)
if [ -n "$DASH_ACTIVE" ] && [ "$DASH_ACTIVE" != "None" ]; then
    print_test "Active materials count available: $DASH_ACTIVE" "PASS"
else
    print_test "Active materials count available" "FAIL"
fi

print_section "Dashboard Divisions vs Dropdown Divisions"
DASH_DIVS=$(echo "$DASHBOARD" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('totalDivisions', 0))" 2>/dev/null)
DROP_DIVS=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/dropdowns/division" 2>/dev/null | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null)

if [ "$DASH_DIVS" == "$DROP_DIVS" ]; then
    print_test "Dashboard divisions ($DASH_DIVS) = Dropdown divisions ($DROP_DIVS)" "PASS"
else
    print_test "Dashboard divisions ($DASH_DIVS) = Dropdown divisions ($DROP_DIVS)" "FAIL"
fi

# ============================================
# TEST SECTION 3: CONSISTENCY (API FORMAT)
# ============================================
print_header "3. CONSISTENCY TESTS (camelCase Format)"

print_section "Material Response Format"
MATERIAL_SAMPLE=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/materials?page=1&limit=1" 2>/dev/null | python3 -c "import sys, json; d=json.load(sys.stdin); mats=d.get('materials',[]); print(json.dumps(mats[0]) if mats else '{}')" 2>/dev/null)

if [ "$MATERIAL_SAMPLE" != "{}" ]; then
    HAS_CAMEL=$(echo "$MATERIAL_SAMPLE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
camel_keys = ['materialName', 'materialNumber', 'divisionId', 'isActive', 'createdAt']
snake_keys = ['material_name', 'material_number', 'division_id', 'is_active', 'created_at']
has_camel = any(k in data for k in camel_keys)
has_snake = any(k in data for k in snake_keys)
print('CAMEL' if has_camel and not has_snake else 'SNAKE' if has_snake else 'UNKNOWN')
" 2>/dev/null)
    
    if [ "$HAS_CAMEL" == "CAMEL" ]; then
        print_test "Material uses camelCase format" "PASS"
    else
        print_test "Material uses camelCase format" "FAIL"
        echo "  → Found: $HAS_CAMEL"
    fi
else
    print_test "Material format check (no materials found)" "PASS"
fi

print_section "Dropdown Response Format"
DROPDOWN_SAMPLE=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/dropdowns/division" 2>/dev/null | python3 -c "import sys, json; d=json.load(sys.stdin); print(json.dumps(d[0]) if d else '{}')" 2>/dev/null)

if [ "$DROPDOWN_SAMPLE" != "{}" ]; then
    HAS_CAMEL=$(echo "$DROPDOWN_SAMPLE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
has_isActive = 'isActive' in data
has_is_active = 'is_active' in data
print('CAMEL' if has_isActive and not has_is_active else 'SNAKE' if has_is_active else 'OK')
" 2>/dev/null)
    
    if [ "$HAS_CAMEL" == "CAMEL" ] || [ "$HAS_CAMEL" == "OK" ]; then
        print_test "Dropdown uses camelCase format" "PASS"
    else
        print_test "Dropdown uses camelCase format" "FAIL"
    fi
else
    print_test "Dropdown format check (no dropdowns found)" "PASS"
fi

# ============================================
# TEST SECTION 4: SOFT DELETE
# ============================================
print_header "4. SOFT DELETE TESTS"

print_section "Get Active Dropdowns"
ACTIVE_DIVS=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/dropdowns/division" 2>/dev/null)
ACTIVE_COUNT=$(echo "$ACTIVE_DIVS" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null)

if [ "$ACTIVE_COUNT" -ge 1 ]; then
    print_test "Active divisions available ($ACTIVE_COUNT found)" "PASS"
    
    # Get first division ID for testing
    DIV_ID=$(echo "$ACTIVE_DIVS" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d[0]['id'] if d else 0)" 2>/dev/null)
    
    if [ "$DIV_ID" -gt 0 ]; then
        print_section "Soft Delete Division (ID=$DIV_ID)"
        DELETE_RESP=$(curl -s -b "$COOKIE_FILE" -X DELETE "$STAGING_URL/dropdowns/$DIV_ID" 2>/dev/null)
        
        if echo "$DELETE_RESP" | grep -q '"success":true'; then
            print_test "Soft delete successful" "PASS"
            
            # Verify not in active list
            print_section "Verify Hidden from Active List"
            AFTER_DELETE=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/dropdowns/division" 2>/dev/null)
            IN_ACTIVE=$(echo "$AFTER_DELETE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(any(x['id']==$DIV_ID for x in d))" 2>/dev/null)
            
            if [ "$IN_ACTIVE" == "False" ]; then
                print_test "Deleted dropdown hidden from active list" "PASS"
            else
                print_test "Deleted dropdown hidden from active list" "FAIL"
            fi
            
            # Verify in all list
            print_section "Verify Still in Database (activeOnly=false)"
            ALL_DIVS=$(curl -s -b "$COOKIE_FILE" "$STAGING_URL/dropdowns/division?activeOnly=false" 2>/dev/null)
            IN_ALL=$(echo "$ALL_DIVS" | python3 -c "import sys, json; d=json.load(sys.stdin); print(any(x['id']==$DIV_ID for x in d))" 2>/dev/null)
            
            if [ "$IN_ALL" == "True" ]; then
                print_test "Soft-deleted dropdown preserved in database" "PASS"
            else
                print_test "Soft-deleted dropdown preserved in database" "FAIL"
            fi
            
            # Reactivate
            print_section "Toggle Reactivate"
            TOGGLE_RESP=$(curl -s -b "$COOKIE_FILE" -X PUT "$STAGING_URL/dropdowns/$DIV_ID/toggle" 2>/dev/null)
            
            if echo "$TOGGLE_RESP" | grep -q '"isActive":true'; then
                print_test "Reactivate dropdown successful" "PASS"
            else
                print_test "Reactivate dropdown successful" "FAIL"
            fi
        else
            print_test "Soft delete successful" "FAIL"
            echo "Response: $DELETE_RESP"
        fi
    fi
else
    print_test "Active divisions available" "FAIL"
    echo "  → No divisions found for soft delete test"
fi

# ============================================
# SUMMARY
# ============================================
print_header "TEST SUMMARY"

TOTAL=$((TOTAL_PASSED + TOTAL_FAILED))
PASS_RATE=0
if [ $TOTAL -gt 0 ]; then
    PASS_RATE=$((TOTAL_PASSED * 100 / TOTAL))
fi

echo -e "Environment: ${BLUE}STAGING (13.212.157.243)${NC}"
echo -e "Total Tests: $TOTAL"
echo -e "Passed: ${GREEN}$TOTAL_PASSED${NC}"
echo -e "Failed: ${RED}$TOTAL_FAILED${NC}"
echo -e "Pass Rate: ${CYAN}$PASS_RATE%${NC}"
echo ""

if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
fi

# Cleanup
rm -f "$COOKIE_FILE"

exit $TOTAL_FAILED
