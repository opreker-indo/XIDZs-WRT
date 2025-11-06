#!/bin/sh

# Setup logging
exec > "/root/setup-xidzswrt.log" 2>&1

# Log function
log_status() {
    local status="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$status] $message"
}

# Header
log_status "INFO" "========================================="
log_status "INFO" "XIDZs-WRT Setup Script Started"
log_status "INFO" "Script Setup By Fidz"
log_status "INFO" "Installed Time: $(date '+%A, %d %B %Y %T')"
log_status "INFO" "========================================="

# Modify firmware display
log_status "INFO" "Modifying firmware display..."
sed -i "s#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' / ':'')+(luciversion||''),#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' | Fidz':''),#g" "/www/luci-static/resources/view/status/include/10_system.js"
sed -i -E 's/icons\/port_%s\.(svg|png)/icons\/port_%s.gif/g' "/www/luci-static/resources/view/status/include/29_ports.js"
mv "/www/luci-static/resources/view/status/include/29_ports.js" "/www/luci-static/resources/view/status/include/11_ports.js"

# Check device model
log_status "INFO" "Checking device model..."
if grep -q "OrangePi Zero3" /proc/device-tree/model 2>/dev/null; then
    log_status "INFO" "OrangePi Zero3 detected..."
    chmod +x /etc/hotplug.d/usb/23-wwan_hat /etc/hotplug.d/usb/99-wifi_hat
else
    log_status "INFO" "Generic devices detected.."
    rm -f /etc/hotplug.d/usb/99-wifi_hat /etc/hotplug.d/usb/23-wwan_hat
    rm -f /etc/hotplug.d/tty/25-modemmanager-tty
fi

# Check system release
log_status "INFO" "Checking system release..."
if grep -q "ImmortalWrt" /etc/openwrt_release; then
    sed -i 's/\(DISTRIB_DESCRIPTION='\''ImmortalWrt [0-9]*\.[0-9]*\.[0-9]*\).*'\''/\1'\''/g' /etc/openwrt_release
    sed -i 's|system/ttyd|services/ttyd|g' /usr/share/luci/menu.d/luci-app-ttyd.json
    BRANCH_VERSION=$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')
    log_status "INFO" "ImmortalWrt detected - $BRANCH_VERSION"
elif grep -q "OpenWrt" /etc/openwrt_release; then
    sed -i 's/\(DISTRIB_DESCRIPTION='\''OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'\''/\1'\''/g' /etc/openwrt_release
    mv /www/luci-static/resources/view/status/include/27_temperature.js /www/luci-static/resources/view/status/include/15_temperature.js
    BRANCH_VERSION=$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')
    log_status "INFO" "OpenWrt detected - $BRANCH_VERSION"
else
    log_status "WARNING" "Unknown system release"
fi

# Setup root password
log_status "INFO" "Setting root password..."
(echo "quenx"; sleep 2; echo "quenx") | passwd > /dev/null

# Configure hostname & timezone
log_status "INFO" "Configure hostname & timezone..."
uci set system.@system[0].hostname='XIDZs-WRT'
uci set system.@system[0].timezone='WIB-7'
uci set system.@system[0].zonename='Asia/Jakarta'
uci delete system.ntp.server
uci add_list system.ntp.server='pool.ntp.org'
uci add_list system.ntp.server='id.pool.ntp.org'
uci add_list system.ntp.server='time.google.com'
uci commit system

# Set default language
log_status "INFO" "Set default language..."
uci set luci.@core[0].lang='en'
uci commit luci

# Configure network
log_status "INFO" "Configure network..."
uci set network.tethering=interface
uci set network.tethering.proto='dhcp'
uci set network.tethering.device='usb0'
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.device='eth1'
uci set network.mm=interface
uci set network.mm.proto='modemmanager'
uci set network.mm.device='/sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/2-1'
uci set network.mm.apn='internet'
uci set network.mm.auth='none'
uci set network.mm.iptype='ipv4'
uci set network.mm.force_connection='1'
uci delete network.wan6
uci commit network

log_status "INFO" "Configure firewall..."
uci set firewall.@zone[1].network='tethering wan mm'
uci commit firewall

# Configure wireless
log_status "INFO" "Configure wireless..."
uci set wireless.@wifi-device[0].disabled='0'
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-iface[0].mode='ap'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key='XIDZs2025'
uci set wireless.@wifi-device[0].country='ID'

# Check Raspberry Pi
if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
    log_status "INFO" "Raspberry Pi - configure 5GHz WiFi..."
    uci set wireless.@wifi-iface[0].ssid='XIDZs-WRT_5G'
    uci set wireless.@wifi-device[0].channel='149'
    uci set wireless.@wifi-device[0].htmode='VHT80'
else
    log_status "INFO" "Generic device - configure 2.4GHz WiFi..."
    uci set wireless.@wifi-iface[0].ssid='XIDZs-WRT'
    uci set wireless.@wifi-device[0].channel='1'
    uci set wireless.@wifi-device[0].htmode='HT20'
fi

uci commit wireless
wifi reload && wifi up > /dev/null

# Check WiFi & add startup scripts for RPi
if iw dev | grep -q Interface; then
    if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
        log_status "INFO" "Add WiFi startup scripts for RPi..."
        if ! grep -q "wifi up" /etc/rc.local; then
            sed -i '/exit 0/i # remove if you dont use wireless' /etc/rc.local
            sed -i '/exit 0/i sleep 10 && wifi up' /etc/rc.local
        fi
        if ! grep -q "wifi up" /etc/crontabs/root; then
            echo "# remove if you dont use wireless" >> /etc/crontabs/root
            echo "0 */12 * * * wifi down && sleep 5 && wifi up" >> /etc/crontabs/root
            /etc/init.d/cron restart > /dev/null
        fi
    fi
fi

# Remove USB modeswitch entries
log_status "INFO" "Remove USB modeswitch entries..."
sed -i -e '/12d1:15c1/,+5d' -e '/413c:81d7/,+5d' /etc/usb-mode.json

# Disable XMM-Modem
log_status "INFO" "Disable XMM-Modem..."
uci set xmm-modem.@xmm-modem[0].enable='0'
uci commit xmm-modem

# Disable OPKG signature
log_status "INFO" "Disable OPKG signature check..."
sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf

# Add custom repository
log_status "INFO" "Add custom repository..."
ARCH=$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')
echo "src/gz custom_packages https://dl.openwrt.ai/latest/packages/$ARCH/kiddin9" >> /etc/opkg/customfeeds.conf

# Set default theme
log_status "INFO" "Set Argon theme as default..."
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# Configure TTYD
log_status "INFO" "Configure TTYD..."
uci set ttyd.@ttyd[0].command='/bin/bash --login'
uci commit ttyd

# Create TinyFM symlink
log_status "INFO" "Create TinyFM symlink..."
ln -sf / /www/tinyfm/rootfs

# Add startup scripts
log_status "INFO" "Add startup scripts..."
sed -i '/exit 0/i #/etc/init.d/openclash restart' /etc/rc.local
sed -i '/exit 0/i #sleep 5 && /sbin/free.sh' /etc/rc.local
sed -i '/exit 0/i #/sbin/jam bug.com' /etc/rc.local

# Check Amlogic device
log_status "INFO" "Check Amlogic device..."
if opkg list-installed | grep -q luci-app-amlogic; then
    log_status "INFO" "luci-app-amlogic detected"
    rm -f /etc/profile.d/30-sysinfo.sh
    sed -i '/exit 0/i #sleep 5 && /usr/bin/x-gpioled -r' /etc/rc.local
else
    log_status "INFO" "luci-app-amlogic not detected"
    rm -f /usr/bin/k5hgled /usr/bin/k6hgled
    rm -f /usr/bin/x-gpioled /usr/bin/x-gpioledon
    rm -f /usr/bin/k5hgledon /usr/bin/k6hgledon
fi

# Misc settings
log_status "INFO" "Setup misc configurations..."
sed -i -e 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' -e 's/\[ -n \"\$FAILSAFE\" \] && cat \/etc\/banner.failsafe/& || \/usr\/bin\/quenx/' /etc/profile
chmod -R +x /sbin /usr/bin /etc/init.d
/etc/init.d/issue enable > /dev/null

# Run additional scripts
log_status "INFO" "Set Permission And Run install2 script..."
chmod +x /root/install2.sh
/root/install2.sh

log_status "INFO" "Set Permission And Run rules script..."
chmod +x /root/rules.sh
/root/rules.sh

log_status "INFO" "Set Permission And Run TTL script..."
chmod +x /root/indowrt.sh
/root/indowrt.sh

# Check tunnel apps
log_status "INFO" "Check tunnel applications..."

for pkg in luci-app-openclash luci-app-nikki luci-app-passwall; do
    if opkg list-installed | grep -qw "$pkg"; then
        log_status "INFO" "$pkg detected"
        
        case "$pkg" in
            luci-app-openclash)
                log_status "INFO" "Configure OpenClash..."
                chmod +x /etc/openclash/core/clash_meta
                chmod +x /etc/openclash/Country.mmdb
                chmod +x /etc/openclash/Geo*
                
                ln -sf /etc/openclash/history/quenx.db /etc/openclash/cache.db
                ln -sf /etc/openclash/core/clash_meta /etc/openclash/clash
                
                rm -f /etc/config/openclash    
                mv /etc/config/openclash1 /etc/config/openclash
                
                sed -i '103,105s/.*/<\!-- & -->/' /usr/lib/lua/luci/view/themes/rtawrt/header.htm
                sed -i '144s/.*/<\!-- & -->/' /usr/share/ucode/luci/template/themes/argon/header.ut
                sed -i "88s/'Enable'/'Disable'/" /etc/config/alpha
                ;;
                
            luci-app-nikki)
                log_status "INFO" "Configure Nikki..."                
                chmod +x /etc/nikki/run/Geo*
                rm -rf /etc/nikki/run/proxy_provider
                rm -rf /etc/nikki/run/rule_provider
                
                log_status "INFO" "Create symlinks from OpenClash to Nikki..."
                ln -sf /etc/openclash/proxy_provider /etc/nikki/run
                ln -sf /etc/openclash/rule_provider /etc/nikki/run
                
                sed -i '115,117s/.*/<\!-- & -->/' /usr/lib/lua/luci/view/themes/rtawrt/header.htm
                sed -i '146s/.*/<\!-- & -->/' /usr/share/ucode/luci/template/themes/argon/header.ut
                sed -i "40s/'Enable'/'Disable'/" /etc/config/alpha
                ;;
                
            luci-app-passwall)
                log_status "INFO" "Configure Passwall..."
                sed -i '112,114s/.*/<\!-- & -->/' /usr/lib/lua/luci/view/themes/rtawrt/header.htm
                sed -i '147s/.*/<\!-- & -->/' /usr/share/ucode/luci/template/themes/argon/header.ut
                sed -i "72s/'Enable'/'Disable'/" /etc/config/alpha
                ;;
        esac
        
    else
        log_status "INFO" "$pkg not detected, cleanup..."
        
        case "$pkg" in
            luci-app-openclash)
                rm -f /etc/config/openclash1
                rm -rf /etc/openclash
                
                sed -i '118,120s/.*/<\!-- & -->/' /usr/lib/lua/luci/view/themes/rtawrt/header.htm
                sed -i '149s/.*/<\!-- & -->/' /usr/share/ucode/luci/template/themes/argon/header.ut
                sed -i "104s/'Enable'/'Disable'/" /etc/config/alpha
                ;;
                
            luci-app-nikki)
                rm -rf /etc/nikki
                
                sed -i '121,123s/.*/<\!-- & -->/' /usr/lib/lua/luci/view/themes/rtawrt/header.htm
                sed -i '150s/.*/<\!-- & -->/' /usr/share/ucode/luci/template/themes/argon/header.ut
                sed -i "120s/'Enable'/'Disable'/" /etc/config/alpha
                ;;
                
            luci-app-passwall)
                rm -f /etc/config/passwall
                
                sed -i '124,126s/.*/<\!-- & -->/' /usr/lib/lua/luci/view/themes/rtawrt/header.htm
                sed -i '151s/.*/<\!-- & -->/' /usr/share/ucode/luci/template/themes/argon/header.ut
                sed -i "136s/'Enable'/'Disable'/" /etc/config/alpha
                ;;
        esac
    fi
done

# Configure uhttpd & PHP8
log_status "INFO" "Configure uhttpd & PHP8..."

# Configure uhttpd
uci set uhttpd.main.ubus_prefix='/ubus'
uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
uci set uhttpd.main.index_page='cgi-bin/luci'
uci add_list uhttpd.main.index_page='index.html'
uci add_list uhttpd.main.index_page='index.php'
uci commit uhttpd

# Configure PHP
cp /etc/php.ini /etc/php.ini.bak
sed -i 's|^memory_limit = .*|memory_limit = 128M|g' /etc/php.ini
sed -i 's|^max_execution_time = .*|max_execution_time = 60|g' /etc/php.ini
sed -i 's|^display_errors = .*|display_errors = Off|g' /etc/php.ini
sed -i 's|^;*date\.timezone =.*|date.timezone = Asia/Jakarta|g' /etc/php.ini

ln -sf /usr/lib/php8
/etc/init.d/uhttpd restart > /dev/null

# Footer
log_status "INFO" "========================================="
log_status "INFO" "XIDZs-WRT Setup Script Finished"
log_status "INFO" "Check log file: /root/setup-xidzswrt.log"
log_status "INFO" "========================================="

# Cleanup & exit
sync
rm -rf /etc/uci-defaults/$(basename "$0")
exit 0