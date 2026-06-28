#!/bin/bash

# Source include file
. ./shell/INCLUDE.sh

# Exit on error
set -e

# Display Profile
make info

# VARIABEL
PROFILE=""
PACKAGES=""
MISC=""
EXCLUDED=""
DISABLED_SERVICES=""

# CORE SYSTEM
PACKAGES+=" dnsmasq-full libc block-mount zram-swap zoneinfo-core zoneinfo-asia bash screen \
uhttpd uhttpd-mod-ubus luci luci-ssl openssh-sftp-server adb curl wget-ssl \
httping htop jq tar unzip coreutils-base64 coreutils-sleep coreutils-stat"

# ETHERNET & MODEM DRIVERS
PACKAGES+=" -kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 -kmod-usb-net-asix -kmod-usb-net-asix-ax88179"
PACKAGES+=" kmod-mii kmod-usb-net kmod-usb-wdm kmod-usb-net-rndis kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-sierrawireless \
kmod-usb-net-qmi-wwan uqmi luci-proto-qmi kmod-usb-acm kmod-usb-net-huawei-cdc-ncm kmod-usb-net-cdc-mbim umbim \
kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan kmod-usb-serial-qualcomm kmod-usb-serial-sierrawireless \
qmi-utils mbim-utils usbutils luci-proto-ncm kmod-usb-ohci kmod-usb-uhci \
kmod-usb2 kmod-usb-ehci -kmod-usb3 kmod-nls-utf8 kmod-macvlan usb-modeswitch xmm-modem luci-proto-xmm"
EXCLUDED+=" -modemmanager luci-proto-modemmanager"

# MODEM TOOLS
#PACKAGES+=" atinout modeminfo modemband sms-tool luci-app-modeminfo luci-app-modemband luci-app-sms-tool-js picocom minicom"
#PACKAGES+=" modeminfo-serial-dell modeminfo-serial-fibocom modeminfo-serial-sierra modeminfo-serial-tw modeminfo-serial-xmm"

# STORAGE
PACKAGES+=" kmod-usb-storage luci-app-diskman"

# VPN TUNNEL
OPENCLASH="coreutils-nohup ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag kmod-nft-tproxy luci-app-openclash"
NIKKI="nikki luci-app-nikki"
FUSIONTUNX="fusiontunx luci-app-fusiontunx"
NEKO="php8 php8-cgi kmod-tun bash curl jq ip-full ca-bundle sing-box mihomo luci-app-neko"
PASSWALL="microsocks dns2socks dns2tcp ipt2socks tcping chinadns-ng xray-core xray-plugin naiveproxy trojan-plus tuic-client luci-app-passwall"

add_tunnel_packages() {
    local option="$1"
    case "$option" in
        openclash)
            PACKAGES+=" $OPENCLASH"
            ;;
        nikki)
            PACKAGES+=" $NIKKI"
            ;;
        neko)
            PACKAGES+=" $NEKO"
            ;;
        fusiontunx)
            PACKAGES+=" $FUSIONTUNX"
            ;;
        passwall)
            PACKAGES+=" $PASSWALL"
            ;;
        nikki-passwall)
            PACKAGES+=" $NIKKI $PASSWALL"
            ;;
        nikki-fusiontunx)
            PACKAGES+=" $NIKKI $FUSIONTUNX"
            ;;
        openclash-nikki)
            PACKAGES+=" $OPENCLASH $NIKKI"
            ;;
        openclash-passwall)
            PACKAGES+=" $OPENCLASH $PASSWALL"
            ;;
        openclash-fusiontunx)
            PACKAGES+=" $OPENCLASH $FUSIONTUNX"
            ;;
        openclash-nikki-passwall)
            PACKAGES+=" $OPENCLASH $NIKKI $PASSWALL"
            ;;
        *)
            # No tunnel
            ;;
    esac
}

# NETMONITOR + REMOTE
#PACKAGES+=" netdata vnstat2 vnstati2 luci-app-netmonitor tailscale luci-app-tailscale"

# PHP8
PACKAGES+=" php8 php8-cli php8-fastcgi php8-fpm php8-mod-session php8-mod-ctype php8-mod-fileinfo php8-mod-zip php8-mod-iconv php8-mod-mbstring"

# THEMES
PACKAGES+=" luci-theme-argon" #luci-theme-alpha

# MISC
MISC+=" -atc-fib-l8x0_gl -atc-fib-fm350_gl -luci-proto-atc -luci-app-mmconfig -luci-app-3ginfo-lite luci-app-ttl -luci-app-droidnet \
luci-app-mactodong -internet-detector -internet-detector-mod-modem-restart -luci-app-internet-detector -luci-app-ipinfo luci-app-eqosplus \
ookla-speedtest luci-app-ttyd luci-app-tinyfm luci-app-ramfree luci-app-poweroffdevice -luci-app-lite-watchdog"

# DISABLED SERVICES
DISABLED_SERVICES="xidzs todong"

# PROFILE SPECIFIC
configure_profile_packages() {
    local profile_name="$1"

    if [[ "$profile_name" == *"rpi-2"* ]] || [[ "$profile_name" == *"rpi-3"* ]] || [[ "$profile_name" == *"rpi-4"* ]] || [[ "$profile_name" == *"rpi-5"* ]]; then
        PACKAGES+=" kmod-i2c-bcm2835 i2c-tools kmod-i2c-core kmod-i2c-gpio"
    elif [[ "${ARCH_2:-}" == "x86_64" ]] || [[ "${ARCH_2:-}" == "i386" ]]; then
        PACKAGES+=" kmod-iwlwifi iw-full pciutils wireless-tools"
    fi

    if [[ "${TYPE:-}" == "OPHUB" ]] || [[ "${TYPE:-}" == "ULO" ]]; then
        PACKAGES+=" btrfs-progs kmod-fs-btrfs luci-app-amlogic"
#        EXCLUDED+=" -procd-ujail"
        EXCLUDED+=" -libiwinfo-data -libiwinfo20230701 -rpcd-mod-iwinfo -libiwinfo -rpcd-mod-iwinfo -kmod-nls-cp437 -kmod-nls-iso8859-1 -procd-ujail -kmod-tun \
        -kmod-amazon-ena -kmod-e1000e -kmod-vmxnet3 -kmod-rtc-rx8025 -kmod-i2c-mux-pca954x -kmod-gpio-pca953x -partx-utils -kmod-wdt-sp805 -kmod-mvneta -kmod-mvpp2 \
        -kmod-fsl-dpaa1-net -kmod-fsl-dpaa2-net -kmod-fsl-enetc-net -kmod-dwmac-imx -kmod-fsl-fec -kmod-dwmac-rockchip -kmod-dwmac-sun8i -kmod-phy-aquantia \
        -kmod-phy-broadcom -kmod-phy-marvell -kmod-phy-marvell-10g -kmod-sfp -kmod-atlantic -kmod-bcmgenet -kmod-octeontx2-net -kmod-renesas-net-avb -kmod-phy-realtek -kmod-phy-smsc"
    fi
}

# RELEASE SPECIFIC
configure_release_packages() {
    if [[ "${BASE:-}" == "openwrt" ]]; then
        MISC+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211 luci-app-temp-status"
        EXCLUDED+=" -dnsmasq"
    elif [[ "${BASE:-}" == "immortalwrt" ]]; then
        MISC+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211"
        EXCLUDED+=" -dnsmasq -cpusage -automount -libustream-openssl -default-settings-chn -luci-i18n-base-zh-cn"
        
        if [[ "${ARCH_2:-}" == "x86_64" ]] || [[ "${ARCH_2:-}" == "i386" ]]; then
            EXCLUDED+=" -kmod-usb-net-rtl8152-vendor"
        fi
    fi
}

# MAIN BUILD
build_firmware() {
    local target_profile="$1"
    local tunnel_option="${2:-}"
    local build_files="files"

    log "INFO" "Starting build for profile '$target_profile' [Tunnel: $tunnel_option]..."

    # Load Profile Specifics
    configure_profile_packages "$target_profile"
    
    # Load Tunnel Packages
    add_tunnel_packages "$tunnel_option"
    
    # Load Base/Release Config
    configure_release_packages

    # PACKAGES + MISC + EXCLUDED + DISABLED_SERVICES    
    make image -j$(nproc) PROFILE="$target_profile" \
               PACKAGES="$PACKAGES $MISC $EXCLUDED" \
               FILES="$build_files" \
               DISABLED_SERVICES="$DISABLED_SERVICES"
    
    local build_status=$?
    if [ "$build_status" -eq 0 ]; then
        log "SUCCESS" "Build completed successfully!"
    else
        log "ERROR" "Build failed with exit code $build_status"
        exit "$build_status"
    fi
}

# Validasi Argumen
if [ -z "${1:-}" ]; then
    echo "ERROR: Profile not specified."
    echo "Usage: $0 <profile> [tunnel_option]"
    echo "Tunnel Options: openclash, nikki, fusiontunx, nikki-passwall, openclash-nikki, openclash-fusiontunx, openclash-nikki-passwall, no-tunnel"
    exit 1
fi

# Jalankan log function dummy
if ! command -v log &> /dev/null; then
    log() { echo "[$1] $2"; }
fi

# Running Build
build_firmware "$1" "${2:-}"
