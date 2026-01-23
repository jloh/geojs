#!/bin/bash
# Download MaxMind GeoLite2 databases
set -e

if [ -z "$MAXMIND_ACCOUNT_ID" ] || [ -z "$MAXMIND_LICENSE_KEY" ]; then
    echo "Error: MAXMIND_ACCOUNT_ID and MAXMIND_LICENSE_KEY must be set"
    echo "Get free credentials at: https://www.maxmind.com/en/geolite2/signup"
    exit 1
fi

echo "Configuring geoipupdate..."
cat > /etc/GeoIP.conf << EOF
EditionIDs GeoLite2-City GeoLite2-Country GeoLite2-ASN
AccountID $MAXMIND_ACCOUNT_ID
LicenseKey $MAXMIND_LICENSE_KEY
EOF

echo "Config file contents:"
cat /etc/GeoIP.conf

echo "Downloading MaxMind databases..."
geoipupdate -v

echo "Databases downloaded successfully to /var/lib/GeoIP"
ls -la /var/lib/GeoIP/

if [ -n "$MAXMIND_LUA_URL" ]; then
    echo "Downloading MaxMind ASN Lua module..."
    mkdir -p /opt/geojs/lib/resty
    curl -s -o /opt/geojs/lib/resty/maxminddb_asn.lua "$MAXMIND_LUA_URL"
fi

echo "Setup complete!"
