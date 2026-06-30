#!/bin/bash

. ./shell/INCLUDE.sh

# Initialize environment
init_environment() {
    log "INFO" "Start Builder Patch!"
    log "INFO" "Current Path: $PWD"
    
    cd "${GITHUB_WORKSPACE}/${WORKING_DIR}" || error "Failed to change directory"
}

# Apply specific patches
apply_distro_patches() {
    if [[ "${BASE}" == "openwrt" ]]; then
        log "INFO" "Applying OpenWrt specific patches"
    elif [[ "${BASE}" == "immortalwrt" ]]; then
        log "INFO" "Applying ImmortalWrt specific patches"
        # cpufreq
        sed -i "\|luci-app-cpufreq|d" include/target.mk
    else
        log "INFO" "Unknown distribution: ${BASE}"
    fi
}

# Patch package signature and add custom feeds
patch_signature_check() {
    log "INFO" "Disabling package signature"
    
    local repo_file="repositories"
    log "INFO" "Using repository file: ${repo_file}"
    
    # Disable signature check in .config (must be unset, not =n)
    sed -i '/CONFIG_SIGNATURE_CHECK/d' .config
    echo "# CONFIG_SIGNATURE_CHECK is not set" >> .config
    
    # Add fantastic-packages feeds
    log "INFO" "Adding fantastic-packages APK feeds for ${ARCH_3}"
    {
        echo "https://fantastic-packages.github.io/releases/25.12/packages/${ARCH_3}/luci/packages.adb"
        echo "https://fantastic-packages.github.io/releases/25.12/packages/${ARCH_3}/packages/packages.adb"
        echo "https://fantastic-packages.github.io/releases/25.12/packages/${ARCH_3}/special/packages.adb"
    } >> "${repo_file}"
}

# Force installation options in Makefile
patch_makefile() {
    log "INFO" "Skipping Makefile force options (apk format)"
}

# Configure partition sizes
configure_partitions() {
    log "INFO" "Configuring partition sizes"
    # Set kernel and rootfs partition sizes
    sed -i "s|CONFIG_TARGET_KERNEL_PARTSIZE=.*|CONFIG_TARGET_KERNEL_PARTSIZE=256|" .config
    sed -i "s|CONFIG_TARGET_ROOTFS_PARTSIZE=.*|CONFIG_TARGET_ROOTFS_PARTSIZE=512|" .config
}

# Apply Amlogic-specific configurations
configure_amlogic() {
    if [[ "${TYPE}" == "OPHUB" || "${TYPE}" == "ULO" ]]; then
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        log "INFO" "System type: ${TYPE}"
    fi
}

# Apply x86_64 and i386 configurations
configure_x86() {
    if [[ "${ARCH_2}" == "x86_64" ]] || [[ "${ARCH_2}" == "i386" ]]; then
        log "INFO" "Applying ${ARCH_2} configurations"
        # disable iso
        sed -i "s|CONFIG_ISO_IMAGES=y|# CONFIG_ISO_IMAGES is not set|" .config
        # disable vhdx
        sed -i "s|CONFIG_VHDX_IMAGES=y|# CONFIG_VHDX_IMAGES is not set|" .config  
    fi
}

# Main execution
main() {
    init_environment
    apply_distro_patches
    patch_signature_check
    patch_makefile
    configure_partitions
    configure_amlogic
    configure_x86

    # Enable parallel squashfs compression
    sed -i "s/SQUASHFSOPT := -b \$(SQUASHFS_BLOCKSIZE)/SQUASHFSOPT := -b \$(SQUASHFS_BLOCKSIZE) -processors \$(shell nproc)/" include/image.mk

    log "INFO" "Builder patch completed successfully!"
}

# Execute main function
main
