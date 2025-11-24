#!/bin/bash

# 自动测试脚本 - 本机 IP 检测
# 这个脚本会自动运行本机 IP 检测并显示结果

cd /mnt/g/GitHub/media-check

echo "========================================="
echo " Media-Check v1.1.0 自动测试"
echo "========================================="
echo ""

# 加载脚本
source ./config.sh
source ./media-check.sh

echo "1. 检查依赖..."
check_dependencies
echo ""

echo "2. 加载 Disney+ Cookie 数据..."
download_disney_cookie
echo ""

echo "3. 获取本机 IP 地址..."
LOCAL_IP=$(get_local_ip)
if [ $? -eq 0 ]; then
    echo "本机 IP: $LOCAL_IP"
else
    echo "获取 IP 失败"
    exit 1
fi
echo ""

echo "4. 查询 IP 信息..."
get_ip_info "$LOCAL_IP"
echo ""

echo "5. 开始流媒体检测..."
CURL_OPTS="--max-time ${DEFAULT_TIMEOUT} --retry ${DEFAULT_RETRY} --retry-max-time ${DEFAULT_MAX_TIME}"

run_tests "$CURL_OPTS" "Local IP (IPv4)" 0

echo ""
echo "========================================="
echo " 测试完成"
echo "========================================="
