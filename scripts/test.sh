#!/bin/bash
# Run GeoJS tests locally using Docker
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check for .env file
if [ ! -f .env ]; then
    if [ -z "$MAXMIND_ACCOUNT_ID" ] || [ -z "$MAXMIND_LICENSE_KEY" ]; then
        echo "Error: MaxMind credentials not found."
        echo ""
        echo "Either create a .env file from .env.example:"
        echo "  cp .env.example .env"
        echo "  # Then edit .env with your credentials"
        echo ""
        echo "Or set environment variables:"
        echo "  export MAXMIND_ACCOUNT_ID=your_account_id"
        echo "  export MAXMIND_LICENSE_KEY=your_license_key"
        echo ""
        echo "Get free credentials at: https://www.maxmind.com/en/geolite2/signup"
        exit 1
    fi
else
    # Load .env file
    set -a
    source .env
    set +a
fi

# Check if setup has been run (volume exists regardless of project name prefix)
if ! docker volume ls -q --filter name=geoip-data | grep -q geoip-data; then
    echo "Running first-time setup (downloading MaxMind databases)..."
    docker compose run --rm setup
fi

# Run tests
echo "Running tests..."
docker compose run --rm tests prove -r t "$@"
