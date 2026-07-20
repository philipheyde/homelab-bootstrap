# Homelab Bootstrap

Public phase-0 provisioning tools for Debian-based homelab virtual machines.

This repository contains no secrets or host-specific credentials.

## Components

- `bootstrap.sh`: phase-0 entry point that downloads and runs the full bootstrap
- `bootstrap-vm.sh`: provisions the VM and clones the private configuration repository

## Requirements

A clean Debian installation may not include `curl`. Install the minimal download
dependencies first:

```bash
sudo apt-get update
sudo apt-get install -y curl ca-certificates
```

## Download

Download the phase-0 script before executing it:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/philipheyde/homelab-bootstrap/main/bootstrap.sh \
  -o /tmp/homelab-bootstrap.sh

bash -n /tmp/homelab-bootstrap.sh
less /tmp/homelab-bootstrap.sh
chmod 755 /tmp/homelab-bootstrap.sh
```

## Run

The SSH deploy key and matching SSH host alias must already be configured for
the private `homelab-config` repository.

```bash
sudo \
  GIT_REMOTE="git@github-homelab-example:philipheyde/homelab-config.git" \
  SYNC_USER="local-user" \
  SSH_HOST_ALIAS="github-homelab-example" \
  /tmp/homelab-bootstrap.sh
```

## Version pinning

`bootstrap.sh` downloads `bootstrap-vm.sh` from the `main` branch by default.

A tag or commit can be selected with `BOOTSTRAP_REF`:

```bash
sudo \
  BOOTSTRAP_REF="v1.0.0" \
  GIT_REMOTE="git@github-homelab-example:philipheyde/homelab-config.git" \
  SYNC_USER="local-user" \
  SSH_HOST_ALIAS="github-homelab-example" \
  /tmp/homelab-bootstrap.sh
```

For disaster recovery, use a tested release tag rather than the moving
`main` branch.
