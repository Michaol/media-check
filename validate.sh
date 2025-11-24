#!/bin/bash

# Simple validation script to test basic functionality
# This tests the utility functions without making actual API calls

echo "========================================="
echo " Media Unlock Checker - Validation Test"
echo "========================================="
echo ""

# Source the main script
source ./media-check.sh

echo "Testing utility functions..."
echo ""

# Test 1: UUID generation
echo -n "1. UUID Generation: "
UUID=$(gen_uuid)
if [ -n "$UUID" ]; then
    echo "✓ PASS (Generated: ${UUID:0:8}...)"
else
    echo "✗ FAIL"
fi

# Test 2: IPv4 validation
echo -n "2. IPv4 Validation: "
validate_ip_address "8.8.8.8" > /dev/null 2>&1
if [ $? -eq 4 ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test 3: IPv6 validation
echo -n "3. IPv6 Validation: "
validate_ip_address "2001:4860:4860::8888" > /dev/null 2>&1
if [ $? -eq 6 ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test 4: Invalid IP validation
echo -n "4. Invalid IP Detection: "
validate_ip_address "invalid.ip" > /dev/null 2>&1
if [ $? -eq 1 ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test 5: Proxy validation (valid)
echo -n "5. Proxy Validation (valid): "
validate_proxy "socks5://127.0.0.1:1080" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test 6: Proxy validation (invalid)
echo -n "6. Proxy Validation (invalid): "
validate_proxy "invalid-proxy" > /dev/null 2>&1
if [ $? -eq 1 ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test 7: Color print initialization
echo -n "7. Color Print: "
color_print
if [ -n "$Font_Green" ]; then
    echo -e "${Font_Green}✓ PASS${Font_Suffix}"
else
    echo "✗ FAIL"
fi

echo ""
echo "========================================="
echo " Validation Complete"
echo "========================================="
