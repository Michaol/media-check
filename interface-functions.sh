# Network Interface Detection and Selection Functions

detect_network_interfaces() {
    echo -e "${Font_Blue}Detecting network interfaces...${Font_Suffix}"
    
    # Try ip command first (modern Linux)
    if command -v ip >/dev/null 2>&1; then
        # Get all interfaces with IP addresses
        ip -o addr show | grep -v "scope host" | awk '{
            iface=$2
            addr=$4
            # Remove CIDR notation
            split(addr, a, "/")
            ip=a[1]
            # Skip loopback
            if (iface != "lo" && ip != "127.0.0.1" && ip != "::1") {
                print iface ":" ip
            }
        }' | sort -u
    # Fallback to ifconfig (older systems)
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig | awk '
            /^[a-z]/ {iface=$1; gsub(/:/, "", iface)}
            /inet / && iface != "lo" {print iface ":" $2}
            /inet6 / && iface != "lo" && $2 !~ /^fe80/ {print iface ":" $2}
        ' | grep -v "127.0.0.1" | grep -v "::1"
    else
        echo "Error: Neither ip nor ifconfig command found"
        return 1
    fi
}

show_interface_menu() {
    echo ""
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo -e "${Font_Blue} Network Interface Selection${Font_Suffix}"
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo ""
    
    # Detect interfaces
    local interfaces=$(detect_network_interfaces)
    
    if [ -z "$interfaces" ]; then
        echo -e "${Font_Red}No network interfaces detected${Font_Suffix}"
        return 1
    fi
    
    # Parse and display interfaces
    local -a iface_list
    local -a ip_list
    local index=1
    
    while IFS=: read -r iface ip; do
        iface_list[$index]="$iface"
        ip_list[$index]="$ip"
        
        # Determine IP type
        if [[ "$ip" =~ : ]]; then
            local ip_type="IPv6"
        else
            local ip_type="IPv4"
        fi
        
        echo -e " ${Font_Green}$index.${Font_Suffix} ${Font_Yellow}$iface${Font_Suffix} - $ip ($ip_type)"
        ((index++))
    done <<< "$interfaces"
    
    echo ""
    echo -e " ${Font_Green}0.${Font_Suffix} Back to main menu"
    echo ""
    echo -e "${Font_Blue}========================================${Font_Suffix}"
    echo -n "Select interface [0-$((index-1))]: "
    
    read selection
    
    if [ "$selection" == "0" ]; then
        return 0
    fi
    
    if [ "$selection" -ge 1 ] && [ "$selection" -lt "$index" ]; then
        local selected_iface="${iface_list[$selection]}"
        local selected_ip="${ip_list[$selection]}"
        
        echo ""
        echo -e "${Font_Green}Selected: $selected_iface ($selected_ip)${Font_Suffix}"
        echo ""
        
        # Run tests with selected interface
        run_interface_test "$selected_iface" "$selected_ip"
    else
        echo -e "${Font_Red}Invalid selection${Font_Suffix}"
        return 1
    fi
}

run_interface_test() {
    local interface="$1"
    local ip="$2"
    
    echo -e "${Font_Blue}Testing with interface: ${Font_Yellow}$interface${Font_Suffix}"
    echo -e "${Font_Blue}IP Address: ${Font_Yellow}$ip${Font_Suffix}"
    echo ""
    
    # Determine if IPv4 or IPv6
    local use_ipv6=0
    if [[ "$ip" =~ : ]]; then
        use_ipv6=1
    fi
    
    # Get IP info
    get_ip_info "$ip"
    
    # Build curl options with interface binding
    local curl_opts="--interface $interface --max-time ${DEFAULT_TIMEOUT} --retry ${DEFAULT_RETRY} --retry-max-time ${DEFAULT_MAX_TIME}"
    
    # Add IPv4/IPv6 flag
    if [ "$use_ipv6" == "1" ]; then
        curl_opts="-6 $curl_opts"
    else
        curl_opts="-4 $curl_opts"
    fi
    
    # Run tests
    run_tests "$curl_opts" "Interface: $interface" "$use_ipv6"
}
