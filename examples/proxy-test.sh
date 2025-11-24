#!/bin/bash

# Example: Proxy Test
# This script demonstrates how to test via a proxy

echo "========================================="
echo " Proxy Test Example"
echo "========================================="
echo ""

# Configure your proxy here
PROXY_URL="socks5://127.0.0.1:1080"

echo "Using proxy: $PROXY_URL"
echo ""

cd "$(dirname "$0")/.."

# Source the main script
source ./media-check.sh

# Validate proxy
if ! validate_proxy "$PROXY_URL"; then
    echo "Invalid proxy address!"
    exit 1
fi

# Get IP via proxy
echo "Getting IP via proxy..."
PROXY_IP=$(curl -x "$PROXY_URL" -s --max-time 5 "https://api64.ipify.org" 2>/dev/null)

if [ -z "$PROXY_IP" ]; then
    echo "Failed to connect via proxy!"
    exit 1
fi

echo "Proxy IP: $PROXY_IP"
echo ""

# Get IP info
get_ip_info "$PROXY_IP"
echo ""

# Run tests via proxy
CURL_OPTS="-x $PROXY_URL --max-time 10 --retry 3 --retry-max-time 20"
run_tests "$CURL_OPTS" "Proxy"
