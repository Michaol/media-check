# 流媒体解锁检测工具

基于 [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) 的简化版流媒体解锁检测工具。

## 功能特性

- ✅ **三大流媒体服务**: Netflix、Disney+ 和 HBO Max
- ✅ **智能网络检测**: 自动识别所有网络接口
- ✅ **自动双栈测试**: 自动检测并测试 IPv4 和 IPv6
- ✅ **详细信息显示**: 自动获取公网 IP、国家、ISP 和城市信息
- ✅ **跨平台支持**: Linux、macOS、Windows (Git Bash/MinGW)
- ✅ **无需 ROOT**: 纯 bash 实现，安全可靠

## 快速开始

### 一键执行（推荐）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Michaol/media-check/main/media-check.sh)
```

**就这么简单！** 脚本会自动检测所有网络接口，选择要测试的接口即可。

## 使用说明

运行脚本后，你会看到类似这样的菜单：

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

选择一个接口（如 `1`），脚本会自动：
1. 检测该接口的 IPv4/IPv6 地址
2. 获取公网 IP 和地理信息
3. 测试 Netflix、Disney+、HBO Max 的解锁状态

## 依赖要求

大部分 Linux 系统已预装所需工具。如果提示缺少依赖：

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

## 输出说明

- 🟢 **绿色 "Yes"**: 服务完全解锁
- 🟡 **黄色**: 部分访问或即将支持
- 🔴 **红色**: 不可用或测试失败

## 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解详细的版本变更历史。

### 最新版本 v1.3.4 (2025-11-25)

- ✅ 修复 IPv6-only VPS 支持（如 EUserv）
- ✅ 优化接口绑定逻辑
- ✅ 提升网络连接稳定性

## 致谢

基于 lmc999 的 [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) 项目。

## 许可证

MIT License

## 免责声明

本工具仅供教育和测试目的使用。请遵守流媒体平台的服务条款。
