# Homelab Bootstrap

Public phase-0 bootstrap tooling for Debian-based homelab virtual machines.

The bootstrap script:

- validates the operating system and required variables
- installs the base packages needed for provisioning
- validates SSH access to the private configuration repository
- clones the private homelab repository
- installs Git synchronization tooling
- generates the initial host inventory

## Security model

This repository contains no secrets.

SSH deploy keys, private repository URLs and host-specific configuration are
provided locally when provisioning a machine.

## Usage

Download the script before executing it:

```bash
curl -fsSLo /tmp/bootstrap-vm.sh \
  https://raw.githubusercontent.com/philipheyde/homelab-bootstrap/main/bootstrap-vm.sh

less /tmp/bootstrap-vm.sh

chmod 755 /tmp/bootstrap-vm.sh

sudo \
  GIT_REMOTE="git@SSH_HOST_ALIAS:philipheyde/homelab-config.git" \
  SYNC_USER="LOCAL_USER" \
  SSH_HOST_ALIAS="SSH_HOST_ALIAS" \
  /tmp/bootstrap-vm.sh

For stable or disaster-recovery usage, download a tagged release rather than
the moving main branch.
