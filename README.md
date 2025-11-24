# 流媒体解锁检测工具

基于 [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) 的简化版流媒体解锁检测工具。

## 功能特性

- ✅ **三大流媒体服务**: Netflix、Disney+ 和 HBO Max
- ✅ **智能网络检测**: 自动识别所有网络接口
- ✅ **自动双栈测试**: 自动检测并测试 IPv4 和 IPv6
- ✅ **详细信息显示**: 自动获取公网 IP、国家、ISP 和城市信息
- ✅ **跨平台**: 支持 Linux、macOS、Windows (Git Bash/MinGW)
- ✅ **无需 ROOT**: 纯 bash 实现
- ✅ **智能 Cookie 管理**: 优先使用云端最新数据，内置数据作为备用

## 快速开始

### 🚀 一键执行(推荐)

**无需下载,直接运行,测试完自动清理:**

```bash
# 方式 1: 临时运行(推荐,测试完自动删除)
bash <(curl -fsSL https://raw.githubusercontent.com/Michaol/media-check/main/media-check.sh)
```

**如果需要保留脚本:**

```bash
# 方式 2: 下载并运行
curl -fsSL https://raw.githubusercontent.com/Michaol/media-check/main/media-check.sh -o media-check.sh && \
curl -fsSL https://raw.githubusercontent.com/Michaol/media-check/main/config.sh -o config.sh && \
bash media-check.sh

# 测试完成后清理(可选)
rm -f media-check.sh config.sh
rm -rf ~/.cache/media-check
```

### 📦 传统方式

如果您已经克隆了仓库:

```bash
# 添加执行权限
chmod +x media-check.sh

# 运行脚本
bash media-check.sh
```

## 依赖要求

### 必需工具

- `curl` (支持 HTTPS)
- `grep` (支持 Perl 正则表达式)
- `sed`
- `awk`
- `uuidgen` 或 `/proc/sys/kernel/random/uuid`

### 安装方法

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
大多数工具已预装。如需要,安装 Git for Windows 即可获得所有必需工具。

## 使用方法

### 交互式菜单

直接运行脚本即可进入交互式菜单:

```bash


### 选项 5: 检查依赖

验证所有必需工具是否已安装:

```bash
bash media-check.sh --check-deps
```

**示例输出:**
```
检查依赖...
✓ curl
✓ grep
✓ sed
✓ awk
✓ UUID 生成
所有依赖已满足!
```

## 工作原理

### Netflix 检测

1. 测试两个不同的 Netflix 内容:
   - **LEGO Ninjago** (ID: 81280792) - 全球原创内容
   - **Breaking Bad** (ID: 70143836) - 地区限定内容

2. **结果判断:**
   - 两个都被屏蔽 → **仅原创内容** (只能观看 Netflix 原创)
   - 至少一个可访问 → **完全解锁** + 地区代码
   - 网络错误 → **失败**
   - HTTP 403 → **IP 被封禁**

### Disney+ 检测

多步骤 API 认证流程:

1. **设备注册**: 注册浏览器设备获取 assertion token
2. **令牌交换**: 用 assertion 交换访问令牌
3. **地区查询**: 查询 GraphQL API 获取国家代码和支持状态
4. **可用性检查**: 验证服务在该地区是否可用

**结果判断:**
- `inSupportedLocation: true` → **完全解锁** + 地区代码
- `inSupportedLocation: false` → **即将支持**
- `forbidden-location` 错误 → **不可用 (IP 被封禁)**

### HBO Max 检测

1. 访问 HBO Max (现为 Max) 主页
2. 从页面提取支持的国家列表
3. 从响应中提取当前地区
4. 比较当前地区是否在支持列表中

**结果判断:**
- 地区在支持列表中 → **完全解锁** + 地区代码
- 地区不在列表中 → **不可用**

## 输出颜色说明

- 🟢 **绿色**: 服务完全解锁
- 🟡 **黄色**: 部分访问或即将支持
- 🔴 **红色**: 不可用或失败

## 常见问题

### "Failed (Network Connection)" 网络连接失败

- 检查网络连接
- 如使用代理,验证代理是否正常工作
- 尝试在 `config.sh` 中增加超时时间

### "Disney+ Failed (Cookie data not available)" Disney+ Cookie 数据不可用

这个错误在 v1.1.0 中已经不应该出现,因为 Cookie 数据已内置。如果仍然出现:
- 检查 `config.sh` 文件是否完整
- 尝试删除缓存: `rm -rf ~/.cache/media-check/`
- 重新运行脚本

### "grep: invalid option -- 'P'" grep 不支持 -P 参数

您的 `grep` 不支持 Perl 正则表达式。请安装 GNU grep:

**macOS:**
```bash
brew install grep
# 添加到 PATH: export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
```

### 代理无法工作

- 验证代理格式: `protocol://host:port`
- 手动测试代理: `curl -x socks5://127.0.0.1:1080 https://api64.ipify.org`
- 检查代理是否需要认证: `protocol://user:pass@host:port`

### IPv6 测试失败

- 确认您的网络支持 IPv6
- 检查 `config.sh` 中 `ENABLE_IPV6=1` 是否启用
- 尝试手动测试 IPv6: `curl -6 https://api64.ipify.org`

## 新功能 (v1.1.0)

### 完整的 IPv6 支持

- ✅ 所有三大流媒体服务支持 IPv6 检测
- ✅ 自动检测网络类型(IPv4/IPv6/双栈)
- ✅ 动态菜单根据网络配置调整

### 内置 Disney+ Cookie 数据

- ✅ 无需外部网络请求
- ✅ 启动速度提升 2-3 倍
- ✅ 支持离线使用
- ✅ 本地缓存机制(24小时过期)

### 增强的错误处理

- ✅ Netflix: HTTP 状态码检查,区分 IP 封禁
- ✅ 所有服务: 区分网络错误和服务错误
- ✅ 更详细的错误提示信息

## 限制说明

1. **X-Forwarded-For 方法**: 大多数流媒体服务会忽略此头部,因此结果可能无法反映目标 IP 的真实解锁状态。

2. **IPv6 支持**: 需要您的网络环境支持 IPv6。如果网络不支持,菜单会自动隐藏 IPv6 选项。

3. **频率限制**: 频繁测试可能触发流媒体服务的频率限制。

## 项目结构

```
media-check/
├── media-check.sh    # 主脚本
├── config.sh         # 配置文件
├── validate.sh       # 验证脚本
├── README.md         # 本文件(中文)
├── README_EN.md      # 英文文档
├── CHANGELOG.md      # 变更日志
├── ANALYSIS.md       # 技术分析
└── examples/         # 示例脚本
    ├── local-ip-test.sh
    ├── proxy-test.sh
    └── x-forward-test.sh
```

## 致谢

基于 lmc999 的 [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) 项目。

## 许可证

MIT License

## 贡献

欢迎贡献! 请随时提交 issue 或 pull request。

## 免责声明

本工具仅供教育和测试目的使用。请遵守流媒体平台的服务条款。

## 清理说明

### 自动清理(一键执行方式)

如果您使用一键执行命令,脚本运行在临时目录中,退出后会自动清理,无需手动操作。

### 手动清理(下载方式)

如果您下载了脚本文件,可以使用以下命令清理:

```bash
# 删除脚本文件
rm -f media-check.sh config.sh

# 删除缓存目录(可选)
rm -rf ~/.cache/media-check
```

### 缓存说明

脚本会在 `~/.cache/media-check/` 目录下创建缓存文件:
- `disney_cookie.txt` - Disney+ Cookie 缓存(24小时过期)

缓存文件很小(约2KB),不影响系统性能,可以保留以提升下次运行速度。

## 使用提示

### 💡 小白用户推荐

1. **最简单**: 直接复制一键执行命令,粘贴到终端运行
2. **无需下载**: 脚本在内存中运行,不占用磁盘空间
3. **自动清理**: 退出后自动清理,保持系统干净
4. **随时使用**: 需要时再次运行一键命令即可

### 🔧 高级用户推荐

1. **克隆仓库**: `git clone https://github.com/Michaol/media-check.git`
2. **保留脚本**: 方便随时使用和自定义配置
3. **定期更新**: `git pull` 获取最新版本

## 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解详细的版本变更历史。

### v1.1.0 主要更新 (2024-11-24)

- ✅ 完整的 IPv6 支持
- ✅ Disney+ Cookie 数据内置
- ✅ 增强的错误处理
- ✅ User-Agent 更新到 Chrome 131
- ✅ 性能优化(启动速度提升 2-3 倍)
- ✅ 一键执行命令(无需下载)
