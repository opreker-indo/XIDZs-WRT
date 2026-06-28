#!/bin/sh
set -e

# Auto-rerun with sudo if not root
USER_ID="$(id -u)"
if [ "${USER_ID}" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

show_usage() {
    cat << EOF
Usage: $0 -t TYPE -b BRANCH -d DEVICE -v TUNNEL [-c]

Options:
    -t TYPE       Build type: ophub, official, ulo
    -b BRANCH     Release branch: openwrt:24.10.5, openwrt:23.05.6, immortalwrt:24.10.5, immortalwrt:23.05.6
    -d DEVICE     Target device (see list below)
    -v TUNNEL     Tunnel VPN: openclash, openclash-nikki, openclash-fusiontunx, openclash-nikki-passwall, no-tunnel
    -c            Run 'make clean' before build (optional)
    -h            Show this help message

OPHUB Devices:
    s905-mxqpro-plus, s905-beelink-mini, s905lb-q96-mini, s905w-tx3-mini, s905w-x96-mini,
    s905l-mibox-4, s905l2-m301a, s905x-b860h, s905x-b860h-modsdcard, s905x-hg680p,
    s905x-hg680p-modsdcard, s905x2-b860hv5, s905x2-hg680-fj, s905x2-x96max-2g, s905x2-x96max-4g,
    s905x3-hk1, s905x3-x96air-100mb, s905x3-x96air-1gb, s905x3-x96max-100mb, s905x3-x96max-1gb,
    s905x4-advan, s912-nexbox-a1, s912-nexbox-a2, s922x-gt-king-pro, rk3318-box,
    firefly-rk3328, rk3399-king3399

OFFICIAL Devices:
    nanopi-r2s, nanopi-r3s, nanopi-r4s, orangepi-pc2, orangepi-r1plus, orangepi-r1plus-lts,
    rpi-2b, rpi-3b, rpi-4b, x86-64

ULO Devices:
    h5-orangepi-zeroplus, h5-orangepi-zeroplus2, h6-orangepi-3, h6-orangepi-3lts,
    h616-orangepi-zero2, h618-orangepi-zero3, orangepi-3b, s905x2-b860hv5-v1,
    s905x2-b860hv5-v2, s905x2-b860hv5-v3, s905x2-hg680-fj-v1, s905x2-hg680-fj-v2,
    s905x2-hg680-fj-v3, s905x4-v1, s905x4-v2, s905x4-v3, s905x4-v4

Examples:
    $0 -t ophub -b openwrt:24.10.4 -d s905x-b860h -v openclash -c
    $0 -t official -b immortalwrt:23.05.6 -d nanopi-r4s -v openclash-nikki
    $0 -t ulo -b openwrt:24.10.4 -d h618-orangepi-zero3 -v no-tunnel

EOF
}

setup_ophub_device() {
    PROFILE="generic"
    TARGET_SYSTEM="armsr/armv8"
    TARGET_NAME="armsr-armv8"
    ARCH_1="arm64"
    ARCH_2="aarch64"
    ARCH_3="aarch64_generic"
    
    case "$1" in
        s905-mxqpro-plus) TARGET_BUILD="s905-mxqpro-plus"; KERNEL="5.15.y_6.1.y" ;;
        s905-beelink-mini) TARGET_BUILD="s905-beelink-mini"; KERNEL="5.15.y_6.1.y" ;;
        s905lb-q96-mini) TARGET_BUILD="s905lb-q96-mini"; KERNEL="5.15.y_6.1.y" ;;
        s905w-tx3-mini) TARGET_BUILD="s905w"; KERNEL="5.15.y_6.1.y" ;;
        s905w-x96-mini) TARGET_BUILD="s905w-x96-mini"; KERNEL="5.15.y_6.1.y" ;;
        s905l-mibox-4) TARGET_BUILD="s905l-mg101"; KERNEL="5.15.y_6.1.y" ;;
        s905l2-m301a) TARGET_BUILD="s905l2"; KERNEL="5.15.y_6.1.y" ;;
        s905x-b860h) TARGET_BUILD="s905x-b860h"; KERNEL="5.15.y_6.1.y_6.6.y_6.12.y" ;;
        s905x-b860h-modsdcard) TARGET_BUILD="s905x-b860h"; KERNEL="5.15.y_6.1.y_6.6.y_6.12.y"; MODSDCARD=1 ;;
        s905x-hg680p) TARGET_BUILD="s905x"; KERNEL="5.15.y_6.1.y_6.6.y_6.12.y" ;;
        s905x-hg680p-modsdcard) TARGET_BUILD="s905x"; KERNEL="5.15.y_6.1.y_6.6.y_6.12.y"; MODSDCARD=1 ;;
        s905x2-b860hv5) TARGET_BUILD="s905x2-b860h-v5"; KERNEL="5.15.y_6.1.y" ;;
        s905x2-hg680-fj) TARGET_BUILD="s905x2-hg680-fj"; KERNEL="5.15.y_6.1.y_6.6.y" ;;
        s905x2-x96max-2g) TARGET_BUILD="s905x2-x96max-2g"; KERNEL="5.15.y_6.1.y" ;;
        s905x2-x96max-4g) TARGET_BUILD="s905x2"; KERNEL="5.15.y_6.1.y" ;;
        s905x3-hk1) TARGET_BUILD="s905x3-hk1"; KERNEL="5.15.y_6.1.y" ;;
        s905x3-x96air-100mb) TARGET_BUILD="s905x3-x96air"; KERNEL="5.15.y_6.1.y" ;;
        s905x3-x96air-1gb) TARGET_BUILD="s905x3-x96air-gb"; KERNEL="5.15.y_6.1.y" ;;
        s905x3-x96max-100mb) TARGET_BUILD="s905x3"; KERNEL="5.15.y_6.1.y" ;;
        s905x3-x96max-1gb) TARGET_BUILD="s905x3-x96max"; KERNEL="5.15.y_6.1.y" ;;
        s905x4-advan) TARGET_BUILD="s905x4-advan"; KERNEL="6.1.y_6.6.y_6.12.y" ;;
        s912-nexbox-a1) TARGET_BUILD="s912-nexbox-a1"; KERNEL="5.15.y_6.1.y" ;;
        s912-nexbox-a2) TARGET_BUILD="s912-nexbox-a2"; KERNEL="5.15.y_6.1.y" ;;
        s922x-gt-king-pro) TARGET_BUILD="s922x"; KERNEL="5.15.y_6.1.y" ;;
        firefly-rk3328) TARGET_BUILD="renegade-rk3328"; KERNEL="5.15.y_6.1.y" ;;
        rk3318-box) TARGET_BUILD="rk3318-box"; KERNEL="5.15.y_6.1.y" ;;
        rk3399-king3399) TARGET_BUILD="king3399"; KERNEL="6.1.y" ;;
        *) echo "Error: Unknown OPHUB device: $1"; exit 1 ;;
    esac
}

setup_official_device() {
    case "$1" in
        nanopi-r2s)
            PROFILE="friendlyarm_nanopi-r2s"
            TARGET_SYSTEM="rockchip/armv8"
            TARGET_NAME="rockchip-armv8"
            ARCH_1="arm64"; ARCH_2="aarch64"; ARCH_3="aarch64_generic"
            ;;
        nanopi-r3s)
            PROFILE="friendlyarm_nanopi-r3s"
            TARGET_SYSTEM="rockchip/armv8"
            TARGET_NAME="rockchip-armv8"
            ARCH_1="arm64"; ARCH_2="aarch64"; ARCH_3="aarch64_generic"
            ;;
        nanopi-r4s)
            PROFILE="friendlyarm_nanopi-r4s"
            TARGET_SYSTEM="rockchip/armv8"
            TARGET_NAME="rockchip-armv8"
            ARCH_1="arm64"; ARCH_2="aarch64"; ARCH_3="aarch64_generic"
            ;;
        orangepi-pc2)
            PROFILE="xunlong_orangepi-pc2"
            TARGET_SYSTEM="sunxi/cortexa53"
            TARGET_NAME="sunxi-cortexa53"
            ARCH_1="arm64"; ARCH_2="aarch64"; ARCH_3="aarch64_cortex-a53"
            ;;
        orangepi-r1plus)
            PROFILE="xunlong_orangepi-r1-plus"
            TARGET_SYSTEM="rockchip/armv8"
            TARGET_NAME="rockchip-armv8"
            ARCH_1="arm64"; ARCH_2="aarch64"; ARCH_3="aarch64_generic"
            ;;
        orangepi-r1plus-lts)
            PROFILE="xunlong_orangepi-r1-plus-lts"
            TARGET_SYSTEM="rockchip/armv8"
            TARGET_NAME="rockchip-armv8"
            ARCH_1="arm64"; ARCH_2="aarch64"; ARCH_3="aarch64_generic"
            ;;
        rpi-2b)
            PROFILE="rpi-2"
            TARGET_SYSTEM="bcm27xx/bcm2709"
            TARGET_NAME="bcm27xx-bcm2709"
            ARCH_1="armv7"; ARCH_2="arm"; ARCH_3="arm_cortex-a7_neon-vfpv4"
            ;;
        rpi-3b)
            PROFILE="rpi-3"
            TARGET_SYSTEM="bcm27xx/bcm2710"
            TARGET_NAME="bcm27xx-bcm2710"
            ARCH_1="arm64"; ARCH_2="aarch64"; ARCH_3="aarch64_cortex-a53"
            ;;
        rpi-4b)
            PROFILE="rpi-4"
            TARGET_SYSTEM="bcm27xx/bcm2711"
            TARGET_NAME="bcm27xx-bcm2711"
            ARCH_1="arm64"; ARCH_2="aarch64"; ARCH_3="aarch64_cortex-a72"
            ;;
        x86-64)
            PROFILE="generic"
            TARGET_SYSTEM="x86/64"
            TARGET_NAME="x86-64"
            ARCH_1="amd64"; ARCH_2="x86_64"; ARCH_3="x86_64"
            ;;
        *) echo "Error: Unknown OFFICIAL device: $1"; exit 1 ;;
    esac
}

setup_ulo_device() {
    PROFILE="generic"
    TARGET_SYSTEM="armsr/armv8"
    TARGET_NAME="armsr-armv8"
    ARCH_1="arm64"
    ARCH_2="aarch64"
    ARCH_3="aarch64_generic"
    
    case "$1" in
        h5-orangepi-zeroplus) TARGET_BUILD="h5-orangepi-zeroplus"; KERNEL="6.6.6-AW64-DBAI" ;;
        h5-orangepi-zeroplus2) TARGET_BUILD="h5-orangepi-zeroplus2"; KERNEL="6.6.6-AW64-DBAI" ;;
        h6-orangepi-3) TARGET_BUILD="h6-orangepi-3"; KERNEL="6.1.31-AW64-DBAI" ;;
        h6-orangepi-3lts) TARGET_BUILD="h6-orangepi-3lts"; KERNEL="6.1.31-AW64-DBAI" ;;
        h616-orangepi-zero2) TARGET_BUILD="h616-orangepi-zero2"; KERNEL="6.1.31-AW64-DBAI" ;;
        h618-orangepi-zero3) TARGET_BUILD="h618-orangepi-zero3"; KERNEL="6.1.31-AW64-DBAI" ;;
        orangepi-3b) TARGET_BUILD="orangepi-3b"; KERNEL="6.1.31-AW64-DBAI" ;;
        s905x2-b860hv5-v1) TARGET_BUILD="s905x2-b860hv5"; KERNEL="6.1.66-DBAI" ;;
        s905x2-b860hv5-v2) TARGET_BUILD="s905x2-b860hv5"; KERNEL="6.2.2" ;;
        s905x2-b860hv5-v3) TARGET_BUILD="s905x2-b860hv5"; KERNEL="6.4.11" ;;
        s905x2-hg680-fj-v1) TARGET_BUILD="s905x2-hg680-fj"; KERNEL="6.1.66-DBAI" ;;
        s905x2-hg680-fj-v2) TARGET_BUILD="s905x2-hg680-fj"; KERNEL="6.2.2" ;;
        s905x2-hg680-fj-v3) TARGET_BUILD="s905x2-hg680-fj"; KERNEL="6.4.11" ;;
        s905x4-v1) TARGET_BUILD="s905x4"; KERNEL="6.1.66-DBAI" ;;
        s905x4-v2) TARGET_BUILD="s905x4"; KERNEL="5.4.279" ;;
        s905x4-v3) TARGET_BUILD="s905x4"; KERNEL="6.6.6" ;;
        s905x4-v4) TARGET_BUILD="s905x4"; KERNEL="6.6.66" ;;
        *) echo "Error: Unknown ULO device: $1"; exit 1 ;;
    esac
}

TYPE=""
BRANCH=""
DEVICE=""
TUNNEL=""
CLEAN=0
MODSDCARD=0

while getopts "t:b:d:v:ch" opt; do
    case ${opt} in
        t) TYPE="${OPTARG}" ;;
        b) BRANCH="${OPTARG}" ;;
        d) DEVICE="${OPTARG}" ;;
        v) TUNNEL="${OPTARG}" ;;
        c) CLEAN=1 ;;
        h) show_usage; exit 0 ;;
        *) show_usage; exit 1 ;;
    esac
done

if [ -z "${TYPE}" ] || [ -z "${BRANCH}" ] || [ -z "${DEVICE}" ] || [ -z "${TUNNEL}" ]; then
    echo "Error: Missing required arguments"
    show_usage
    exit 1
fi

case "${TYPE}" in
    ophub|official|ulo) ;;
    *) echo "Error: Invalid type. Must be: ophub, official, or ulo"; exit 1 ;;
esac

case "${TUNNEL}" in
    openclash|openclash-nikki|openclash-fusiontunx|openclash-nikki-passwall|openclash-passwall|no-tunnel) ;;
    *) echo "Error: Invalid tunnel option"; exit 1 ;;
esac

BASE="${BRANCH%:*}"
VERSION="${BRANCH#*:}"
VEROP="$(echo "${VERSION}" | awk -F. '{print $1"."$2}')"
DOWNLOAD_BASE="https://downloads.${BASE}.org"
BUILD_DIR="/tmp/openwrt-build"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATE=$(date +'%d%m%Y')

export TZ="Asia/Jakarta"
export DEBIAN_FRONTEND=noninteractive
export BASE VERSION VEROP TYPE TUNNEL DATE
export BRANCH="${VERSION}"
export WORKING_DIR="imagebuilder"
export GITHUB_WORKSPACE="${BUILD_DIR}"

# Set OP_BASE (capitalized name for firmware renaming)
case "${BASE}" in
    openwrt) export OP_BASE="OpenWrt" ;;
    immortalwrt) export OP_BASE="ImmortalWrt" ;;
    *) export OP_BASE="${BASE}" ;;
esac

# Clean PATH - remove relative paths and tilde paths
CLEAN_PATH="$(echo "${PATH}" | tr ':' '\n' | grep -v '^\~' | grep -v '^\.' | tr '\n' ':' | sed 's/:$//')"
export PATH="${CLEAN_PATH}"

echo "=== Build Configuration ==="
echo "Type: ${TYPE}"
echo "Branch: ${BRANCH} (${BASE} ${VERSION})"
echo "Device: ${DEVICE}"
echo "Tunnel: ${TUNNEL}"
echo "Clean: ${CLEAN}"
echo "Build Dir: ${BUILD_DIR}"
echo "=========================="

if [ "${CLEAN}" -eq 1 ]; then
    echo "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
fi

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

case "${TYPE}" in
    ophub) setup_ophub_device "${DEVICE}" ;;
    official) setup_official_device "${DEVICE}" ;;
    ulo) setup_ulo_device "${DEVICE}" ;;
    *) echo "Error: Invalid type"; exit 1 ;;
esac

export PROFILE TARGET_SYSTEM TARGET_NAME ARCH_1 ARCH_2 ARCH_3 TARGET_BUILD KERNEL

if [ ! -d "${BUILD_DIR}/imagebuilder" ]; then
    CURVER=$(echo "${VERSION}" | cut -d'.' -f1)
    archive_ext=$([ "${CURVER}" = "24" ] && echo "tar.zst" || echo "tar.xz")

    RELEASE="${DOWNLOAD_BASE}/releases/${VERSION}/targets/${TARGET_SYSTEM}/${BASE}-imagebuilder-${VERSION}-${TARGET_NAME}.Linux-x86_64.${archive_ext}"

    echo "Downloading ImageBuilder..."
    curl -# -L -O "${RELEASE}"

    echo "Extracting archive..."
    case "${archive_ext}" in
        tar.xz) tar -xJf ./*-imagebuilder-* && rm -f ./*-imagebuilder-*.tar.xz ;;
        tar.zst) tar --use-compress-program=unzstd -xf ./*-imagebuilder-* && rm -f ./*-imagebuilder-*.tar.zst ;;
        *) echo "Error: Unknown archive format"; exit 1 ;;
    esac

    mv ./*-imagebuilder-* "${BUILD_DIR}/imagebuilder"
    cp -r "${SCRIPT_DIR}/files" "${SCRIPT_DIR}/packages" "${SCRIPT_DIR}/shell" "${BUILD_DIR}/imagebuilder/"
else
    echo "Using existing ImageBuilder..."
    cp -r "${SCRIPT_DIR}/files" "${SCRIPT_DIR}/packages" "${SCRIPT_DIR}/shell" "${BUILD_DIR}/imagebuilder/"
fi

cd "${BUILD_DIR}/imagebuilder"

echo "Downloading external packages..."
chmod +x shell/PACKAGES.sh
./shell/PACKAGES.sh "${CLEAN}"

echo "Applying patches..."
chmod +x shell/PATCH.sh
./shell/PATCH.sh

echo "Applying customizations..."
chmod +x shell/MISC.sh
./shell/MISC.sh

echo "Configuring tunnel..."
chmod +x shell/TUNNEL.sh
./shell/TUNNEL.sh "${TUNNEL}"

mkdir -p compiled_images
chmod +x shell/MAKE-IMAGE.sh

if [ "${CLEAN}" -eq 1 ]; then
    echo "Running make clean..."
    make clean
fi

echo "Building firmware..."
./shell/MAKE-IMAGE.sh "${PROFILE}" "${TUNNEL}"

case "${TYPE}" in
    ophub|ulo)
        for file in bin/targets/"${TARGET_SYSTEM}"/*-rootfs.tar.gz; do
            if [ -f "${file}" ]; then
                basename=$(basename "${file}")
                newname="${basename%-rootfs.tar.gz}_${TUNNEL}-rootfs.tar.gz"
                mv "${file}" "compiled_images/${newname}"
            fi
        done
        
        echo "Repacking firmware..."
        chmod +x shell/REPACKWRT.sh
        ./shell/REPACKWRT.sh "${TYPE}" "${TARGET_BUILD}" "${KERNEL}" "${TUNNEL}"
        
        if [ "${MODSDCARD}" -eq 1 ]; then
            echo "Modifying SDCard..."
            chmod +x shell/MODSDCARD.sh
            ./shell/MODSDCARD.sh
        fi
        ;;
    official)
        for file in bin/targets/"${TARGET_SYSTEM}"/*.img.gz; do
            [ -f "${file}" ] && mv "${file}" compiled_images/
        done
        ;;
    *) echo "Error: Invalid type"; exit 1 ;;
esac

echo "Renaming firmware..."
chmod +x shell/RENAMEFW.sh
./shell/RENAMEFW.sh

echo "=== Build Complete ==="
echo "Output files:"
ls -lh compiled_images/
echo "======================="
