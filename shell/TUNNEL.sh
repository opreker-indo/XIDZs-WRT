#!/bin/bash


. ./shell/INCLUDE.sh

if [ -z "$1" ]; then
    log "ERROR" "Parameter required"
    log "INFO" "Usage: $0 {nikki|fusiontunx|passwall|nikki-passwall|nikki-fusiontunx|no-tunnel}"
    exit 1
fi

PACKAGES="$1"
log "INFO" "Packages to install: ${PACKAGES}"

generate_passwall_urls() {
    local pkg_ext=$(get_package_extension "${VEROP}")
    
    passwall_core_file_zip="passwall_packages_${pkg_ext}_${ARCH_3}"
    passwall_url=$(curl -s "https://api.github.com/repos/Openwrt-Passwall/openwrt-passwall/releases" | grep "browser_download_url" | grep -oE "https.*luci-app-passwall[-_][0-9]+\.[0-9]+\.[0-9]+-r[0-9]+.*\.${pkg_ext}" | head -n 1)
    passwall_core_file_zip_down=$(curl -s "https://api.github.com/repos/Openwrt-Passwall/openwrt-passwall/releases" | grep "browser_download_url" | grep -oE "https.*${passwall_core_file_zip}.*.zip" | head -n 1)
}

generate_nikki_urls() {
    nikki_pkg="nikki_${ARCH_3}-openwrt-${VEROP}"
    if [[ "${VEROP}" == "23.05" ]]; then
        nikki_url=$(curl -s "https://api.github.com/repos/Yogxx/OpenWrt-nikkiku/releases/tags/v1.25.0" | grep "browser_download_url" | grep -oE "https.*${nikki_pkg}.*.tar.gz" | head -n 1)
    else
        nikki_url=$(curl -s "https://api.github.com/repos/syntax-xidz/nikki-x/releases" | grep "browser_download_url" | grep -oE "https.*${nikki_pkg}.*.tar.gz" | head -n 1)
    fi
}

generate_fusiontunx_urls() {
    local pkg_ext=$(get_package_extension "${VEROP}")
    fusiontunx_luci_pkg="luci-app-fusiontunx"
    fusiontunx_core_pkg="fusiontunx"
    fusiontunx_luci_url=$(curl -s "https://api.github.com/repos/bobbyunknown/FusionTunX/releases" | grep "browser_download_url" | grep -oE "https.*${fusiontunx_luci_pkg}.*.${pkg_ext}" | head -n 1)
    fusiontunx_core_url=$(curl -s "https://api.github.com/repos/bobbyunknown/FusionTunX/releases" | grep "browser_download_url" | grep -oE "https.*fusiontunx_[^\"]*${ARCH_3}[^\"]*\.${pkg_ext}" | head -n 1)
}

setup_passwall() {
    local pkg_ext=$(get_package_extension "${VEROP}")
    generate_passwall_urls
    log "INFO" "Downloading PassWall packages (${pkg_ext} format)"
    
    ariadl "${passwall_url}" "packages/passwall.${pkg_ext}"
    ariadl "${passwall_core_file_zip_down}" "packages/passwall.zip"
    
    log "INFO" "Configuring PassWall Tunnel"
    unzip -qq "packages/passwall.zip" -d "packages" && rm "packages/passwall.zip" || error_msg "Error: Failed to extract PassWall package"
}

setup_nikki() {
    generate_nikki_urls
    log "INFO" "Downloading Nikki packages"
    
    ariadl "${nikki_url}" "packages/nikki.tar.gz"
    
    log "INFO" "Configuring Nikki Tunnel"
    tar -xzvf "packages/nikki.tar.gz" -C "packages" > /dev/null 2>&1 && rm "packages/nikki.tar.gz" || error_msg "Error: Failed to extract Nikki package"
    
    chmod 755 "files/etc/nikki/run/Country.mmdb" || error_msg "Error: Failed to set permission for nikki Country.mmdb"
    chmod 755 "files/etc/nikki/run/GeoIP.dat" || error_msg "Error: Failed to set permission for nikki GeoIP.dat"
    chmod 755 "files/etc/nikki/run/GeoSite.dat" || error_msg "Error: Failed to set permission for nikki GeoSite.dat"
}

setup_fusiontunx() {
    local pkg_ext=$(get_package_extension "${VEROP}")
    generate_fusiontunx_urls
    log "INFO" "Downloading fusiontunx packages (${pkg_ext} format)"
    
    ariadl "${fusiontunx_luci_url}" "packages/luci-app-fusiontunx.${pkg_ext}"
    ariadl "${fusiontunx_core_url}" "packages/fusiontunx.${pkg_ext}"
    
    log "INFO" "Configuring fusiontunx Tunnel"
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
    nikki)
        setup_nikki
        clean_passwall
        clean_fusiontunx
        ;;
    fusiontunx)
        setup_fusiontunx
        clean_passwall
        clean_nikki
        ;;
    passwall)
        setup_passwall
        clean_nikki
        clean_fusiontunx
        ;;
    nikki-passwall)
        setup_nikki
        setup_passwall
        clean_fusiontunx
        ;;
    nikki-fusiontunx)
        setup_nikki
        setup_fusiontunx
        clean_passwall
        ;;
    no-tunnel)
        clean_passwall
        clean_nikki
        clean_fusiontunx
        ;;
    *)
        log "ERROR" "Invalid package option: ${PACKAGES}"
        log "INFO" "Available options: nikki, fusiontunx, passwall, nikki-passwall, nikki-fusiontunx, no-tunnel"
        exit 1
        ;;
esac

if [ "$?" -ne 0 ]; then
    error_msg "Download or extraction failed."
    exit 1
else
    log "INFO" "Tunnel package installation completed successfully for: ${PACKAGES}"
fi
