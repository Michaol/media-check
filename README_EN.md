# Media Unlock Checker

A simplified streaming service unlock detection tool based on [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck).

## Features

- ✅ **Three Major Services**: Netflix, Disney+, and HBO Max
- ✅ **Smart Network Detection**: Automatically identifies all network interfaces
- ✅ **Auto Dual-Stack**: Automatically tests IPv4 and IPv6
- ✅ **Detailed Info**: Auto-fetches public IP, Country, ISP, and City
- ✅ **Cross-Platform**: Works on Linux, macOS, Windows (Git Bash/MinGW)
- ✅ **No Root Required**: Pure bash implementation
- ✅ **Smart Cookie Management**: Prioritizes cloud data with embedded fallback

## Quick Start

### 🚀 One-Click Execution (Recommended)

**No download required, run directly, auto-cleanup after testing:**

```bash
# Method 1: Temporary run (recommended, auto-delete after testing)
bash <(curl -fsSL https://raw.githubusercontent.com/Michaol/media-check/main/media-check.sh)
```

**If you want to keep the script:**

```bash
# Method 2: Download and run
curl -fsSL https://raw.githubusercontent.com/Michaol/media-check/main/media-check.sh -o media-check.sh && \
curl -fsSL https://raw.githubusercontent.com/Michaol/media-check/main/config.sh -o config.sh && \
bash media-check.sh

# Cleanup after testing (optional)
rm -f media-check.sh config.sh
rm -rf ~/.cache/media-check
```

### 📦 Traditional Method

If you have already cloned the repository:

```bash
# Make the script executable
chmod +x media-check.sh

# Run the script
bash media-check.sh
```

## Requirements

### Required Tools

- `curl` (with HTTPS support)
- `grep` (with Perl regex support)
- `sed`
- `awk`
- `uuidgen` or `/proc/sys/kernel/random/uuid`

### Installation

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install curl grep sed gawk uuid-runtime
```

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install curl grep sed gawk util-linux
```

**macOS:**
```bash
brew install grep coreutils
```

**Windows (Git Bash/MinGW):**
Most tools are pre-installed. If needed, install Git for Windows which includes all required utilities.

## Usage

### Interactive Menu

Simply run the script to access the interactive menu:

```bash
bash media-check.sh
```

You'll see:
```
========================================
  Media Unlock Checker v1.3.0
========================================

 Network: IPv4 + IPv6 (Dual Stack)

 Available Interfaces:
  1. eth0
  2. eth1
  3. warp

 Other Options:
  4. Exit

========================================
Select interface [1-3] or option [4]:
```

### Automatic Testing Flow

After selecting an interface, the script will automatically:
1. **Get IP Info**: Detect IPv4/IPv6 addresses for the interface
2. **Query Public Info**: Fetch public IP, location, ISP, and city
3. **Dual-Stack Test**: Automatically test both IPv4 and IPv6 if available
4. **Streaming Check**: Check unlock status for Netflix, Disney+, and HBO Max

### Option 4: Check Dependencies

Verify that all required tools are installed:

```bash
bash media-check.sh --check-deps
```

**Example output:**
```
Checking dependencies...
✓ curl
✓ grep
✓ sed
✓ awk
✓ UUID generation
All dependencies are satisfied!
```

## How It Works

### Netflix Detection

1. Tests two different Netflix titles:
   - **LEGO Ninjago** (ID: 81280792) - Global original content
   - **Breaking Bad** (ID: 70143836) - Region-restricted content

2. **Results:**
   - Both blocked → **Originals Only** (only Netflix originals available)
   - At least one accessible → **Yes** (full unlock) + region code
   - Network error → **Failed**

### Disney+ Detection

Multi-step API authentication process:

1. **Device Registration**: Register a browser device to get assertion token
2. **Token Exchange**: Exchange assertion for access token
3. **Region Query**: Query GraphQL API for country code and support status
4. **Availability Check**: Verify service is available in the region

**Results:**
- `inSupportedLocation: true` → **Yes** + region code
- `inSupportedLocation: false` → **Available Soon**
- `forbidden-location` error → **No (IP Banned)**

### HBO Max Detection

1. Access HBO Max (now Max) homepage
2. Extract list of supported countries from page
3. Extract current region from response
4. Compare current region with supported list

**Results:**
- Region in supported list → **Yes** + region code
- Region not in list → **No**

## Output Colors

- 🟢 **Green**: Service is fully unlocked
- 🟡 **Yellow**: Partial access or coming soon
- 🔴 **Red**: Not available or failed

## Troubleshooting

### "Failed (Network Connection)"

- Check your internet connection
- If using a proxy, verify the proxy is working
- Try increasing timeout in `config.sh`

### "Disney+ Failed (Cookie data not available)"

- The script couldn't download Disney+ authentication data from GitHub
- Check if you can access: https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies
- Try running the script again

### "grep: invalid option -- 'P'"

Your `grep` doesn't support Perl regex. Install GNU grep:

**macOS:**
```bash
brew install grep
# Add to PATH: export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
```

### Proxy not working

- Verify proxy format: `protocol://host:port`
- Test proxy manually: `curl -x socks5://127.0.0.1:1080 https://api64.ipify.org`
- Check if proxy requires authentication: `protocol://user:pass@host:port`

## Limitations

1. **X-Forwarded-For method**: Most streaming services ignore this header, so results may not reflect the target IP's actual unlock status.

2. **Disney+ dependency**: Requires downloading cookie data from the original RegionRestrictionCheck repository. If this fails, Disney+ detection won't work.

3. **IPv6 support**: Currently optimized for IPv4. IPv6 support may vary by service.

4. **Rate limiting**: Frequent testing may trigger rate limits from streaming services.

## Project Structure

```
media-check/
├── media-check.sh    # Main script
├── config.sh         # Configuration file
├── README.md         # This file
├── README_CN.md      # Chinese documentation
├── ANALYSIS.md       # Technical analysis
└── examples/         # Example scripts
    ├── local-ip-test.sh
    ├── proxy-test.sh
    └── x-forward-test.sh
```

## Credits

Based on [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) by lmc999.

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Disclaimer

This tool is for educational and testing purposes only. Please respect the terms of service of streaming platforms.
