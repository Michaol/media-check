# RegionRestrictionCheck 项目分析

## 项目概述

RegionRestrictionCheck 是一个基于 Bash Shell 的流媒体解锁检测工具,可以检测当前 IP 对各种流媒体服务的访问权限。

### 核心特性
- 纯 Bash Shell 实现,无需 ROOT 权限
- 支持多平台:Linux, macOS, FreeBSD, Windows (MinGW/Cygwin), Android (Termux), iOS (iSH)
- 支持 IPv4 和 IPv6
- 支持代理检测
- 支持自定义网卡接口

## 核心工作原理

### 1. 基础架构

脚本使用 `curl` 作为核心工具,通过以下方式检测流媒体解锁状态:

1. **HTTP 请求模拟**: 使用真实的浏览器 User-Agent 和请求头
2. **Cookie 管理**: 某些服务需要特定的 Cookie 来模拟真实用户
3. **响应分析**: 通过分析 HTTP 响应码、页面内容、JSON 数据来判断解锁状态
4. **地区识别**: 提取响应中的国家/地区代码

### 2. 关键函数说明

#### 通用工具函数

- `color_print()`: 定义颜色输出
- `validate_ip_address()`: 验证 IP 地址格式(IPv4/IPv6)
- `resolve_ip_address()`: DNS 解析
- `get_ip_info()`: 获取本机 IP 和 ISP 信息
- `download_extra_data()`: 下载额外的 Cookie 和数据

#### 核心检测逻辑

每个流媒体服务都有独立的检测函数,格式为 `MediaUnlockTest_ServiceName()`

## 三大服务检测机制详解

### 1. Netflix 检测 (`MediaUnlockTest_Netflix`)

**检测原理:**
- 访问两个不同的 Netflix 内容页面:
  - LEGO Ninjago (ID: 81280792) - 全球可用的原创内容
  - Breaking Bad (ID: 70143836) - 地区限定内容
  
**判断逻辑:**
1. 如果两个页面都显示 "Oh no!" → **仅原创内容** (Originals Only)
2. 如果至少一个页面可访问 → **完全解锁** (Yes) + 显示地区代码
3. 提取地区代码: `data-country="XX"` 属性

**关键技术:**
```bash
# 使用预设的 Netflix Cookie 模拟登录用户
# 通过 grep 查找 "Oh no!" 判断是否被限制
# 通过正则提取 data-country 属性获取地区
```

### 2. Disney+ 检测 (`MediaUnlockTest_DisneyPlus`)

**检测原理:**
Disney+ 使用多步骤认证流程:

**步骤 1: 设备注册**
```bash
POST https://disney.api.edge.bamgrid.com/devices
Authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA...
Body: {"deviceFamily":"browser","applicationRuntime":"chrome",...}
```
- 获取 `assertion` token

**步骤 2: 获取访问令牌**
```bash
POST https://disney.api.edge.bamgrid.com/token
# 使用 assertion 和预设的 Cookie 数据
```
- 获取 `refresh_token`
- 检测 `forbidden-location` 错误

**步骤 3: 查询地区信息**
```bash
POST https://disney.api.edge.bamgrid.com/graph/v1/device/graphql
# 使用 refresh_token 查询
```
- 提取 `countryCode` (地区代码)
- 提取 `inSupportedLocation` (是否在支持地区)

**步骤 4: 检查可用性**
```bash
GET https://disneyplus.com
# 检查重定向 URL 是否包含 preview/unavailable
```

**判断逻辑:**
1. 403 错误或 `forbidden-location` → **IP 被封禁**
2. `inSupportedLocation: false` → **即将支持该地区**
3. `inSupportedLocation: true` → **完全解锁** + 显示地区代码
4. 重定向到 preview/unavailable → **不可用**

**关键技术:**
```bash
# 使用 Disney+ 官方 API
# Bearer Token 认证
# 多步骤 token 交换
# 从外部文件加载预设 Cookie 数据
```

### 3. HBO Max 检测 (`MediaUnlockTest_HBOMax`)

**检测原理:**
- 访问 HBO Max (现为 Max) 主页: `https://www.max.com/`
- 分析响应头和页面内容

**判断逻辑:**
1. 提取所有支持的国家列表: `"url":"/xx/xx"` 格式
2. 提取当前地区代码: `countryCode=XX` 参数
3. 如果当前地区在支持列表中 → **解锁** (Yes) + 显示地区代码
4. 否则 → **不可用** (No)

**关键技术:**
```bash
# 使用 -i 参数获取响应头
# grep -woP 正则提取 URL 模式
# 提取并去重国家代码列表
# 默认添加 US 到支持列表
```

## 依赖项

### 必需工具
1. **curl**: HTTP 请求核心工具
2. **grep**: 支持 Perl 正则 (`-P` 参数)
3. **uuidgen** 或 `/proc/sys/kernel/random/uuid`: 生成 UUID
4. **openssl**: 加密相关
5. **md5sum/sha256sum** (macOS 需要)

### 可选工具
- **nslookup/dig**: DNS 解析
- **usleep**: 精确延迟控制

## 核心变量

```bash
# 全局配置
UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64)..."
CURL_DEFAULT_OPTS="$USE_NIC $USE_PROXY $X_FORWARD ${CURL_SSL_CIPHERS_OPT} --max-time 10 --retry 3"

# 网络配置
USE_NIC=""           # 网卡接口: --interface eth0
USE_PROXY=""         # 代理: -x socks5://127.0.0.1:1080
X_FORWARD=""         # X-Forwarded-For 头
NETWORK_TYPE=""      # 4=IPv4, 6=IPv6

# 外部数据
MEDIA_COOKIE=""      # 从 GitHub 下载的 Cookie 数据
```

## 命令行参数

```bash
-I, --interface <name>        # 指定网卡接口
-M, --network-type <4|6>      # 指定 IPv4 或 IPv6
-E, --language <en|zh>        # 语言设置
-X, --x-forwarded-for <ip>    # 设置 X-Forwarded-For 头
-P, --proxy <url>             # 代理地址
-R, --region <id>             # 地区 ID
```

## 检测流程

1. **初始化**
   - 检查操作系统类型
   - 验证依赖工具
   - 解析命令行参数

2. **网络检测**
   - 获取本机 IP 地址
   - 获取 ISP 信息
   - 检查网络连通性

3. **下载外部数据**
   - 从 GitHub 下载 Cookie 数据
   - 下载 IATA 机场代码数据

4. **执行检测**
   - 调用各个服务的检测函数
   - 输出彩色格式化结果

## 关键技术点

### 1. IP 地址处理
```bash
# 隐藏部分 IP 地址
# IPv4: 1.2.*.* 
# IPv6: 2001:db8:85a3:*:*
```

### 2. Cookie 管理
```bash
# 从外部 URL 下载预设 Cookie
MEDIA_COOKIE=$(curl -s "https://raw.githubusercontent.com/.../cookies")
# 使用变量替换插入动态 token
disneyCookie=$(echo "$preDisneyCookie" | sed "s/DISNEYASSERTION/${assertion}/g")
```

### 3. JSON 解析
```bash
# 使用 grep -woP 提取 JSON 字段
local region=$(echo "$tmpresult" | grep -woP '"countryCode"\s{0,}:\s{0,}"\K[^"]+')
```

### 4. 错误处理
```bash
# 检查 HTTP 状态码
case "$result" in
    '000') echo "Failed (Network Connection)" ;;
    '200') echo "Yes" ;;
    '403') echo "No" ;;
    *) echo "Failed (Error: ${result})" ;;
esac
```

## 输出格式

```
Netflix:                    Yes (Region: US)
Disney+:                    Yes (Region: US)
HBO Max:                    Yes (Region: US)
```

颜色编码:
- 🟢 绿色 (Font_Green): 完全解锁
- 🟡 黄色 (Font_Yellow): 部分解锁/即将支持
- 🔴 红色 (Font_Red): 不可用/失败
