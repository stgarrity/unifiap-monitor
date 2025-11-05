#!/bin/bash

# Load environment variables from .env file
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.template to .env and fill in your credentials"
    exit 1
fi

# Source the .env file
export $(grep -v '^#' .env | xargs)

echo "==========================================="
echo "Testing UniFi API Endpoints"
echo "==========================================="
echo "URL: ${UNIFI_URL}"
echo "Username: ${UNIFI_USERNAME}"
echo ""

echo "-------------------------------------------"
echo "Test 1: UniFi OS Login (UDM/UDM-Pro)"
echo "Endpoint: ${UNIFI_URL}/api/auth/login"
echo "-------------------------------------------"
curl -k -v -X POST "${UNIFI_URL}/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${UNIFI_USERNAME}\",\"password\":\"${UNIFI_PASSWORD}\",\"remember\":false}" \
  2>&1 | grep -E "HTTP|< |> " | head -20

echo ""
echo ""
echo "-------------------------------------------"
echo "Test 2: Regular Controller Login"
echo "Endpoint: ${UNIFI_URL}/api/login"
echo "-------------------------------------------"
curl -k -v -X POST "${UNIFI_URL}/api/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${UNIFI_USERNAME}\",\"password\":\"${UNIFI_PASSWORD}\"}" \
  2>&1 | grep -E "HTTP|< |> " | head -20

echo ""
echo ""
echo "-------------------------------------------"
echo "Test 3: Base URL Check"
echo "Endpoint: ${UNIFI_URL}/"
echo "-------------------------------------------"
curl -k -I "${UNIFI_URL}/" 2>&1 | grep -E "HTTP|Location"

echo ""
echo ""
echo "-------------------------------------------"
echo "Test 4: /manage/account/login"
echo "Endpoint: ${UNIFI_URL}/manage/account/login"
echo "-------------------------------------------"
curl -k -v -X POST "${UNIFI_URL}/manage/account/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${UNIFI_USERNAME}\",\"password\":\"${UNIFI_PASSWORD}\"}" \
  2>&1 | grep -E "HTTP|< |> " | head -20

echo ""
echo ""
echo "-------------------------------------------"
echo "Test 5: /api/v2/login"
echo "Endpoint: ${UNIFI_URL}/api/v2/login"
echo "-------------------------------------------"
curl -k -v -X POST "${UNIFI_URL}/api/v2/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${UNIFI_USERNAME}\",\"password\":\"${UNIFI_PASSWORD}\"}" \
  2>&1 | grep -E "HTTP|< |> " | head -20

echo ""
echo ""
echo "==========================================="
echo "Test Complete"
echo "==========================================="
echo ""
echo "Look for 'HTTP/1.1 200' or 'HTTP/2 200' for successful login"
echo "If you see 404, the endpoint doesn't exist"
echo "If you see 401, the credentials are wrong"
