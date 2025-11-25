# Media Unlock Checker

A simplified streaming service unlock detection tool based on [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck).

## Features

- ✅ **Three Major Services**: Netflix, Disney+, and HBO Max
- ✅ **Smart Network Detection**: Automatically identifies all network interfaces
- ✅ **Auto Dual-Stack**: Automatically tests IPv4 and IPv6
- ✅ **Detailed Info**: Auto-fetches public IP, Country, ISP, and City
- ✅ **Cross-Platform**: Linux, macOS, Windows (Git Bash/MinGW)
- ✅ **No Root Required**: Pure bash implementation, safe and reliable

## Quick Start

### One-Click Execution (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Michaol/media-check/main/media-check.sh)
```

**That's it!** The script will automatically detect all network interfaces and you can select which one to test.

## Usage

After running the script, you'll see a menu like this:

```
========================================
  Media Unlock Checker v1.3.4
========================================

 Network: IPv4 + IPv6 (Dual Stack)

 Available Interfaces:
  1. eth0
  2. warp

 Other Options:
  3. Exit

========================================
Select interface [1-2] or option [3]: 
```

Select an interface (e.g., `1`), and the script will automatically:
1. Detect IPv4/IPv6 addresses for that interface
2. Fetch public IP and geo-location info
3. Test unlock status for Netflix, Disney+, and HBO Max

## Requirements

Most Linux systems have all required tools pre-installed. If you see missing dependencies:

**Ubuntu/Debian:**
```bash
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

## Output Legend

- 🟢 **Green "Yes"**: Service fully unlocked
- 🟡 **Yellow**: Partial access or coming soon
- 🔴 **Red**: Not available or test failed

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

### Latest Version v1.3.4 (2025-11-25)

- ✅ Fixed IPv6-only VPS support (e.g., EUserv)
- ✅ Improved interface binding logic
- ✅ Enhanced network connection stability

## Credits

Based on [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) by lmc999.

## License

MIT License

## Disclaimer

This tool is for educational and testing purposes only. Please comply with the streaming platforms' terms of service.
