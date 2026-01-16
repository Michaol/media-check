#!/bin/bash

# Configuration file for Media Unlock Checker

# Version
VERSION='1.4.0'

# User-Agent strings (Updated to Chrome 131)
UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
UA_SEC_CH_UA='"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"'
UA_ANDROID="Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"

# API Endpoints
NETFLIX_TEST_URL_1="https://www.netflix.com/title/81280792"  # LEGO Ninjago (Originals)
NETFLIX_TEST_URL_2="https://www.netflix.com/title/70143836"  # Breaking Bad (Regional)

DISNEY_DEVICE_API="https://disney.api.edge.bamgrid.com/devices"
DISNEY_TOKEN_API="https://disney.api.edge.bamgrid.com/token"
DISNEY_GRAPH_API="https://disney.api.edge.bamgrid.com/graph/v1/device/graphql"
DISNEY_HOME_URL="https://disneyplus.com"
DISNEY_BEARER_TOKEN="ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84"

HBOMAX_HOME_URL="https://www.max.com/"
PRIMEVIDEO_HOME_URL="https://www.primevideo.com"

# API Endpoints
IP_INFO_API="http://ip-api.com/json"
IP_QUERY_API="https://api64.ipify.org"
IP_QUERY_API_V6="https://api64.ipify.org"  # IPv6 support

# Cache configuration
CACHE_DIR="${HOME}/.cache/media-check"
DISNEY_COOKIE_CACHE="${CACHE_DIR}/disney_cookie.txt"
CACHE_EXPIRY=86400  # 24 hours in seconds

# Netflix cookies (simplified version)
NETFLIX_COOKIE="flwssn=d2c72c47-49e9-48da-b7a2-2dc6d7ca9fcf; nfvdid=BQFmAAEBEMZa4XMYVzVGf9-kQ1HXumtAKsCyuBZU4QStC6CGEGIVznjNuuTerLAG8v2-9V_kYhg5uxTB5_yyrmqc02U5l1Ts74Qquezc9AE-LZKTo3kY3g%3D%3D"

# Default settings
DEFAULT_TIMEOUT=10
DEFAULT_RETRY=3
DEFAULT_MAX_TIME=20

# Cookie data validation
MIN_COOKIE_LENGTH=100

# IPv6 support
ENABLE_IPV6=1  # Set to 0 to disable IPv6 support

# Disney+ Cookie data (embedded to avoid external dependency)
# This data is from RegionRestrictionCheck project
# Last updated: 2024-11-24
read -r -d '' DISNEY_COOKIE_DATA << 'EOF'
grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Atoken-exchange&latitude=0&longitude=0&platform=browser&subject_token=DISNEYASSERTION&subject_token_type=urn%3Abamtech%3Aparams%3Aoauth%3Atoken-type%3Adevice
'authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84'
"AMCVS_CFAF55745DD2611E0A495C82%40AdobeOrg=1; s_pvDate=2021%2F06%2F17; s_cc=true; wowow2_mem_guide=visited; wowow2_MGSID=4440260aa4011f0162393267600028772; wowow2_MGSID_AuthTicket=fd28d6b1349fd2e672af97370c4eaa4d42a4fdf2; demographics=01301; u-demographics=BAD81A3D84A07B32EC333E1BEFE72F10; wowow2_sls=1; wowow2_ext_MGSID=4440260aa4011f0162393267600028772; wod_auth=CfDJ8D-H-2bqdw1AjJk3TVDbKLaZydf2DfrFVw51ktRQdWqpml0TtbTZudBFfOd-ReyghPDX8aTlo8Ys_shmm-Nv7GBeFMrsM-pUufuTmiSYX7yEa5D9h6YDRA7OviqDLyAKDHUpZifwVToT1vKg_A9G1UMaS0exxBx_TcoOe9U_3Ex4HAb98A5106gj-6ztKoSPVxxKEneO1JdtLe3uVCZ_HMqh6oCeJCZvvlOVN_w_lECjchu58NGtZWmV3mE02DZ-SK5X6xT6GTetvr5EvFKJAxNfaNvkHoS_e-20dz-c-8huuTuvXTg3-i5OAQSyG5UQ_VRz-qqMVV-JR2xmRyxPuEifLU3Iy_B0IWvE65YZlexmL2KVEP745nB7-wCRuVzu9zEdO1IRHQ3fruQ_8RJqb0g; wod_secret=1e4c8db631cd4d2f986102a87811e8e5; s_ips=1010; s_sq=%5B%5BB%5D%5D; x_xsrf_token=1623934360j1T6bPwpGswOnPp3IrcHFZ5vPMo8LE; s_gpvPage=www%3Awowow%3Amember%3Alogin.php%3Ard%3Ahttps%3A%2B%2Bwww.wowow.co.jp%2Bsupport%2Bregist_self.php; s_tp=1010; s_ppv=www%253Awowow%253Amember%253Alogin.php%253Ard%253Ahttps%253A%2B%2Bwww.wowow.co.jp%2Bsupport%2Bregist_self.php%2C100%2C100%2C1010%2C1%2C1; s_nr365=1623934367877-Repeat; AMCV_CFAF55745DD2611E0A495C82%40AdobeOrg=-432600572%7CMCIDTS%7C18796%7CMCMID%7C30796674720677405047057880592301178864%7CMCOPTOUT-1623941567s%7CNONE%7CvVersion%7C4.5.2"
"Accept: application/json;pk=BCpkADawqM3ZdH8iYjCnmIpuIRqzCn12gVrtpk_qOePK3J9B6h7MuqOw5T_qIqdzpLvuvb_hTvu7hs-7NsvXnPTYKd9Cgw7YiwI9kFfOOCDDEr20WDEYMjGiLptzWouXXdfE996WWM8myP3Z"
{"device_identifier":"2B3BACF5B121715649E5D667D863612E:2ea6","deejay_device_id":190,"version":1,"all_cdn":true,"content_eab_id":"EAB::ea0def9a-afa3-4371-b126-964e1c6bea89::60515729::2000604","region":"US","xlink_support":false,"device_ad_id":"7DC1A194-92E0-117A-A072-E22535FD3B8D","limit_ad_tracking":false,"ignore_kids_block":false,"language":"en","guid":"2B3BACF5B121715649E5D667D863612E","rv":838281,"kv":451730,"unencrypted":true,"include_t2_revenue_beacon":"1","cp_session_id":"D5A29AC4-45C5-28EC-2D90-310D8B603665","interface_version":"1.11.0","network_mode":"wifi","play_intent":"resume","lat":23.1192247,"long":113.2199658,"playback":{"version":2,"video":{"codecs":{"values":[{"type":"H264","width":1920,"height":1080,"framerate":60,"level":"4.2","profile":"HIGH"}],"selection_mode":"ONE"}},"audio":{"codecs":{"values":[{"type":"AAC"}],"selection_mode":"ONE"}},"drm":{"values":[{"type":"WIDEVINE","version":"MODULAR","security_level":"L3"},{"type":"PLAYREADY","version":"V2","security_level":"SL2000"}],"selection_mode":"ALL"},"manifest":{"type":"DASH","https":true,"multiple_cdns":true,"patch_updates":true,"hulu_types":true,"live_dai":true,"multiple_periods":false,"xlink":false,"secondary_audio":true,"live_fragment_delay":3},"segments":{"values":[{"type":"FMP4","encryption":{"mode":"CENC","type":"CENC"},"https":true}],"selection_mode":"ONE"}}}
{"query":"mutation refreshToken($input: RefreshTokenInput!) {\\n            refreshToken(refreshToken: $input) {\\n                activeSession {\\n                    sessionId\\n                }\\n            }\\n        }","variables":{"input":{"refreshToken":"ILOVEDISNEY"}}}
grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Atoken-exchange&latitude=0&longitude=0&platform=browser&subject_token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJlM2NkMTFmYi1hZjA4LTQ4Y2UtOGJmNi03ZTVhNDdmNDdmMzUiLCJhdWQiOiJ1cm46YmFtdGVjaDpzZXJ2aWNlOnRva2VuIiwibmJmIjoxNjMwNDIxNDc0LCJpc3MiOiJ1cm46YmFtdGVjaDpzZXJ2aWNlOmRldmljZSIsImV4cCI6MjQ5NDQyMTQ3NCwiaWF0IjoxNjMwNDIxNDc0LCJqdGkiOiI0NGFhNWE4NC01YzdmLTQzOTMtYWFjNy1kN2U5OGM3MzU2NmMifQ.3NIPcVfIPgkDsJJoBD2RS9MK86i-xuIABKcYNl1oCCJJ2bzTiK8cgdPZNrpah7EMzIesVQdVet4Epxpy99jw2w&subject_token_type=urn%3Abamtech%3Aparams%3Aoauth%3Atoken-type%3Adevice
{"query":"mutation registerDevice($input: RegisterDeviceInput!) {\\n            registerDevice(registerDevice: $input) {\\n                grant {\\n                    grantType\\n                    assertion\\n                }\\n            }\\n        }","variables":{"input":{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","deviceLanguage":"zh-CN","attributes":{"osDeviceIds":[],"manufacturer":"microsoft","model":null,"operatingSystem":"windows","operatingSystemVersion":"10.0","browserName":"chrome","browserVersion":"96.0.4664"}}}}
EOF
