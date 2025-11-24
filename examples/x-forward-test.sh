#!/bin/bash

# Example: X-Forwarded-For Test
# This script demonstrates how to test via X-Forwarded-For header
# WARNING: This method may not work for most streaming services!

echo "========================================="
echo " X-Forwarded-For Test Example"
echo "========================================="
echo ""
echo "WARNING: This method may not work for most streaming services!"
echo "Most services ignore the X-Forwarded-For header for security reasons."
echo ""

# Configure target IP here
TARGET_IP="8.8.8.8"

echo "Target IP: $TARGET_IP"
echo ""

cd "$(dirname "$0")/.."

# Source the main script
source ./media-check.sh

# Validate IP
validate_ip_address "$TARGET_IP"
RESULT=$?

if [ "$RESULT" -ne 4 ] && [ "$RESULT" -ne 6 ]; then
    echo "Invalid IP address!"
    exit 1
fi

# Get IP info
get_ip_info "$TARGET_IP"
echo ""

# Run tests with X-Forwarded-For
CURL_OPTS="--header X-Forwarded-For:$TARGET_IP --max-time 10 --retry 3 --retry-max-time 20"
run_tests "$CURL_OPTS" "X-Forwarded-For (Results may be inaccurate)"
