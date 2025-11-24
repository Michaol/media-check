#!/bin/bash

# Example: Local IP Test
# This script demonstrates how to test your local IP

echo "========================================="
echo " Local IP Test Example"
echo "========================================="
echo ""

# Run the main script with option 1 (Local IP test)
# Note: This is an example. In practice, you would use the interactive menu.

cd "$(dirname "$0")/.."

echo "Running local IP test..."
echo ""

# You can also call the script functions directly if you source it
source ./media-check.sh

# Get local IP
LOCAL_IP=$(get_local_ip)
echo "Local IP: $LOCAL_IP"
echo ""

# Get IP info
get_ip_info "$LOCAL_IP"
echo ""

# Run tests
CURL_OPTS="--max-time 10 --retry 3 --retry-max-time 20"
run_tests "$CURL_OPTS" "Local IP"
