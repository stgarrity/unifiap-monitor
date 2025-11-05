#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

echo "==========================================="
echo "Debug AP Matching"
echo "==========================================="
echo ""

# Get current WiFi BSSID
echo "Current WiFi BSSID:"
/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | grep " BSSID"

echo ""
echo "Fetching UniFi APs..."

# Login and get access points
COOKIE_FILE=$(mktemp)

# Login
LOGIN_RESPONSE=$(curl -k -c "$COOKIE_FILE" -X POST "${UNIFI_URL}/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${UNIFI_USERNAME}\",\"password\":\"${UNIFI_PASSWORD}\",\"remember\":false}" \
  -s -w "\nHTTP_STATUS:%{http_code}")

HTTP_STATUS=$(echo "$LOGIN_RESPONSE" | grep HTTP_STATUS | cut -d: -f2)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Login successful"
    echo ""
    
    # Get devices
    DEVICES=$(curl -k -b "$COOKIE_FILE" -X GET "${UNIFI_URL}/proxy/network/api/s/default/stat/device" \
      -H "Content-Type: application/json" -s)
    
    echo "UniFi Access Points (type=uap):"
    echo "$DEVICES" | python3 -c "
import sys
import json
try:
    data = json.load(sys.stdin)
    aps = [d for d in data.get('data', []) if d.get('type') == 'uap']
    for ap in aps:
        mac = ap.get('mac', 'N/A')
        name = ap.get('name', ap.get('model', 'Unknown'))
        normalized = mac.replace(':', '').lower()
        print(f'  Name: {name}')
        print(f'  MAC:  {mac}')
        print(f'  Normalized: {normalized}')
        print()
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    print(sys.stdin.read())
"
else
    echo "❌ Login failed with status: $HTTP_STATUS"
fi

rm -f "$COOKIE_FILE"

echo ""
echo "==========================================="
echo "Compare the BSSID format above!"
echo "==========================================="
