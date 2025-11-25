#!/bin/bash

# Media Unlock Checker
# A simplified tool to check Netflix, Disney+, and HBO Max unlock status
# Based on RegionRestrictionCheck project

# ============================================
# Auto-download config.sh for one-click execution
# ============================================

# Detect if running in one-click mode (from stdin/pipe)
if [ ! -t 0 ] || [[ "${BASH_SOURCE[0]}" == */dev/fd/* ]] || [[ "${BASH_SOURCE[0]}" == *bash* ]]; then
    # One-click execution mode - download config.sh
    CONFIG_URL="https://raw.githubusercontent.com/Michaol/media-check/main/config.sh"
    TEMP_CONFIG="/tmp/media-check-config-$$.sh"
    
    echo "Downloading config.sh..."
    if curl -fsSL "$CONFIG_URL" -o "$TEMP_CONFIG" 2>/dev/null; then
        source "$TEMP_CONFIG"
        # Clean up on exit
        trap "rm -f $TEMP_CONFIG" EXIT
    else
        echo "Error: Failed to download config.sh"
        exit 1
    fi
else
    # Local execution mode - load from script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/config.sh" ]; then
        source "${SCRIPT_DIR}/config.sh"
    else
        echo "Error: config.sh not found in ${SCRIPT_DIR}"
        exit 1
    fi
fi

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
color_print

# ============================================
# Utility Functions
# ============================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

gen_uuid() {
    if command_exists uuidgen; then
        uuidgen
    elif [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
    else
        # Fallback UUID generation
        echo "$(date +%s)-$(od -x /dev/urandom | head -1 | awk '{print $2$3$4$5}')"
    fi
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

    # Parse ip-api.com format (countryCode, isp, city)
    local country=$(echo "$info" | grep -oP '"countryCode"\s*:\s*"\K[^"]+' 2>/dev/null)
    local isp=$(echo "$info" | grep -oP '"isp"\s*:\s*"\K[^"]+' 2>/dev/null)
    local city=$(echo "$info" | grep -oP '"city"\s*:\s*"\K[^"]+' 2>/dev/null)

    echo "Country: ${country:-Unknown}"
    echo "ISP: ${isp:-Unknown}"
    echo "City: ${city:-Unknown}"
    return 0
}

detect_network_interfaces() {
    if command -v ip >/dev/null 2>&1; then
        # Get all interfaces (excluding lo)
        ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' | sort -u
    elif command -v ifconfig >/dev/null 2>&1; then
        # Get all interfaces (excluding lo)
        ifconfig | awk '/^[a-z]/ {iface=$1; gsub(/:/, "", iface); if (iface != "lo") print iface}' | sort -u
    fi
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
                echo -e "${Font_Green}Using cached Disney+ cookie data (age: $((cache_age / 3600))h)${Font_Suffix}"
                return 0
            fi
        fi
    fi
    
    # Try to download from external source (latest data)
    echo -e "${Font_Blue}Downloading latest Disney+ cookie data from GitHub...${Font_Suffix}"
    local external_cookie=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies" 2>/dev/null)
    
    if [ -n "$external_cookie" ] && [ ${#external_cookie} -gt 100 ]; then
        # External download successful
        DISNEY_COOKIE="$external_cookie"
        echo "$DISNEY_COOKIE" > "$DISNEY_COOKIE_CACHE" 2>/dev/null
        echo -e "${Font_Green}✓ Downloaded latest Disney+ cookie data from GitHub${Font_Suffix}"
        return 0
    else
        # External download failed, use embedded data as fallback
        echo -e "${Font_Yellow}⚠ Failed to download from GitHub, using embedded cookie data${Font_Suffix}"
        DISNEY_COOKIE="$DISNEY_COOKIE_DATA"
        
        if [ -z "$DISNEY_COOKIE" ]; then
            echo -e "${Font_Red}Error: Disney+ cookie data not available${Font_Suffix}"
            return 1
        fi
        
        # Save embedded data to cache
        echo "$DISNEY_COOKIE" > "$DISNEY_COOKIE_CACHE" 2>/dev/null
        echo -e "${Font_Green}✓ Using embedded Disney+ cookie data (fallback)${Font_Suffix}"
        return 0
    fi
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
        -w "_TAG_%{http_code}" \
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

run_interface_test() {
    local interface="$1"
    
    echo ""
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo -e "${Font_Blue} Testing Interface: ${Font_Yellow}$interface${Font_Suffix}"
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo ""
    
    # Get IPv4 address for this interface
    local ipv4=""
    # Strip any '@' suffix from interface name for ip/ifconfig commands
    local iface_base="${interface%%@*}"
    if command -v ip >/dev/null 2>&1; then
        ipv4=$(ip -4 addr show "$iface_base" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
    elif command -v ifconfig >/dev/null 2>&1; then
        ipv4=$(ifconfig "$iface_base" 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -1)
    fi
    
    # Get IPv6 address for this interface
    local ipv6=""
    if command -v ip >/dev/null 2>&1; then
        ipv6=$(ip -6 addr show "$iface_base" 2>/dev/null | grep -oP 'inet6 \K[0-9a-f:]+' | grep -v '^fe80' | head -1)
    elif command -v ifconfig >/dev/null 2>&1; then
        ipv6=$(ifconfig "$iface_base" 2>/dev/null | grep 'inet6 ' | awk '{print $2}' | grep -v '^fe80' | head -1)
    fi
    
    # Test IPv4 if available
    if [ -n "$ipv4" ]; then
        echo -e "${Font_Blue}[IPv4 Test]${Font_Suffix}"
        echo -e "Local IP: ${Font_Green}$ipv4${Font_Suffix}"
        echo ""
        
        # Get public IP via this interface
        echo -e "${Font_Blue}Getting public IP information...${Font_Suffix}"
        local public_ipv4=$(curl -4 --interface "$iface_base" -s --max-time 5 "${IP_QUERY_API}" 2>/dev/null)
        
        if [ -n "$public_ipv4" ]; then
            echo -e "Public IP: ${Font_Green}$public_ipv4${Font_Suffix}"
            get_ip_info "$public_ipv4"
        else
            echo -e "${Font_Red}Failed to get public IP${Font_Suffix}"
        fi
        
        echo ""
        local curl_opts="-4 --interface $iface_base --max-time ${DEFAULT_TIMEOUT} --retry ${DEFAULT_RETRY} --retry-max-time ${DEFAULT_MAX_TIME}"
        run_tests "$curl_opts" "Interface: $interface (IPv4)" 0
        echo ""
    fi
    
    # Test IPv6 if available
    if [ -n "$ipv6" ]; then
        echo -e "${Font_Blue}[IPv6 Test]${Font_Suffix}"
        echo -e "Local IP: ${Font_Green}$ipv6${Font_Suffix}"
        echo ""
        
        # Get public IP via this interface
        echo -e "${Font_Blue}Getting public IP information...${Font_Suffix}"
        local public_ipv6=$(curl -6 --interface "$iface_base" -s --max-time 5 "${IP_QUERY_API_V6}" 2>/dev/null)
        
        if [ -n "$public_ipv6" ]; then
            echo -e "Public IP: ${Font_Green}$public_ipv6${Font_Suffix}"
            get_ip_info "$public_ipv6"
        else
            echo -e "${Font_Red}Failed to get public IP${Font_Suffix}"
        fi
        
        echo ""
        local curl_opts="-6 --interface $iface_base --max-time ${DEFAULT_TIMEOUT} --retry ${DEFAULT_RETRY} --retry-max-time ${DEFAULT_MAX_TIME}"
        run_tests "$curl_opts" "Interface: $interface (IPv6)" 1
        echo ""
    fi
    
    if [ -z "$ipv4" ] && [ -z "$ipv6" ]; then
        echo -e "${Font_Red}No IP address found on interface $interface${Font_Suffix}"
        echo ""
    fi
    
    echo -e "${Font_Blue}========================================${Font_Suffix}"
}

# ============================================
# Main Menu and Control
# ============================================

show_menu() {
    # Detect network type
    local network_type=$(detect_network_type)
    local network_info=""
    
    case $network_type in
        "dual")
            network_info="${Font_Green}IPv4 + IPv6 (Dual Stack)${Font_Suffix}"
            ;;
        "ipv4")
            network_info="${Font_Green}IPv4 Only${Font_Suffix}"
            ;;
        "ipv6")
            network_info="${Font_Green}IPv6 Only${Font_Suffix}"
            ;;
        *)
            network_info="${Font_Red}No Network${Font_Suffix}"
            ;;
    esac
    
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo -e "${Font_Blue}  Media Unlock Checker v${VERSION}${Font_Suffix}"
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo ""
    echo -e " Network: ${network_info}"
    echo ""
    
    # Detect and display network interfaces
    echo -e "${Font_Blue} Available Interfaces:${Font_Suffix}"
    
    # Use array to store interfaces properly
    local interfaces_str=$(detect_network_interfaces)
    
    if [ -z "$interfaces_str" ]; then
        echo -e "  ${Font_Red}No interfaces detected${Font_Suffix}"
        echo ""
        echo -e "${Font_Blue}========================================${Font_Suffix}"
        echo ""
        echo " 1. Exit"
        echo ""
        echo -e "${Font_Blue}========================================${Font_Suffix}"
        echo -n "Please select [1]: "
        return
    fi
    
    # Clear array first
    unset iface_list
    declare -a iface_list
    
    local index=0
    # Read line by line into array
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            iface_list[$index]="$line"
            echo -e "  ${Font_Green}$((index+1)).${Font_Suffix} ${Font_Yellow}$line${Font_Suffix}"
            ((index++))
        fi
    done <<< "$interfaces_str"
    
    local exit_option=$((index+1))
    echo ""
    echo -e "${Font_Blue} Other Options:${Font_Suffix}"
    echo -e "  ${Font_Green}$exit_option.${Font_Suffix} Exit"
    echo ""
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo -n "Select interface [1-$index] or option [$exit_option]: "
    
    # Store interface list and exit option for main function
    # We must export or use global variables since this is running in the same shell
    IFACE_LIST=("${iface_list[@]}")
    EXIT_OPTION=$exit_option
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

    # Download Disney+ cookie data before entering loop
    download_disney_cookie

    # Main loop
    while true; do
        # Global arrays for interface list
        unset IFACE_LIST
        unset EXIT_OPTION
        
        show_menu
        read choice
        
        # Check if it's the exit option
        if [ "$choice" == "$EXIT_OPTION" ]; then
            echo ""
            echo -e "${Font_Green}Goodbye!${Font_Suffix}"
            echo ""
            exit 0
        fi
        
        # Check if it's a valid interface number
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((EXIT_OPTION-1)) ]; then
            local selected_iface="${IFACE_LIST[$((choice-1))]}"
            if [ -n "$selected_iface" ]; then
                run_interface_test "$selected_iface"
                echo -n "Press Enter to continue..."
                read
            else
                echo ""
                echo -e "${Font_Red}Invalid selection${Font_Suffix}"
                echo -n "Press Enter to continue..."
                read
            fi
        else
            echo ""
            echo -e "${Font_Red}Invalid selection${Font_Suffix}"
            echo -n "Press Enter to continue..."
            read
        fi
    done
}

# Run main function
main "$@"
