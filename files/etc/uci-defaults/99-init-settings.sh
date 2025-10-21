#!/bin/sh

# Setup logging
LOG_FILE="/root/setup-xidzswrt.log"
exec > "$LOG_FILE" 2>&1

# All variables
SYSTEM_JS="/www/luci-static/resources/view/status/include/10_system.js"
PORTS_JS="/www/luci-static/resources/view/status/include/29_ports.js"
NEW_PORTS_JS="/www/luci-static/resources/view/status/include/11_ports.js"
RELEASE_FILE="/etc/openwrt_release"
TTYD_JSON="/usr/share/luci/menu.d/luci-app-ttyd.json"
TEMP_JS="/www/luci-static/resources/view/status/include/27_temperature.js"
NEW_TEMP_JS="/www/luci-static/resources/view/status/include/15_temperature.js"
RC_LOCAL="/etc/rc.local"
CRONTAB_ROOT="/etc/crontabs/root"
USB_MODE="/etc/usb-mode.json"
OPKG_CONF="/etc/opkg.conf"
SYSINFO_SH="/etc/profile.d/30-sysinfo.sh"
PROFILE="/etc/profile"
MM_REPORT="/usr/lib/ModemManager/connection.d/10-report-down"
INSTALL2_SH="/root/install2.sh"
RULES_SH="/root/rules.sh"
INDOWRT_SH="/root/indowrt.sh"
OCPATCH_SH="/root/ocpatch.sh"
CLASH_META="/etc/openclash/core/clash_meta"
COUNTRY_MMDB="/etc/openclash/Country.mmdb"
PHP_INI="/etc/php.ini"
PHP_INI_BAK="/etc/php.ini.bak"
VNSTAT_CONF="/etc/vnstat.conf"
PLUG_USB="/etc/hotplug.d/usb/23-wwan-modem"
HAT_WIFI="/etc/hotplug.d/usb/99-wifi-hat"
ARGON_CONF="/usr/share/ucode/luci/template/themes/argon/header.ut"
RTA_CONF="/usr/lib/lua/luci/view/themes/rtawrt/header.htm"

# logging dengan status
log_status() {
    local status="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$status] $message"
}

# header log
log_status "INFO" "========================================="
log_status "INFO" "XIDZs-WRT Setup Script Started"
log_status "INFO" "Script Setup By Xidz-x | Fidz"
log_status "INFO" "Installed Time: $(date '+%A, %d %B %Y %T')"
log_status "INFO" "========================================="

# modify firmware display
log_status "INFO" "Modifying firmware display..."
sed -i "s#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' / ':'')+(luciversion||''),#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' By fidz':''),#g" "$SYSTEM_JS"
sed -i -E 's/icons\/port_%s\.(svg|png)/icons\/port_%s.gif/g' "$PORTS_JS"
mv "$PORTS_JS" "$NEW_PORTS_JS"

# sett permission directory
log_status "INFO" "sett permission directory..."
chmod -R +x /sbin /usr/bin /etc/init.d
chmod +x "$MM_REPORT"
chmod +x "$PLUG_USB"
chmod +x "$HAT_WIFI"

# check system release
log_status "INFO" "Checking system release..."
if grep -q "ImmortalWrt" /etc/openwrt_release; then
    sed -i 's/\(DISTRIB_DESCRIPTION='\''ImmortalWrt [0-9]*\.[0-9]*\.[0-9]*\).*'\''/\1'\''/g' "$RELEASE_FILE"
    sed -i 's|system/ttyd|services/ttyd|g' "$TTYD_JSON"
    BRANCH_VERSION=$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')
    log_status "INFO" "ImmortalWrt detected - $BRANCH_VERSION"
elif grep -q "OpenWrt" /etc/openwrt_release; then
    sed -i 's/\(DISTRIB_DESCRIPTION='\''OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'\''/\1'\''/g' "$RELEASE_FILE"
    mv "$TEMP_JS" "$NEW_TEMP_JS"
    BRANCH_VERSION=$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')
    log_status "INFO" "OpenWrt detected - $BRANCH_VERSION"
else
    log_status "WARNING" "Unknown system release"
fi

# setup root password
log_status "INFO" "Setting up root password..."
(echo "xyyraa"; sleep 2; echo "xyyraa") | passwd > /dev/null

# setup hostname and timezone
log_status "INFO" "Configuring hostname and timezone..."
uci set system.@system[0].hostname='XIDZs-WRT'
uci set system.@system[0].timezone='WIB-7'
uci set system.@system[0].zonename='Asia/Jakarta'
uci delete system.ntp.server
uci add_list system.ntp.server='pool.ntp.org'
uci add_list system.ntp.server='id.pool.ntp.org'
uci add_list system.ntp.server='time.google.com'
uci commit system

# setup bahasa default
log_status "INFO" "Setting default language to English..."
uci set luci.@core[0].lang='en'
uci commit luci

# configure wan and lan
log_status "INFO" "Configuring network interfaces..."
uci set network.tethering=interface
uci set network.tethering.proto='dhcp'
uci set network.tethering.device='usb0'
uci set network.modem=interface
uci set network.modem.proto='dhcp'
uci set network.modem.device='eth1'
uci set network.mm=interface
uci set network.mm.proto='modemmanager'
uci set network.mm.device='/sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/2-1'
uci set network.mm.apn='internet'
uci set network.mm.auth='none'
uci set network.mm.iptype='ipv4'
uci delete network.wan6
uci commit network

log_status "INFO" "Configuring firewall..."
uci set firewall.@zone[1].network='tethering modem mm'
uci commit firewall

# disable ipv6 lan
log_status "INFO" "Disabling IPv6 on LAN..."
uci delete dhcp.lan.dhcpv6
uci delete dhcp.lan.ra
uci delete dhcp.lan.ndp
uci commit dhcp

# configure wireless device
log_status "INFO" "Configuring wireless..."
uci set wireless.@wifi-device[0].disabled='0'
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-iface[0].mode='ap'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key='XIDZs2025'
uci set wireless.@wifi-device[0].country='ID'

# check for Raspberry Pi Devices
if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
    log_status "INFO" "Raspberry Pi detected - configuring 5GHz WiFi..."
    uci set wireless.@wifi-iface[0].ssid='XIDZs-WRT_5G'
    uci set wireless.@wifi-device[0].channel='149'
    uci set wireless.@wifi-device[0].htmode='VHT80'
else
    log_status "INFO" "Generic device detected - configuring 2.4GHz WiFi..."
    uci set wireless.@wifi-iface[0].ssid='XIDZs-WRT'
    uci set wireless.@wifi-device[0].channel='1'
    uci set wireless.@wifi-device[0].htmode='HT20'
fi

uci commit wireless
wifi reload && wifi up > /dev/null

# check wireless interface
if iw dev | grep -q Interface; then
    if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
        log_status "INFO" "Adding wireless startup scripts for Raspberry Pi..."
        if ! grep -q "wifi up" /etc/rc.local; then
            sed -i '/exit 0/i # remove if you dont use wireless' "$RC_LOCAL"
            sed -i '/exit 0/i sleep 10 && wifi up' "$RC_LOCAL"
        fi
        if ! grep -q "wifi up" /etc/crontabs/root; then
            echo "# remove if you dont use wireless" >> /etc/crontabs/root
            echo "0 */12 * * * wifi down && sleep 5 && wifi up" >> /etc/crontabs/root
            /etc/init.d/cron restart > /dev/null
        fi
    fi
fi

# remove huawei me909s and dw5821e usb-modeswitch
log_status "INFO" "Removing USB modeswitch entries..."
sed -i -e '/12d1:15c1/,+5d' -e '/413c:81d7/,+5d' "$USB_MODE"

# disable xmm-modem
log_status "INFO" "Disabling XMM-Modem..."
uci set xmm-modem.@xmm-modem[0].enable='0'
uci commit xmm-modem

# disable opkg signature check
log_status "INFO" "Disabling OPKG signature check..."
sed -i 's/option check_signature/# option check_signature/g' "$OPKG_CONF"

# add custom repository
log_status "INFO" "Adding custom repository..."
ARCH=$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')
echo "src/gz custom_packages https://dl.openwrt.ai/latest/packages/$ARCH/kiddin9" >> /etc/opkg/customfeeds.conf

# setup default theme
log_status "INFO" "Setting Argon theme as default..."
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# remove login password ttyd
log_status "INFO" "Configuring TTYD..."
uci set ttyd.@ttyd[0].command='/bin/bash --login'
uci commit ttyd

# symlink Tinyfm
log_status "INFO" "Creating TinyFM symlink..."
ln -sf / /www/tinyfm/rootfs

# add auto sinkron jam, Clean Cache, Remove mm tty
log_status "INFO" "Adding startup scripts..."
sed -i '/exit 0/i #/etc/init.d/openclash restart' "$RC_LOCAL"
sed -i '/exit 0/i #/sbin/free.sh' "$RC_LOCAL"
sed -i '/exit 0/i #/sbin/jam bug.com' "$RC_LOCAL"

# setup device amlogic
log_status "INFO" "Checking for Amlogic device configuration..."
if opkg list-installed | grep -q luci-app-amlogic; then
    log_status "INFO" "luci-app-amlogic detected"
    rm -f "$SYSINFO_SH"
    sed -i '/exit 0/i #sleep 5 && /usr/bin/k5hgled -r' "$RC_LOCAL"
    sed -i '/exit 0/i #sleep 5 && /usr/bin/k6hgled -r' "$RC_LOCAL"
else
    log_status "INFO" "luci-app-amlogic not detected"
    rm -f /usr/bin/k5hgled /usr/bin/k6hgled /usr/bin/k5hgledon /usr/bin/k6hgledon
fi

# setup misc settings
log_status "INFO" "Setting up misc configurations..."
sed -i -e 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' -e 's/\[ -n \"\$FAILSAFE\" \] && cat \/etc\/banner.failsafe/& || \/usr\/bin\/xyyraa/' "$PROFILE"
rm -rf /etc/hotplug.d/usb/25-modemmanager-usb
/etc/init.d/issue enable > /dev/null

# run install2 script
log_status "INFO" "Running install2 script..."
chmod +x "$INSTALL2_SH"
"$INSTALL2_SH"

# add rules
log_status "INFO" "Running rules script..."
chmod +x "$RULES_SH"
"$RULES_SH"

# add TTL
log_status "INFO" "Running TTL script..."
chmod +x "$INDOWRT_SH"
"$INDOWRT_SH"

# checking and setup tunnel
log_status "INFO" "Checking tunnel applications..."

for pkg in luci-app-openclash luci-app-nikki luci-app-passwall; do
    if opkg list-installed | grep -qw "$pkg"; then
        log_status "INFO" "$pkg detected"
        
        case "$pkg" in
            luci-app-openclash)
                log_status "INFO" "Configuring OpenClash..."
                chmod +x "$CLASH_META"
                chmod +x "$COUNTRY_MMDB"
                chmod +x /etc/openclash/Geo*
                
                log_status "INFO" "Patching OpenClash overview..."
                if [ -f "$OCPATCH_SH" ]; then
                    chmod +x "$OCPATCH_SH"
                    "$OCPATCH_SH"
                    log_status "INFO" "OpenClash patch applied successfully"
                else
                    log_status "WARNING" "ocpatch.sh not found, skipping patch"
                fi
                
                ln -sf /etc/openclash/history/quenx.db /etc/openclash/cache.db
                ln -sf /etc/openclash/core/clash_meta /etc/openclash/clash
                
                rm -f /etc/config/openclash    
                mv /etc/config/openclash1 /etc/config/openclash
                
                sed -i '103,105s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '144s/.*/<\!-- & -->/' "$ARGON_CONF"
                ;;
                
            luci-app-nikki)
                log_status "INFO" "Configuring Nikki..."                
                chmod +x /etc/nikki/run/Geo*
                rm -rf /etc/nikki/run/proxy_provider
                rm -rf /etc/nikki/run/rule_provider
                
                log_status "INFO" "Creating symlinks from OpenClash to Nikki..."
                ln -sf /etc/openclash/proxy_provider /etc/nikki/run
                ln -sf /etc/openclash/rule_provider /etc/nikki/run
                
                sed -i '115,117s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '146s/.*/<\!-- & -->/' "$ARGON_CONF"
                ;;
                
            luci-app-passwall)
                log_status "INFO" "Configuring Passwall..."
                sed -i '112,114s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '147s/.*/<\!-- & -->/' "$ARGON_CONF"
                ;;
        esac
        
    else
        log_status "INFO" "$pkg not detected, cleaning up..."
        
        case "$pkg" in
            luci-app-openclash)
                rm -f /etc/config/openclash1
                rm -rf /etc/openclash
                
                sed -i '118,120s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '149s/.*/<\!-- & -->/' "$ARGON_CONF"
                ;;
                
            luci-app-nikki)
                rm -rf /etc/nikki
                
                sed -i '121,123s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '150s/.*/<\!-- & -->/' "$ARGON_CONF"
                ;;
                
            luci-app-passwall)
                rm -f /etc/config/passwall
                
                sed -i '124,126s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '151s/.*/<\!-- & -->/' "$ARGON_CONF"
                ;;
        esac
    fi
done

# konfigurasi uhttpd dan PHP8
log_status "INFO" "Configuring uhttpd and PHP8..."

# uhttpd configuration
uci set uhttpd.main.ubus_prefix='/ubus'
uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
uci set uhttpd.main.index_page='cgi-bin/luci'
uci add_list uhttpd.main.index_page='index.html'
uci add_list uhttpd.main.index_page='index.php'
uci commit uhttpd

# PHP configuration
cp /etc/php.ini "$PHP_INI_BAK"
sed -i 's|^memory_limit = .*|memory_limit = 128M|g' "$PHP_INI"
sed -i 's|^max_execution_time = .*|max_execution_time = 60|g' "$PHP_INI"
sed -i 's|^display_errors = .*|display_errors = Off|g' "$PHP_INI"
sed -i 's|^;*date\.timezone =.*|date.timezone = Asia/Jakarta|g' "$PHP_INI"

ln -sf /usr/lib/php8
/etc/init.d/uhttpd restart > /dev/null

log_status "INFO" "========================================="
log_status "INFO" "XIDZs-WRT Setup Script Finished"
log_status "INFO" "Check log file: $LOG_FILE"
log_status "INFO" "========================================="

sync
rm -rf /etc/uci-defaults/$(basename "$0")

exit 0
