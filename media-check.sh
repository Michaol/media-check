#!/bin/bash

# Media Unlock Checker
# A simplified tool to check Netflix, Disney+, and HBO Max unlock status
# Based on RegionRestrictionCheck project

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# ============================================
# Color Definitions
# ============================================
color_print() {
    Font_Black="\033[30m"
    Font_Red="\033[31m"
    Font_Green="\033[32m"
    Font_Yellow="\033[33m"
    Font_Blue="\033[34m"
    Font_Purple="\033[35m"
    Font_SkyBlue="\033[36m"
    Font_White="\033[37m"
    Font_Suffix="\033[0m"
}

# Initialize colors
color_print

# ============================================
# Utility Functions
# ============================================

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

gen_uuid() {
    if [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
        return 0
    fi

    if command_exists uuidgen; then
        uuidgen
        return 0
    fi

    if command_exists powershell; then
        powershell -c "[guid]::NewGuid().ToString()"
        return 0
    fi

    echo -e "${Font_Red}Error: Unable to generate UUID${Font_Suffix}"
    return 1
}

validate_ip_address() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Error: IP Address is missing${Font_Suffix}"
        return 1
    fi

    local ip="$1"

    # Check IPv4
    if echo "$ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
        # Validate each octet
        local valid=1
        IFS='.' read -ra OCTETS <<< "$ip"
        for octet in "${OCTETS[@]}"; do
            if [ "$octet" -gt 255 ]; then
                valid=0
                break
            fi
        done
        if [ "$valid" -eq 1 ]; then
            return 4  # IPv4
        fi
    fi

    # Check IPv6
    if echo "$ip" | grep -Eq '^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$|^::([0-9a-fA-F]{0,4}:){0,6}[0-9a-fA-F]{0,4}$|^([0-9a-fA-F]{0,4}:){1,7}:$'; then
        return 6  # IPv6
    fi

    echo -e "${Font_Red}Error: Invalid IP address format${Font_Suffix}"
    return 1
}

validate_proxy() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Error: Proxy address is missing${Font_Suffix}"
        return 1
    fi

    local proxy="$1"

    # Check proxy format: protocol://[user:pass@]host:port
    if echo "$proxy" | grep -Eq '^(socks|socks4|socks5|http|https)://([^:]+:[^@]+@)?([0-9a-fA-F.:]+|[a-zA-Z0-9.-]+):[0-9]{1,5}$'; then
        return 0
    fi

    echo -e "${Font_Red}Error: Invalid proxy format${Font_Suffix}"
    echo -e "${Font_Yellow}Expected format: protocol://[user:pass@]host:port${Font_Suffix}"
    echo -e "${Font_Yellow}Example: socks5://127.0.0.1:1080 or http://user:pass@proxy.com:8080${Font_Suffix}"
    return 1
}

check_dependencies() {
    echo -e "${Font_Blue}Checking dependencies...${Font_Suffix}"
    
    local missing_deps=0

    # Check curl
    if ! command_exists curl; then
        echo -e "${Font_Red}✗ curl is missing${Font_Suffix}"
        missing_deps=1
    else
        echo -e "${Font_Green}✓ curl${Font_Suffix}"
    fi

    # Check grep with Perl regex support
    if ! echo 'test' | grep -P 'test' > /dev/null 2>&1; then
        echo -e "${Font_Red}✗ grep (with Perl regex support) is missing or incomplete${Font_Suffix}"
        missing_deps=1
    else
        echo -e "${Font_Green}✓ grep${Font_Suffix}"
    fi

    # Check sed
    if ! command_exists sed; then
        echo -e "${Font_Red}✗ sed is missing${Font_Suffix}"
        missing_deps=1
    else
        echo -e "${Font_Green}✓ sed${Font_Suffix}"
    fi

    # Check awk
    if ! command_exists awk; then
        echo -e "${Font_Red}✗ awk is missing${Font_Suffix}"
        missing_deps=1
    else
        echo -e "${Font_Green}✓ awk${Font_Suffix}"
    fi

    # Check UUID generation
    if ! gen_uuid > /dev/null 2>&1; then
        echo -e "${Font_Red}✗ UUID generation (uuidgen or /proc/sys/kernel/random/uuid) is missing${Font_Suffix}"
        missing_deps=1
    else
        echo -e "${Font_Green}✓ UUID generation${Font_Suffix}"
    fi

    if [ "$missing_deps" -eq 1 ]; then
        echo ""
        echo -e "${Font_Red}Please install missing dependencies first.${Font_Suffix}"
        echo ""
        echo -e "${Font_Yellow}Ubuntu/Debian:${Font_Suffix}"
        echo "  sudo apt update && sudo apt install curl grep sed gawk uuid-runtime"
        echo ""
        echo -e "${Font_Yellow}RHEL/CentOS/Fedora:${Font_Suffix}"
        echo "  sudo dnf install curl grep sed gawk util-linux"
        echo ""
        echo -e "${Font_Yellow}macOS:${Font_Suffix}"
        echo "  brew install grep coreutils"
        echo ""
        return 1
    fi

    echo -e "${Font_Green}All dependencies are satisfied!${Font_Suffix}"
    return 0
}

# ============================================
# Network Functions
# ============================================

get_local_ip() {
    local ip=$(curl -s --max-time 5 "${IP_QUERY_API}" 2>/dev/null)
    if [ -z "$ip" ]; then
        echo -e "${Font_Red}Error: Failed to get local IP${Font_Suffix}"
        return 1
    fi
    echo "$ip"
    return 0
}

get_local_ip_v6() {
    local ip=$(curl -6 -s --max-time 5 "${IP_QUERY_API_V6}" 2>/dev/null)
    if [ -z "$ip" ]; then
        return 1
    fi
    echo "$ip"
    return 0
}

detect_network_type() {
    local ipv4_available=0
    local ipv6_available=0
    
    # Check IPv4
    if get_local_ip >/dev/null 2>&1; then
        ipv4_available=1
    fi
    
    # Check IPv6
    if [ "$ENABLE_IPV6" == "1" ]; then
        if get_local_ip_v6 >/dev/null 2>&1; then
            ipv6_available=1
        fi
    fi
    
    if [ "$ipv4_available" == "1" ] && [ "$ipv6_available" == "1" ]; then
        echo "dual"
    elif [ "$ipv4_available" == "1" ]; then
        echo "ipv4"
    elif [ "$ipv6_available" == "1" ]; then
        echo "ipv6"
    else
        echo "none"
    fi
}


get_ip_info() {
    local ip="$1"
    if [ -z "$ip" ]; then
        echo -e "${Font_Red}Error: IP address is required${Font_Suffix}"
        return 1
    fi

    local info=$(curl -s --max-time 5 "${IP_INFO_API}/${ip}" 2>/dev/null)
    if [ -z "$info" ]; then
        echo -e "${Font_Red}Error: Failed to get IP info${Font_Suffix}"
        return 1
    fi

    local country=$(echo "$info" | grep -oP '"country_code"\s*:\s*"\K[^"]+' 2>/dev/null)
    local isp=$(echo "$info" | grep -oP '"organization"\s*:\s*"\K[^"]+' 2>/dev/null)
    local city=$(echo "$info" | grep -oP '"city"\s*:\s*"\K[^"]+' 2>/dev/null)

    echo "Country: ${country:-Unknown}"
    echo "ISP: ${isp:-Unknown}"
    echo "City: ${city:-Unknown}"
    return 0
}

download_disney_cookie() {
    # Create cache directory if it doesn't exist
    if [ ! -d "$CACHE_DIR" ]; then
        mkdir -p "$CACHE_DIR" 2>/dev/null
    fi
    
    # Check if cache exists and is valid
    if [ -f "$DISNEY_COOKIE_CACHE" ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$DISNEY_COOKIE_CACHE" 2>/dev/null || stat -f %m "$DISNEY_COOKIE_CACHE" 2>/dev/null || echo 0)))
        if [ "$cache_age" -lt "$CACHE_EXPIRY" ]; then
            DISNEY_COOKIE=$(cat "$DISNEY_COOKIE_CACHE")
            if [ -n "$DISNEY_COOKIE" ]; then
                echo -e "${Font_Green}Using cached Disney+ cookie data${Font_Suffix}"
                return 0
            fi
        fi
    fi
    
    # Use embedded cookie data
    DISNEY_COOKIE="$DISNEY_COOKIE_DATA"
    
    if [ -z "$DISNEY_COOKIE" ]; then
        echo -e "${Font_Red}Error: Disney+ cookie data not available${Font_Suffix}"
        return 1
    fi
    
    # Save to cache
    echo "$DISNEY_COOKIE" > "$DISNEY_COOKIE_CACHE" 2>/dev/null
    
    echo -e "${Font_Green}Disney+ cookie data loaded successfully${Font_Suffix}"
    return 0
}


# ============================================
# Streaming Service Detection Functions
# ============================================

test_netflix() {
    local curl_opts="$1"
    local use_ipv6="$2"
    
    echo -n -e " Netflix:\t\t\t"
    
    # Add IPv6 flag if needed
    if [ "$use_ipv6" == "1" ]; then
        curl_opts="-6 $curl_opts"
    fi

    # Test 1: LEGO Ninjago (Originals)
    local result1=$(curl ${curl_opts} -fsL "${NETFLIX_TEST_URL_1}" \
        -w "\n%{http_code}" \
        -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
        -H 'accept-language: en-US,en;q=0.9' \
        -b "${NETFLIX_COOKIE}" \
        -H "sec-ch-ua: ${UA_SEC_CH_UA}" \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' \
        --user-agent "${UA_BROWSER}" 2>/dev/null)
    
    local http_code1=$(echo "$result1" | tail -n1)
    local content1=$(echo "$result1" | sed '$d')

    # Test 2: Breaking Bad (Regional content)
    local result2=$(curl ${curl_opts} -fsL "${NETFLIX_TEST_URL_2}" \
        -w "\n%{http_code}" \
        -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
        -H 'accept-language: en-US,en;q=0.9' \
        -b "${NETFLIX_COOKIE}" \
        -H "sec-ch-ua: ${UA_SEC_CH_UA}" \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' \
        --user-agent "${UA_BROWSER}" 2>/dev/null)
    
    local http_code2=$(echo "$result2" | tail -n1)
    local content2=$(echo "$result2" | sed '$d')

    # Check for network errors
    if [ "$http_code1" == "000" ] || [ "$http_code2" == "000" ]; then
        echo -e "${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi
    
    # Check for HTTP errors
    if [ "$http_code1" == "403" ] && [ "$http_code2" == "403" ]; then
        echo -e "${Font_Red}No (IP Blocked)${Font_Suffix}"
        return
    fi

    local blocked1=$(echo "$content1" | grep 'Oh no!')
    local blocked2=$(echo "$content2" | grep 'Oh no!')

    if [ -n "$blocked1" ] && [ -n "$blocked2" ]; then
        echo -e "${Font_Yellow}Originals Only${Font_Suffix}"
        return
    fi

    if [ -z "$blocked1" ] || [ -z "$blocked2" ]; then
        local region=$(echo "$content1" | grep -oP 'data-country="\K[A-Z]{2}' | head -n1)
        if [ -z "$region" ]; then
            region=$(echo "$content2" | grep -oP 'data-country="\K[A-Z]{2}' | head -n1)
        fi
        
        if [ -n "$region" ]; then
            echo -e "${Font_Green}Yes (Region: ${region})${Font_Suffix}"
        else
            echo -e "${Font_Green}Yes${Font_Suffix}"
        fi
        return
    fi

    echo -e "${Font_Red}Failed (Unknown Error)${Font_Suffix}"
}


test_disneyplus() {
    local curl_opts="$1"
    local use_ipv6="$2"
    
    echo -n -e " Disney+:\t\t\t"
    
    # Add IPv6 flag if needed
    if [ "$use_ipv6" == "1" ]; then
        curl_opts="-6 $curl_opts"
    fi

    if [ -z "$DISNEY_COOKIE" ]; then
        echo -e "${Font_Red}Failed (Cookie data not available)${Font_Suffix}"
        return
    fi

    # Step 1: Device registration
    local device_resp=$(curl ${curl_opts} -s "${DISNEY_DEVICE_API}" \
        -X POST \
        -H "authorization: Bearer ${DISNEY_BEARER_TOKEN}" \
        -H "content-type: application/json; charset=UTF-8" \
        -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' \
        --user-agent "${UA_BROWSER}" 2>/dev/null)

    if [ -z "$device_resp" ]; then
        echo -e "${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi

    local is403=$(echo "$device_resp" | grep -i '403 ERROR')
    if [ -n "$is403" ]; then
        echo -e "${Font_Red}No (IP Banned)${Font_Suffix}"
        return
    fi

    local assertion=$(echo "$device_resp" | grep -oP '"assertion"\s*:\s*"\K[^"]+')
    if [ -z "$assertion" ]; then
        echo -e "${Font_Red}Failed (Device Registration Error)${Font_Suffix}"
        return
    fi

    # Step 2: Get token
    local pre_cookie=$(echo "$DISNEY_COOKIE" | sed -n '1p')
    local cookie_data=$(echo "$pre_cookie" | sed "s/DISNEYASSERTION/${assertion}/g")
    
    local token_resp=$(curl ${curl_opts} -s "${DISNEY_TOKEN_API}" \
        -X POST \
        -H "authorization: Bearer ${DISNEY_BEARER_TOKEN}" \
        -d "${cookie_data}" \
        --user-agent "${UA_BROWSER}" 2>/dev/null)

    local is_blocked=$(echo "$token_resp" | grep -i 'forbidden-location')
    local is403=$(echo "$token_resp" | grep -i '403 ERROR')

    if [ -n "$is_blocked" ] || [ -n "$is403" ]; then
        echo -e "${Font_Red}No (IP Banned)${Font_Suffix}"
        return
    fi

    local refresh_token=$(echo "$token_resp" | grep -oP '"refresh_token"\s*:\s*"\K[^"]+')
    if [ -z "$refresh_token" ]; then
        echo -e "${Font_Red}Failed (Token Error)${Font_Suffix}"
        return
    fi

    # Step 3: Query region
    local fake_content=$(echo "$DISNEY_COOKIE" | sed -n '8p')
    local graph_data=$(echo "$fake_content" | sed "s/ILOVEDISNEY/${refresh_token}/g")
    
    local region_resp=$(curl ${curl_opts} -sL "${DISNEY_GRAPH_API}" \
        -X POST \
        -H "authorization: ${DISNEY_BEARER_TOKEN}" \
        -d "${graph_data}" \
        --user-agent "${UA_BROWSER}" 2>/dev/null)

    # Step 4: Check availability
    local preview_check=$(curl ${curl_opts} -sL "${DISNEY_HOME_URL}" \
        -w '%{url_effective}\n' -o /dev/null \
        --user-agent "${UA_BROWSER}" 2>/dev/null)
    
    local is_unavailable=$(echo "$preview_check" | grep -E 'preview|unavailable')
    local country=$(echo "$region_resp" | grep -oP '"countryCode"\s*:\s*"\K[^"]+')
    local supported=$(echo "$region_resp" | grep -oP '"inSupportedLocation"\s*:\s*\K(true|false)')

    if [ -z "$country" ]; then
        echo -e "${Font_Red}No${Font_Suffix}"
        return
    fi

    if [ -n "$is_unavailable" ]; then
        echo -e "${Font_Red}No${Font_Suffix}"
        return
    fi

    if [ "$supported" == "false" ]; then
        echo -e "${Font_Yellow}Available For [Disney+ ${country}] Soon${Font_Suffix}"
        return
    fi

    if [ "$supported" == "true" ]; then
        echo -e "${Font_Green}Yes (Region: ${country})${Font_Suffix}"
        return
    fi

    echo -e "${Font_Red}Failed (Unknown Error)${Font_Suffix}"
}

test_hbomax() {
    local curl_opts="$1"
    local use_ipv6="$2"
    
    echo -n -e " HBO Max:\t\t\t"
    
    # Add IPv6 flag if needed
    if [ "$use_ipv6" == "1" ]; then
        curl_opts="-6 $curl_opts"
    fi

    local resp=$(curl ${curl_opts} -sLi "${HBOMAX_HOME_URL}" \
        -w "_TAG_%{http_code}_TAG_" \
        --user-agent "${UA_BROWSER}" 2>/dev/null)

    local http_code=$(echo "$resp" | grep '_TAG_' | awk -F'_TAG_' '{print $2}')
    
    if [ "$http_code" == "000" ]; then
        echo -e "${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi

    # Extract supported countries
    local countries=$(echo "$resp" | grep -oP '"url":"/[a-z]{2}/[a-z]{2}"' | \
        cut -f4 -d'"' | cut -f2 -d'/' | sort -u | tr '\n' ' ' | tr 'a-z' 'A-Z')

    # Extract current region
    local region=$(echo "$resp" | grep -oP 'countryCode=\K[A-Z]{2}' | head -n1)

    if [ -z "$region" ]; then
        echo -e "${Font_Red}Failed (Country Code Not Found)${Font_Suffix}"
        return
    fi

    if echo "$countries" | grep -q "$region"; then
        echo -e "${Font_Green}Yes (Region: ${region})${Font_Suffix}"
        return
    fi

    echo -e "${Font_Red}No${Font_Suffix}"
}

# ============================================
# Test Execution Functions
# ============================================

run_tests() {
    local curl_opts="$1"
    local test_type="$2"
    local use_ipv6="${3:-0}"  # Default to IPv4
    
    echo ""
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo -e "${Font_Blue} Running Tests (${test_type})${Font_Suffix}"
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    
    test_netflix "$curl_opts" "$use_ipv6"
    test_disneyplus "$curl_opts" "$use_ipv6"
    test_hbomax "$curl_opts" "$use_ipv6"
    
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo ""
}

# ============================================
# Main Menu and Control
# ============================================

show_menu() {
    clear
    
    # Detect network type
    local network_type=$(detect_network_type)
    local network_info=""
    
    case "$network_type" in
        "dual")
            network_info="${Font_Green}IPv4 + IPv6 (Dual Stack)${Font_Suffix}"
            ;;
        "ipv4")
            network_info="${Font_Blue}IPv4 Only${Font_Suffix}"
            ;;
        "ipv6")
            network_info="${Font_Blue}IPv6 Only${Font_Suffix}"
            ;;
        "none")
            network_info="${Font_Red}No Network${Font_Suffix}"
            ;;
    esac
    
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo -e "${Font_Blue}  Media Unlock Checker v${VERSION}${Font_Suffix}"
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo ""
    echo -e " Network: ${network_info}"
    echo ""
    echo " 1. Check Local IP (IPv4)"
    if [ "$network_type" == "dual" ] || [ "$network_type" == "ipv6" ]; then
        echo " 2. Check Local IP (IPv6)"
        echo " 3. Check via Proxy (Recommended)"
        echo " 4. Check via X-Forwarded-For (May not work)"
        echo " 5. Check Dependencies"
        echo " 6. Exit"
    else
        echo " 2. Check via Proxy (Recommended)"
        echo " 3. Check via X-Forwarded-For (May not work)"
        echo " 4. Check Dependencies"
        echo " 5. Exit"
    fi
    echo ""
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    
    if [ "$network_type" == "dual" ] || [ "$network_type" == "ipv6" ]; then
        echo -n "Please select [1-6]: "
    else
        echo -n "Please select [1-5]: "
    fi
}

run_local_test() {
    echo ""
    echo -e "${Font_Blue}Getting local IP information...${Font_Suffix}"
    
    local ip=$(get_local_ip)
    if [ $? -ne 0 ]; then
        echo -e "${Font_Red}Failed to get local IP${Font_Suffix}"
        return 1
    fi
    
    echo -e "${Font_Green}Local IP: ${ip}${Font_Suffix}"
    echo ""
    
    get_ip_info "$ip"
    
    local curl_opts="--max-time ${DEFAULT_TIMEOUT} --retry ${DEFAULT_RETRY} --retry-max-time ${DEFAULT_MAX_TIME}"
    
    run_tests "$curl_opts" "Local IP (IPv4)" 0
}

run_local_test_v6() {
    echo ""
    echo -e "${Font_Blue}Getting local IPv6 information...${Font_Suffix}"
    
    local ip=$(get_local_ip_v6)
    if [ $? -ne 0 ]; then
        echo -e "${Font_Red}Failed to get local IPv6 address${Font_Suffix}"
        echo -n "Press Enter to continue..."
        read
        return 1
    fi
    
    echo -e "${Font_Green}Local IPv6: ${ip}${Font_Suffix}"
    echo ""
    
    get_ip_info "$ip"
    
    local curl_opts="--max-time ${DEFAULT_TIMEOUT} --retry ${DEFAULT_RETRY} --retry-max-time ${DEFAULT_MAX_TIME}"
    
    run_tests "$curl_opts" "Local IP (IPv6)" 1
}

run_proxy_test() {
    echo ""
    echo -e "${Font_Yellow}Proxy format examples:${Font_Suffix}"
    echo "  socks5://127.0.0.1:1080"
    echo "  http://proxy.example.com:8080"
    echo "  socks5://user:pass@proxy.example.com:1080"
    echo ""
    echo -n "Enter proxy address (or 'q' to quit): "
    read proxy_addr
    
    if [ "$proxy_addr" == "q" ] || [ "$proxy_addr" == "Q" ]; then
        return 0
    fi
    
    if ! validate_proxy "$proxy_addr"; then
        echo ""
        echo -e "${Font_Red}Invalid proxy address${Font_Suffix}"
        echo -n "Press Enter to continue..."
        read
        return 1
    fi
    
    echo ""
    echo -e "${Font_Blue}Testing proxy connection...${Font_Suffix}"
    
    local test_ip=$(curl -x "$proxy_addr" -s --max-time 5 "${IP_QUERY_API}" 2>/dev/null)
    if [ -z "$test_ip" ]; then
        echo -e "${Font_Red}Failed to connect via proxy${Font_Suffix}"
        echo -n "Press Enter to continue..."
        read
        return 1
    fi
    
    echo -e "${Font_Green}Proxy IP: ${test_ip}${Font_Suffix}"
    echo ""
    
    get_ip_info "$test_ip"
    
    local curl_opts="-x $proxy_addr --max-time ${DEFAULT_TIMEOUT} --retry ${DEFAULT_RETRY} --retry-max-time ${DEFAULT_MAX_TIME}"
    
    run_tests "$curl_opts" "Proxy"
}

run_xforward_test() {
    echo ""
    echo -e "${Font_Yellow}WARNING: X-Forwarded-For method may not work for most streaming services!${Font_Suffix}"
    echo -e "${Font_Yellow}Most services ignore this header for security reasons.${Font_Suffix}"
    echo ""
    echo -n "Enter target IP address (or 'q' to quit): "
    read target_ip
    
    if [ "$target_ip" == "q" ] || [ "$target_ip" == "Q" ]; then
        return 0
    fi
    
    validate_ip_address "$target_ip"
    local result=$?
    
    if [ "$result" -ne 4 ] && [ "$result" -ne 6 ]; then
        echo -e "${Font_Red}Invalid IP address${Font_Suffix}"
        echo -n "Press Enter to continue..."
        read
        return 1
    fi
    
    echo ""
    echo -e "${Font_Blue}Target IP: ${target_ip}${Font_Suffix}"
    echo ""
    
    get_ip_info "$target_ip"
    
    local curl_opts="--header X-Forwarded-For:$target_ip --max-time ${DEFAULT_TIMEOUT} --retry ${DEFAULT_RETRY} --retry-max-time ${DEFAULT_MAX_TIME}"
    
    run_tests "$curl_opts" "X-Forwarded-For (Results may be inaccurate)"
}

main() {
    # Check for --check-deps flag
    if [ "$1" == "--check-deps" ] || [ "$1" == "-c" ]; then
        check_dependencies
        exit $?
    fi

    # Check dependencies first
    if ! check_dependencies; then
        exit 1
    fi

    # Download Disney+ cookie data
    download_disney_cookie

    # Main loop
    while true; do
        show_menu
        read choice
        
        # Detect network type for dynamic menu handling
        local network_type=$(detect_network_type)
        
        # Handle menu based on network type
        if [ "$network_type" == "dual" ] || [ "$network_type" == "ipv6" ]; then
            # Dual stack or IPv6 only menu (6 options)
            case $choice in
                1)
                    run_local_test
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                2)
                    run_local_test_v6
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                3)
                    run_proxy_test
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                4)
                    run_xforward_test
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                5)
                    check_dependencies
                    echo ""
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                6)
                    echo ""
                    echo -e "${Font_Green}Goodbye!${Font_Suffix}"
                    echo ""
                    exit 0
                    ;;
                *)
                    echo ""
                    echo -e "${Font_Red}Invalid selection${Font_Suffix}"
                    echo -n "Press Enter to continue..."
                    read
                    ;;
            esac
        else
            # IPv4 only menu (5 options)
            case $choice in
                1)
                    run_local_test
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                2)
                    run_proxy_test
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                3)
                    run_xforward_test
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                4)
                    check_dependencies
                    echo ""
                    echo -n "Press Enter to continue..."
                    read
                    ;;
                5)
                    echo ""
                    echo -e "${Font_Green}Goodbye!${Font_Suffix}"
                    echo ""
                    exit 0
                    ;;
                *)
                    echo ""
                    echo -e "${Font_Red}Invalid selection${Font_Suffix}"
                    echo -n "Press Enter to continue..."
                    read
                    ;;
            esac
        fi
    done
}

# Run main function
main "$@"
