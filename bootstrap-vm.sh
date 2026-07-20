#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY_DIRECTORY="/opt/homelab-config"
readonly CONFIG_FILE="/etc/homelab-sync.conf"

GIT_REMOTE="${GIT_REMOTE:-}"
SYNC_USER="${SYNC_USER:-}"
SSH_HOST_ALIAS="${SSH_HOST_ALIAS:-}"

log() {
    printf '[%s] %s\n' "$(date --iso-8601=seconds)" "$*"
}

fail() {
    log "FEJL: $*"
    exit 1
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        fail "Scriptet skal køres som root eller med sudo"
    fi
}

require_debian() {
    if [[ ! -r /etc/os-release ]]; then
        fail "Kan ikke identificere operativsystemet"
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    if [[ "${ID:-}" != "debian" ]]; then
        fail "Dette script understøtter foreløbig kun Debian"
    fi
}

validate_variables() {
    if [[ -z "$GIT_REMOTE" ]]; then
        fail "GIT_REMOTE skal angives"
    fi

    if [[ -z "$SYNC_USER" ]]; then
        fail "SYNC_USER skal angives"
    fi

    if [[ -z "$SSH_HOST_ALIAS" ]]; then
        fail "SSH_HOST_ALIAS skal angives"
    fi

    if ! id "$SYNC_USER" >/dev/null 2>&1; then
        fail "Brugeren findes ikke: $SYNC_USER"
    fi
}

install_packages() {
    log "Opdaterer pakkelister"

    apt-get update

    log "Installerer nødvendige pakker"

    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates \
        curl \
        git \
        openssh-client \
        rsync
}

validate_ssh_access() {
    local exit_code

    log "Kontrollerer SSH-adgang til GitHub"

    set +e

    sudo -u "$SYNC_USER" \
        ssh \
        -o BatchMode=yes \
        -o ConnectTimeout=15 \
        -T "$SSH_HOST_ALIAS"

    exit_code="$?"

    set -e

    # GitHub returnerer normalt exitkode 1 efter vellykket
    # autentificering, fordi interaktiv shell-adgang ikke tilbydes.
    if [[ "$exit_code" -ne 1 ]]; then
        fail "SSH-forbindelsen til $SSH_HOST_ALIAS kunne ikke valideres"
    fi
}

clone_repository() {
    if [[ -d "${REPOSITORY_DIRECTORY}/.git" ]]; then
        log "Repositoryet findes allerede: $REPOSITORY_DIRECTORY"
        return
    fi

    if [[ -e "$REPOSITORY_DIRECTORY" ]] &&
        [[ -n "$(find "$REPOSITORY_DIRECTORY" -mindepth 1 -maxdepth 1 -print -quit)" ]]
    then
        fail "$REPOSITORY_DIRECTORY findes og er ikke tom"
    fi

    mkdir -p "$REPOSITORY_DIRECTORY"
    chown "$SYNC_USER:$SYNC_USER" "$REPOSITORY_DIRECTORY"

    log "Kloner repositoryet"

    sudo -u "$SYNC_USER" git clone \
        "$GIT_REMOTE" \
        "$REPOSITORY_DIRECTORY"
}

configure_git() {
    log "Kontrollerer Git-konfiguration"

    sudo -u "$SYNC_USER" git \
        -C "$REPOSITORY_DIRECTORY" \
        config pull.rebase true

    sudo -u "$SYNC_USER" git \
        -C "$REPOSITORY_DIRECTORY" \
        config rebase.autoStash true
}

install_sync_tooling() {
    log "Installerer sync-værktøjer"

    "${REPOSITORY_DIRECTORY}/scripts/install-sync.sh"
}

generate_inventory() {
    log "Genererer første host-inventar"

    sudo -u "$SYNC_USER" \
        "${REPOSITORY_DIRECTORY}/scripts/update-host-inventory.sh"
}

show_next_steps() {
    cat <<EOF

Bootstrap er gennemført.

Næste skridt:

1. Tilpas:
   ${CONFIG_FILE}

2. Kontrollér konfigurationen:
   bash -n ${CONFIG_FILE}

3. Kør en manuel synkronisering:
   sudo -u ${SYNC_USER} /usr/local/bin/homelab-git-sync

4. Kontrollér timeren:
   systemctl list-timers homelab-git-sync.timer --no-pager

EOF
}

main() {
    require_root
    require_debian
    validate_variables
    install_packages
    validate_ssh_access
    clone_repository
    configure_git
    install_sync_tooling
    generate_inventory
    show_next_steps
}

main "$@"
