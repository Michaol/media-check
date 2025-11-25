## [1.3.4] - 2025-11-25

### Fixed
- **IPv6-only VPS Support**: Fixed network connection issues on IPv6-only VPS (e.g., EUserv) by correcting the interface binding in curl commands. Now uses the base interface name (stripped of `@` suffix) for `--interface` parameter.

## [1.3.3] - 2025-11-24

### Fixed
- **Version Bump**: Updated to v1.3.3.
- **Cleanup**: Removed obsolete files and ensured repository only contains necessary scripts.


All notable changes to this project will be documented in this file.

## [1.3.2] - 2025-11-24

### Fixed
- **Interface Selection**: Fixed a critical bug where selecting an interface (e.g., option 1) would test a different interface due to incorrect array indexing.
- **Disney+ Detection**: Reverted to the v1.2.0 detection method (downloading cookies from GitHub) as the new API-based method was unstable.
- **Stability**: Improved robustness of the main loop and interface handling.

## [1.3.1] - 2025-11-24


### Fixed
- **Interface Selection**: Fixed a bug where selecting an interface might test a different one.
- **IP Info**: Fixed IP information display (Country/ISP/City) by switching to a more reliable API.
- **Disney+ Detection**: Reverted to the original detection method to ensure accuracy.

## [1.3.0] - 2025-11-24


### Added
- **Smart Network Interface Selection**: Automatically detects and lists available network interfaces (e.g., eth0, warp).
- **Auto Dual-Stack Testing**: Automatically detects if an interface supports IPv4 and IPv6, and tests both if available.
- **Auto Public IP Detection**: Automatically fetches public IP, Country, ISP, and City information for the selected interface.
- **Simplified Menu**: Streamlined user interface with direct interface selection.

### Changed
- **Menu Structure**: Removed separate IPv4/IPv6/Proxy/XFF options in favor of a unified interface-based workflow.
- **Dependency Management**: Disney+ cookie data is now downloaded from the cloud with a local fallback, ensuring up-to-date detection.
- **Code Optimization**: Removed redundant functions and improved network detection logic.

### Removed
- **Manual IP/Proxy Input**: Removed manual Proxy and X-Forwarded-For testing options to simplify the user experience.
- **Manual Dependency Check**: Dependency check is now performed automatically at startup.

## [1.1.0] - 2025-11-24

### Added
- **IPv6 Support**: Full support for IPv6 detection across all services (Netflix, Disney+, HBO Max).
- **Dual Stack Detection**: Automatically detects if the system supports both IPv4 and IPv6.
- **Embedded Disney+ Cookie**: Cookie data is now embedded in the script, removing the runtime dependency on external files.
- **One-Click Execution**: Added support for `curl | bash` style execution.
- **Chinese Documentation**: Added `README_CN.md` and made it the default documentation.

### Changed
- **User-Agent**: Updated to Chrome 131 for better compatibility.
- **Menu System**: Dynamic menu that adapts to the network environment (IPv4/IPv6/Dual Stack).
- **Error Handling**: Improved error messages and retry logic for network requests.

### Fixed
- **Netflix Detection**: Improved reliability of Netflix region detection.
- **Disney+ Detection**: Fixed issues with token generation and region checks.

## [1.0.0] - 2025-11-23

### Added
- Initial release.
- Support for Netflix, Disney+, and HBO Max.
- Basic local IP detection (IPv4).
- Proxy support.
