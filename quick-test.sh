#!/bin/bash

# 简化的自动测试脚本
# 直接调用检测函数,不进入交互模式

cd /mnt/g/GitHub/media-check

# 设置颜色
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

echo -e "${Font_Blue}=========================================${Font_Suffix}"
echo -e "${Font_Blue} Media-Check v1.1.0 本机 IP 检测测试${Font_Suffix}"
echo -e "${Font_Blue}=========================================${Font_Suffix}"
echo ""

# 1. 获取本机 IP
echo -e "${Font_Blue}1. 获取本机 IP 地址...${Font_Suffix}"
LOCAL_IP=$(curl -s --max-time 5 https://api64.ipify.org 2>/dev/null)
if [ -z "$LOCAL_IP" ]; then
    echo -e "${Font_Red}✗ 获取 IP 失败${Font_Suffix}"
    exit 1
fi
echo -e "${Font_Green}✓ 本机 IP: $LOCAL_IP${Font_Suffix}"
echo ""

# 2. 查询 IP 信息
echo -e "${Font_Blue}2. 查询 IP 信息...${Font_Suffix}"
IP_INFO=$(curl -s --max-time 5 "https://api.ip.sb/geoip/$LOCAL_IP" 2>/dev/null)
if [ -n "$IP_INFO" ]; then
    COUNTRY=$(echo "$IP_INFO" | grep -oP '"country"\s*:\s*"\K[^"]+' | head -n1)
    ISP=$(echo "$IP_INFO" | grep -oP '"isp"\s*:\s*"\K[^"]+' | head -n1)
    CITY=$(echo "$IP_INFO" | grep -oP '"city"\s*:\s*"\K[^"]+' | head -n1)
    echo -e "${Font_Green}✓ 国家: $COUNTRY${Font_Suffix}"
    echo -e "${Font_Green}✓ ISP: $ISP${Font_Suffix}"
    echo -e "${Font_Green}✓ 城市: $CITY${Font_Suffix}"
else
    echo -e "${Font_Yellow}⚠ IP 信息查询失败${Font_Suffix}"
fi
echo ""

echo -e "${Font_Blue}=========================================${Font_Suffix}"
echo -e "${Font_Blue} 开始流媒体检测${Font_Suffix}"
echo -e "${Font_Blue}=========================================${Font_Suffix}"
echo ""

# 3. Netflix 检测
echo -e -n " Netflix:\t\t\t"
NETFLIX_RESULT=$(curl -fsL --max-time 10 \
    "https://www.netflix.com/title/81280792" \
    -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
    -H 'accept-language: en-US,en;q=0.9' \
    -b "flwssn=d2c72c47-49e9-48da-b7a2-2dc6d7ca9fcf" \
    -H 'sec-ch-ua: "Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Windows"' \
    --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
    2>/dev/null)

if [ -z "$NETFLIX_RESULT" ]; then
    echo -e "${Font_Red}Failed (Network Connection)${Font_Suffix}"
elif echo "$NETFLIX_RESULT" | grep -q "Oh no!"; then
    echo -e "${Font_Yellow}Originals Only${Font_Suffix}"
else
    REGION=$(echo "$NETFLIX_RESULT" | grep -oP 'data-country="\K[A-Z]{2}' | head -n1)
    if [ -n "$REGION" ]; then
        echo -e "${Font_Green}Yes (Region: ${REGION})${Font_Suffix}"
    else
        echo -e "${Font_Green}Yes${Font_Suffix}"
    fi
fi

# 4. Disney+ 检测
echo -e -n " Disney+:\t\t\t"
echo -e "${Font_Yellow}Skipped (需要完整脚本支持)${Font_Suffix}"

# 5. HBO Max 检测
echo -e -n " HBO Max:\t\t\t"
HBOMAX_RESULT=$(curl -sLi "https://www.max.com/" \
    -w "_TAG_%{http_code}_TAG_" \
    --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
    2>/dev/null)

HTTP_CODE=$(echo "$HBOMAX_RESULT" | grep '_TAG_' | awk -F'_TAG_' '{print $2}')

if [ "$HTTP_CODE" == "000" ]; then
    echo -e "${Font_Red}Failed (Network Connection)${Font_Suffix}"
else
    REGION=$(echo "$HBOMAX_RESULT" | grep -oP 'countryCode=\K[A-Z]{2}' | head -n1)
    if [ -n "$REGION" ]; then
        echo -e "${Font_Green}Yes (Region: ${REGION})${Font_Suffix}"
    else
        echo -e "${Font_Yellow}Unknown${Font_Suffix}"
    fi
fi

echo ""
echo -e "${Font_Blue}=========================================${Font_Suffix}"
echo -e "${Font_Green} 测试完成${Font_Suffix}"
echo -e "${Font_Blue}=========================================${Font_Suffix}"
