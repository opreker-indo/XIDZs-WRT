#!/bin/bash

. ./shell/INCLUDE.sh

# All packages are installed from fantastic-packages APK feeds (configured in PATCH.sh)
# No individual package downloads needed.

main() {
    log "INFO" "All packages provided by fantastic-packages feeds"
    log "INFO" "No custom package downloads required"

    # Add Amlogic packages for specific device types
    if [[ "${TYPE}" == "OPHUB" || "${TYPE}" == "ULO" ]]; then
        log "INFO" "Amlogic packages (luci-app-amlogic) available from feeds"
    fi

    log "SUCCESS" "Package setup completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
