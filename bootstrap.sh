#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly DEFAULT_BRANCH="main"
readonly DEFAULT_BOOTSTRAP_REPOSITORY="philipheyde/homelab-bootstrap"

log() {
    printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}

error() {
    printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2
    exit 1
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "Scriptet skal køres som root, eksempelvis med sudo."
    fi
}

require_environment() {
    local variable

    for variable in GIT_REMOTE SYNC_USER SSH_HOST_ALIAS; do
        if [[ -z "${!variable:-}" ]]; then
            error "Miljøvariablen ${variable} skal angives."
        fi
    done
}

install_downloader() {
    if command -v curl >/dev/null 2>&1; then
        return
    fi

    command -v apt-get >/dev/null 2>&1 ||
        error "curl mangler, og apt-get blev ikke fundet."

    log "Installerer curl og CA-certifikater..."
    apt-get update
    DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends curl ca-certificates
}

download_bootstrap() {
    local repository="${BOOTSTRAP_REPOSITORY:-$DEFAULT_BOOTSTRAP_REPOSITORY}"
    local ref="${BOOTSTRAP_REF:-$DEFAULT_BRANCH}"
    local destination
    local url

    destination="$(mktemp /tmp/bootstrap-vm.XXXXXX.sh)"
    url="https://raw.githubusercontent.com/${repository}/${ref}/bootstrap-vm.sh"

    log "Henter bootstrap-vm.sh fra ${repository}@${ref}..."
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --proto '=https' \
        --tlsv1.2 \
        --output "$destination" \
        "$url"

    chmod 0700 "$destination"

    bash -n "$destination" ||
        error "Det hentede bootstrap-script bestod ikke syntakskontrollen."

    printf '%s\n' "$destination"
}

main() {
    local bootstrap_script

    require_root
    require_environment
    install_downloader

    bootstrap_script="$(download_bootstrap)"

    trap 'rm -f "$bootstrap_script"' EXIT

    log "Starter VM-bootstrap..."

    GIT_REMOTE="$GIT_REMOTE" \
    SYNC_USER="$SYNC_USER" \
    SSH_HOST_ALIAS="$SSH_HOST_ALIAS" \
        "$bootstrap_script"

    log "Bootstrap afsluttet."
}

main "$@"
