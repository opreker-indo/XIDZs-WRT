#!/bin/bash


. ./shell/INCLUDE.sh

if [ -z "$1" ]; then
    log "ERROR" "Parameter required"
    log "INFO" "Usage: $0 {openclash|nikki|fusiontunx|passwall|nikki-passwall|nikki-fusiontunx|openclash-nikki|openclash-fusiontunx|openclash-nikki-passwall|no-tunnel}"
    exit 1
fi

PACKAGES="$1"
log "INFO" "Packages to install: ${PACKAGES}"

get_package_extension() {
    local version="$1"
    local major_version=$(echo "$version" | cut -d'.' -f1)
    
    if [[ "$major_version" -ge 25 ]]; then
        echo "apk"
    else
        echo "ipk"
    fi
}

generate_openclash_urls() {
    local pkg_ext=$(get_package_extension "${VEROP}")
    
    if [[ "${ARCH_3}" == "x86_64" ]]; then
        meta_file="mihomo-linux-${ARCH_1}-compatible"
    else
        meta_file="mihomo-linux-${ARCH_1}"
    fi
    
    openclash_core=$(curl -s "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" | grep "browser_download_url" | grep -oE "https.*${meta_file}-v[0-9]+\.[0-9]+\.[0-9]+\.gz" | head -n 1)
    openclash_file_ipk="luci-app-openclash"
    openclash_file_ipk_down=$(curl -s "https://api.github.com/repos/de-quenx/OpenClash-x/releases" | grep "browser_download_url" | grep -oE "https.*${openclash_file_ipk}.*.${pkg_ext}" | head -n 1)
}

generate_passwall_urls() {
    local pkg_ext=$(get_package_extension "${VEROP}")
    
    passwall_core_file_zip="passwall_packages_${pkg_ext}_${ARCH_3}"
    passwall_file_ipk_down=$(curl -s "https://api.github.com/repos/Openwrt-Passwall/openwrt-passwall/releases" | grep "browser_download_url" | grep -oE "https.*luci-app-passwall[-_][0-9]+\.[0-9]+\.[0-9]+-r[0-9]+.*\.${pkg_ext}" | head -n 1)
    passwall_core_file_zip_down=$(curl -s "https://api.github.com/repos/Openwrt-Passwall/openwrt-passwall/releases" | grep "browser_download_url" | grep -oE "https.*${passwall_core_file_zip}.*.zip" | head -n 1)
}

generate_nikki_urls() {
    nikki_file_ipk="nikki_${ARCH_3}-openwrt-${VEROP}"
    if [[ "${VEROP}" == "23.05" ]]; then
        nikki_file_ipk_down=$(curl -s "https://api.github.com/repos/Yogxx/OpenWrt-nikkiku/releases/tags/v1.25.0" | grep "browser_download_url" | grep -oE "https.*${nikki_file_ipk}.*.tar.gz" | head -n 1)
    else
        nikki_file_ipk_down=$(curl -s "https://api.github.com/repos/syntax-xidz/nikki-x/releases" | grep "browser_download_url" | grep -oE "https.*${nikki_file_ipk}.*.tar.gz" | head -n 1)
    fi
}

generate_fusiontunx_urls() {
    fusiontunx_file_ipk="luci-app-fusiontunx"
    fusiontunx_core_ipk="fusiontunx"
    fusiontunx_file_ipk_down=$(curl -s "https://api.github.com/repos/bobbyunknown/FusionTunX/releases" | grep "browser_download_url" | grep -oE "https.*${fusiontunx_file_ipk}.*.ipk" | head -n 1)
    fusiontunx_core_ipk_down=$(curl -s "https://api.github.com/repos/bobbyunknown/FusionTunX/releases" | grep "browser_download_url" | grep -oE "https.*fusiontunx_[^\"]*${ARCH_3}[^\"]*\.ipk" | head -n 1)
}

setup_openclash() {
    local pkg_ext=$(get_package_extension "${VEROP}")
    generate_openclash_urls
    log "INFO" "Downloading OpenClash packages (${pkg_ext} format)"
    
    ariadl "${openclash_file_ipk_down}" "packages/openclash.${pkg_ext}"
    ariadl "${openclash_core}" "files/etc/openclash/core/clash_meta.gz"
    
    log "INFO" "Configuring OpenClash Tunnel"
    gzip -df "files/etc/openclash/core/clash_meta.gz" || error_msg "Error: Failed to extract clash_meta"
    chmod 755 "files/etc/openclash/core/clash_meta" || error_msg "Error: Failed to set permission for clash_meta"
    chmod 755 "files/etc/openclash/Country.mmdb" || error_msg "Error: Failed to set permission for Country.mmdb"
    chmod 755 "files/etc/openclash/GeoIP.dat" || error_msg "Error: Failed to set permission for GeoIP.dat"
    chmod 755 "files/etc/openclash/GeoSite.dat" || error_msg "Error: Failed to set permission for GeoSite.dat"
    
    sed -i "/# Tunnel/a\\
echo \"configurasi tunnel\"\\
ln -sf /etc/openclash/history/xidzs.db /etc/openclash/cache.db\\
ln -sf /etc/openclash/core/clash_meta /etc/openclash/clash" "files/etc/uci-defaults/99-init-settings.sh" || error_msg "Error: Failed to add symlinks to uci-defaults"
}

setup_passwall() {
    local pkg_ext=$(get_package_extension "${VEROP}")
    generate_passwall_urls
    log "INFO" "Downloading PassWall packages (${pkg_ext} format)"
    
    ariadl "${passwall_file_ipk_down}" "packages/passwall.${pkg_ext}"
    ariadl "${passwall_core_file_zip_down}" "packages/passwall.zip"
    
    log "INFO" "Configuring PassWall Tunnel"
    unzip -qq "packages/passwall.zip" -d "packages" && rm "packages/passwall.zip" || error_msg "Error: Failed to extract PassWall package"
}

setup_nikki() {
    generate_nikki_urls
    log "INFO" "Downloading Nikki packages"
    
    ariadl "${nikki_file_ipk_down}" "packages/nikki.tar.gz"
    
    log "INFO" "Configuring Nikki Tunnel"
    tar -xzvf "packages/nikki.tar.gz" -C "packages" > /dev/null 2>&1 && rm "packages/nikki.tar.gz" || error_msg "Error: Failed to extract Nikki package"
    
    chmod 755 "files/etc/nikki/run/Country.mmdb" || error_msg "Error: Failed to set permission for nikki Country.mmdb"
    chmod 755 "files/etc/nikki/run/GeoIP.dat" || error_msg "Error: Failed to set permission for nikki GeoIP.dat"
    chmod 755 "files/etc/nikki/run/GeoSite.dat" || error_msg "Error: Failed to set permission for nikki GeoSite.dat"
}

setup_fusiontunx() {
    generate_fusiontunx_urls
    log "INFO" "Downloading fusiontunx packages"
    
    ariadl "${fusiontunx_file_ipk_down}" "packages/luci-app-fusiontunx.ipk"
    ariadl "${fusiontunx_core_ipk_down}" "packages/fusiontunx.ipk"
    
    log "INFO" "Configuring fusiontunx Tunnel"
}

clean_openclash() {
    log "INFO" "Cleaning OpenClash configuration files and folders"
    rm -rf "files/etc/openclash" || error_msg "Error: Failed to remove OpenClash configuration files"
}

clean_passwall() {
    log "INFO" "Cleaning PassWall configuration files and folders"
    rm -f "files/etc/config/passwall" || error_msg "Error: Failed to remove PassWall configuration files"
}

clean_nikki() {
    log "INFO" "Cleaning Nikki configuration files and folders"
    rm -rf "files/etc/nikki" || error_msg "Error: Failed to remove Nikki configuration files"
    rm -f "files/etc/config/nikki" || error_msg "Error: Failed to remove Nikki config files"
}

clean_fusiontunx() {
    log "INFO" "Cleaning fusiontunx configuration files and folders"
    rm -rf "files/etc/fusiontunx" || error_msg "Error: Failed to remove fusiontunx configuration files"
}

case "${PACKAGES}" in
    openclash)
        setup_openclash
        clean_passwall
        clean_nikki
        clean_fusiontunx
        ;;
    nikki)
        setup_nikki
        clean_openclash
        clean_passwall
        clean_fusiontunx
        ;;
    fusiontunx)
        setup_fusiontunx
        clean_openclash
        clean_passwall
        clean_nikki
        ;;
    passwall)
        setup_passwall
        clean_openclash
        clean_nikki
        clean_fusiontunx
        ;;
    nikki-passwall)
        setup_nikki
        setup_passwall
        clean_openclash
        clean_fusiontunx
        ;;
    nikki-fusiontunx)
        setup_nikki
        setup_fusiontunx
        clean_openclash
        clean_passwall
        ;;
    openclash-nikki)
        setup_openclash
        setup_nikki
        clean_passwall
        clean_fusiontunx
        ;;
    openclash-passwall)
        setup_openclash
        setup_passwall
        clean_nikki
        clean_fusiontunx
        ;;
    openclash-fusiontunx)
        setup_openclash
        setup_fusiontunx
        clean_passwall
        clean_nikki
        ;;
    openclash-nikki-passwall)
        setup_openclash
        setup_nikki
        setup_passwall
        clean_fusiontunx
        ;;
    no-tunnel)
        clean_openclash
        clean_passwall
        clean_nikki
        clean_fusiontunx
        ;;
    *)
        log "ERROR" "Invalid package option: ${PACKAGES}"
        log "INFO" "Available options: openclash, nikki, fusiontunx, passwall, nikki-passwall, nikki-fusiontunx, openclash-nikki, openclash-fusiontunx, openclash-nikki-passwall, no-tunnel"
        exit 1
        ;;
esac

if [ "$?" -ne 0 ]; then
    error_msg "Download or extraction failed."
    exit 1
else
    log "INFO" "Tunnel package installation completed successfully for: ${PACKAGES}"
fi
