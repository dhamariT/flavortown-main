#!/bin/bash
# Test script for email endpoints

echo "🧪 Email Service Endpoint Tests"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if server is running
echo "📡 Checking if server is running..."
if ! curl -s http://localhost:3000/up > /dev/null 2>&1; then
    echo -e "${RED}❌ Server is not running!${NC}"
    echo "Please start the server with: bin/dev"
    exit 1
fi
echo -e "${GREEN}✓ Server is running${NC}"
echo ""

# Test 1: Send test email
echo "📧 Test 1: Sending test email..."
echo "--------------------------------"
response=$(curl -s -X POST http://localhost:3000/emails/test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@buildboard.com",
    "subject": "Test Email from Buildboard"
  }')

echo "Response: $response"
if echo "$response" | grep -q '"success":true'; then
    echo -e "${GREEN}✓ Test email sent successfully${NC}"
else
    echo -e "${RED}❌ Test email failed${NC}"
fi
echo ""

# Test 2: Send signup confirmation (requires a user ID)
echo "📧 Test 2: Sending signup confirmation..."
echo "----------------------------------------"
echo -e "${YELLOW}Note: This requires a valid user ID in your database${NC}"
echo "Skipping for now. To test, run:"
echo "curl -X POST http://localhost:3000/emails/test_signup \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"user_id\": 1}'"
echo ""

# Test 3: Check letter_opener
echo "📬 Test 3: Letter Opener (Email Preview)"
echo "----------------------------------------"
echo "Visit: http://localhost:3000/letter_opener"
echo "This will show all emails sent in development mode"
echo ""

echo "================================"
echo -e "${GREEN}✅ Tests complete!${NC}"
echo ""
echo "💡 Tips:"
echo "  - Check emails at: http://localhost:3000/letter_opener"
echo "  - View OpenTelemetry traces in your OTel backend (e.g., Jaeger)"
echo "  - Check Rails logs for detailed output"