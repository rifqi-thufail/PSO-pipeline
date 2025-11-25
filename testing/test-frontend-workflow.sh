#!/bin/bash
echo "=========================================="
echo "FRONTEND WORKFLOW TEST"
echo "=========================================="
echo ""

# 1. Login
echo "1. Testing Login..."
LOGIN_RESPONSE=$(curl -s -c test-cookies.txt -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}')
echo "$LOGIN_RESPONSE" | python3 -m json.tool
echo ""

# 2. Check Auth
echo "2. Testing Auth Check..."
curl -s -b test-cookies.txt http://localhost:5001/api/auth/check | python3 -m json.tool
echo ""

# 3. Get Dashboard Stats
echo "3. Testing Dashboard Stats..."
curl -s -b test-cookies.txt http://localhost:5001/api/dashboard/stats | python3 -m json.tool
echo ""

# 4. Get Materials List
echo "4. Testing Materials List..."
curl -s -b test-cookies.txt "http://localhost:5001/api/materials?page=1&limit=5" | python3 -m json.tool
echo ""

# 5. Get Material with Images
echo "5. Testing Get Material with Images (ID=1)..."
MATERIAL=$(curl -s -b test-cookies.txt http://localhost:5001/api/materials/1)
echo "$MATERIAL" | python3 -m json.tool
echo ""

# 6. Check if image URL exists and is accessible
echo "6. Testing Image URL Accessibility..."
IMAGE_URL=$(echo "$MATERIAL" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['images'][0]['url'] if data.get('images') else '')")
if [ -n "$IMAGE_URL" ]; then
  echo "Image URL: $IMAGE_URL"
  IMAGE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5001$IMAGE_URL")
  echo "HTTP Status: $IMAGE_STATUS"
  if [ "$IMAGE_STATUS" = "200" ]; then
    echo "✅ Image is accessible!"
  else
    echo "❌ Image not accessible"
  fi
else
  echo "No images found"
fi
echo ""

# 7. Get Dropdowns
echo "7. Testing Dropdowns..."
curl -s -b test-cookies.txt http://localhost:5001/api/dropdowns/all/options | python3 -m json.tool | head -30
echo ""

# 8. Search Materials
echo "8. Testing Search Functionality..."
curl -s -b test-cookies.txt "http://localhost:5001/api/materials?search=laptop" | python3 -m json.tool
echo ""

echo "=========================================="
echo "WORKFLOW TEST COMPLETED"
echo "=========================================="

rm -f test-cookies.txt
