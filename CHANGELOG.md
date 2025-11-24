# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2024-11-24

### Added
- **Full IPv6 Support**: All three streaming services now support IPv6 detection
  - Added `get_local_ip_v6()` function for IPv6 address retrieval
  - Added `detect_network_type()` function to auto-detect network configuration
  - Added `run_local_test_v6()` function for IPv6 local IP testing
  - Dynamic menu that adapts based on network type (IPv4/IPv6/Dual Stack)
  
- **Embedded Disney+ Cookie Data**: Removed external GitHub dependency
  - Disney+ cookie data now embedded in `config.sh`
  - Added local caching mechanism (`~/.cache/media-check/`)
  - Cache expiry set to 24 hours
  - Automatic fallback to embedded data if cache fails

- **Enhanced Error Handling**:
  - Netflix: Added HTTP status code checking (403 detection for IP blocks)
  - Disney+: Improved error messages for each authentication step
  - HBO Max: Better network error detection
  - All services: Distinguish between network errors and service errors

### Changed
- **Updated User-Agent**: Chrome 125 → Chrome 131
  - `UA_BROWSER`: Updated to Chrome 131.0.0.0
  - `UA_ANDROID`: Updated to Android 14 with Pixel 8
  - `UA_SEC_CH_UA`: Updated version strings

- **Improved Detection Logic**:
  - Netflix: Now checks HTTP status codes in addition to page content
  - HBO Max: Removed hardcoded "US" from supported countries list
  - All services: Accept IPv6 flag parameter for proper IPv6 testing

- **Version Bump**: 1.0.0 → 1.1.0

### Fixed
- Disney+ detection no longer depends on external GitHub repository
- HBO Max now correctly extracts all supported countries from API response
- Network type detection works correctly on all platforms
- Cache directory creation handles permission errors gracefully

### Technical Details
- Added `ENABLE_IPV6` configuration option (default: enabled)
- Added `CACHE_DIR` and `DISNEY_COOKIE_CACHE` configuration
- Modified `run_tests()` to accept IPv6 flag parameter
- Updated all test functions (`test_netflix`, `test_disneyplus`, `test_hbomax`) to support IPv6

## [1.0.0] - 2024-11-23

### Initial Release
- Basic Netflix, Disney+, and HBO Max detection
- IPv4 support
- Proxy and X-Forwarded-For methods
- Cross-platform compatibility
- Interactive menu system
