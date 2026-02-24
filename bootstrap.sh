#!/usr/bin/env bash

# ============================================================
# OpenClaw Bootstrap — DigitalOcean Droplet Provisioner
# ============================================================
# Prepares a fresh Ubuntu 24.04 droplet: hardens the server,
# creates users, installs Node.js, and sets up Caddy for TLS.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/bootstrap.sh \
#     | bash -s -- --domain example.com
#
# Full:
#   curl -fsSL ... | bash -s -- \
#     --user szewong \
#     --key "ssh-ed25519 AAAA..." \
#     --domain example.com
#
# Flags:
#   --user <name>     Admin SSH username (default: zuser-XXXX random)
#   --key "<pubkey>"  SSH public key (default: copy from root authorized_keys)
#   --domain <fqdn>   Domain for Let's Encrypt TLS (default: self-signed via IP)
#   --help            Show this help
# ============================================================

if [[ "${1:-}" == "--help" ]]; then
    sed -n '/^# Usage:/,/^# ====/p' "$0" | sed 's/^# \?//'
    exit 0
fi

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Logging ────────────────────────────────────────────────

log_step() {
    echo -e "\n${BOLD}$1${NC}"
}

log_ok() {
    echo -e "  ${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "  ${YELLOW}!${NC} $1"
}

log_err() {
    echo -e "  ${RED}✗${NC} $1"
}

# ── Banner ─────────────────────────────────────────────────

banner() {
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  ${RED}●${NC} ${YELLOW}●${NC} ${GREEN}●${NC} ${BLUE}●${NC}  ${BOLD}OpenClaw Bootstrap                   ║${NC}"
    echo -e "${BOLD}║        DigitalOcean Droplet Provisioner               ║${NC}"
    echo -e "${BOLD}║                                                       ║${NC}"
    echo -e "${BOLD}║  ${DIM}Harden · Prep · TLS${NC}${BOLD}                                   ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Parse Arguments ────────────────────────────────────────

ADMIN_USER=""
SSH_KEY=""
DOMAIN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)
            shift; ADMIN_USER="${1:-}"
            ;;
        --key)
            shift; SSH_KEY="${1:-}"
            ;;
        --domain)
            shift; DOMAIN="${1:-}"
            ;;
        *)
            log_err "Unknown flag: $1"
            exit 1
            ;;
    esac
    shift
done

# ── Validate ───────────────────────────────────────────────

# Default admin username: zuser-XXXX
if [[ -z "$ADMIN_USER" ]]; then
    ADMIN_USER="zuser-$(printf '%04d' $((RANDOM % 10000)))"
fi

# Must be root
if [[ "$(id -u)" -ne 0 ]]; then
    log_err "This script must be run as root"
    exit 1
fi

# Must be Ubuntu
if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
    # shellcheck source=/dev/null
    log_err "This script requires Ubuntu (detected: $(. /etc/os-release && echo "$NAME"))"
    exit 1
fi

# ── Preflight ──────────────────────────────────────────────

banner

echo -e "${BOLD}Configuration:${NC}"
echo -e "  Admin user: ${GREEN}${ADMIN_USER}${NC}"
echo -e "  Domain:     ${GREEN}${DOMAIN:-<none — self-signed>}${NC}"
echo ""

# RAM check
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
if [[ $TOTAL_RAM_MB -lt 2048 ]]; then
    log_warn "Low memory: ${TOTAL_RAM_MB}MB detected (minimum recommended: 2048MB) — swap will be added"
fi

# ============================================================
# Phase 1/3 — Server Hardening
# ============================================================

log_step "[1/3] Server hardening..."

# ── Install packages ───────────────────────────────────────
install_packages() {
    log_step "  Installing system packages..."
    export DEBIAN_FRONTEND=noninteractive

    # Wait for any running apt/dpkg processes (e.g. unattended-upgrades on first boot)
    while fuser /var/lib/dpkg/lock-frontend &>/dev/null 2>&1; do
        log_step "  Waiting for dpkg lock (unattended-upgrades?)..."
        sleep 5
    done

    apt-get update -qq
    apt-get install -y -qq curl vim git ufw build-essential python3 jq fail2ban ca-certificates gnupg > /dev/null
    log_ok "System packages installed"
}

# ── Create admin user ─────────────────────────────────────
create_admin_user() {
    log_step "  Creating admin user: ${ADMIN_USER}..."

    if id "$ADMIN_USER" &>/dev/null; then
        log_ok "User $ADMIN_USER already exists"
    else
        useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
        log_ok "Created user $ADMIN_USER"
    fi

    # Passwordless sudo
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/sudo-nopasswd"
    chmod 440 "/etc/sudoers.d/sudo-nopasswd"
    log_ok "Passwordless sudo configured"

    # SSH key
    local ssh_dir="/home/${ADMIN_USER}/.ssh"
    mkdir -p "$ssh_dir"

    if [[ -n "$SSH_KEY" ]]; then
        echo "$SSH_KEY" > "${ssh_dir}/authorized_keys"
        log_ok "SSH key set from --key flag"
    elif [[ -f /root/.ssh/authorized_keys ]]; then
        cp /root/.ssh/authorized_keys "${ssh_dir}/authorized_keys"
        log_ok "SSH key copied from root (DO-injected)"
    else
        log_warn "No SSH key found — set one manually in ${ssh_dir}/authorized_keys"
    fi

    chmod 700 "$ssh_dir"
    chmod 600 "${ssh_dir}/authorized_keys" 2>/dev/null || true
    chown -R "${ADMIN_USER}:${ADMIN_USER}" "$ssh_dir"
}

# ── Configure SSH ──────────────────────────────────────────
configure_ssh() {
    log_step "  Configuring SSH..."

    local sshd_config="/etc/ssh/sshd_config"

    # PermitRootLogin prohibit-password (preserve key-based root for DO recovery)
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "$sshd_config"

    # Disable password auth
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$sshd_config"

    systemctl restart ssh 2>/dev/null || systemctl restart sshd
    log_ok "SSH hardened (root key-only, password auth disabled)"
}

# ── Configure firewall ─────────────────────────────────────
configure_firewall() {
    log_step "  Configuring firewall..."

    ufw --force reset > /dev/null
    ufw default deny incoming > /dev/null
    ufw default allow outgoing > /dev/null
    ufw allow 22/tcp > /dev/null
    ufw allow 80/tcp > /dev/null
    ufw allow 443/tcp > /dev/null
    ufw --force enable > /dev/null
    log_ok "UFW enabled (22, 80, 443 only)"
}

# ── Configure fail2ban ─────────────────────────────────────
configure_fail2ban() {
    log_step "  Configuring fail2ban..."

    systemctl enable fail2ban > /dev/null 2>&1
    systemctl start fail2ban > /dev/null 2>&1
    log_ok "fail2ban enabled"
}

install_packages
create_admin_user
configure_ssh
configure_firewall
configure_fail2ban

log_ok "Phase 1 complete — server hardened"

# ── Swap file (prevents OOM on ≤2 GB droplets) ──────────────
if ! swapon --show | grep -q /swapfile; then
    log_step "  Creating 2 GB swap file..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile > /dev/null
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    log_ok "2 GB swap enabled"
else
    log_ok "Swap already active — skipping"
fi

# ============================================================
# Phase 2/3 — OpenClaw Prep (user + Node.js)
# ============================================================

log_step "[2/3] Preparing OpenClaw environment..."

OPENCLAW_HOME="/home/openclaw"

# ── Create openclaw user ──────────────────────────────────
create_openclaw_user() {
    log_step "  Creating openclaw user..."

    if id openclaw &>/dev/null; then
        log_ok "User openclaw already exists"
    else
        useradd --create-home --home-dir "$OPENCLAW_HOME" --shell /bin/bash openclaw
        log_ok "Created user: openclaw"
    fi

    # Enable lingering so systemd user services survive logout
    loginctl enable-linger openclaw
    OPENCLAW_UID=$(id -u openclaw)
    mkdir -p "/run/user/${OPENCLAW_UID}"
    chown openclaw:openclaw "/run/user/${OPENCLAW_UID}"
    chmod 700 "/run/user/${OPENCLAW_UID}"
    systemctl start "user@${OPENCLAW_UID}.service"
    log_ok "Lingering enabled, systemd user session started"

    # Ensure npm global bin and XDG_RUNTIME_DIR are set for interactive shells
    # (sudo -u openclaw -i doesn't go through full PAM, so systemd user
    # services need XDG_RUNTIME_DIR explicitly)
    local bashrc="${OPENCLAW_HOME}/.bashrc"
    if ! grep -q '.npm-global/bin' "$bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$bashrc"
    fi
    if ! grep -q 'XDG_RUNTIME_DIR' "$bashrc" 2>/dev/null; then
        echo 'export XDG_RUNTIME_DIR="/run/user/$(id -u)"' >> "$bashrc"
    fi
    chown openclaw:openclaw "$bashrc"
}

# ── Install Node.js ────────────────────────────────────────
install_nodejs() {
    log_step "  Installing Node.js..."

    # Skip if node >= 22 already exists
    if command -v node &>/dev/null; then
        local current_major
        current_major=$(node --version | sed 's/v\([0-9]*\).*/\1/')
        if [[ "$current_major" -ge 22 ]]; then
            log_ok "Node.js $(node --version) already installed (>= 22)"
            return
        fi
    fi

    # NodeSource 22.x APT repo
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
    apt-get update -qq
    apt-get install -y -qq nodejs > /dev/null
    log_ok "Node.js $(node --version) installed"
}

create_openclaw_user
install_nodejs

log_ok "Phase 2 complete — openclaw user and Node.js ready"

# ============================================================
# Phase 3/3 — Reverse Proxy (Caddy)
# ============================================================

log_step "[3/3] Setting up reverse proxy..."

# ── Detect public IP ───────────────────────────────────────
PUBLIC_IP=""
detect_public_ip() {
    log_step "  Detecting public IP..."

    # Try DO metadata API first
    PUBLIC_IP=$(curl -s --connect-timeout 3 http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address 2>/dev/null || true)

    # Fallback to external service
    if [[ -z "$PUBLIC_IP" ]]; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 https://ifconfig.me 2>/dev/null || true)
    fi

    if [[ -z "$PUBLIC_IP" ]]; then
        PUBLIC_IP=$(hostname -I | awk '{print $1}')
        log_warn "Could not detect public IP — using ${PUBLIC_IP}"
    else
        log_ok "Public IP: ${PUBLIC_IP}"
    fi
}

# ── Install Caddy ──────────────────────────────────────────
install_caddy() {
    log_step "  Installing Caddy..."

    if command -v caddy &>/dev/null; then
        log_ok "Caddy already installed: $(caddy version 2>/dev/null || echo 'unknown')"
        return
    fi

    apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https > /dev/null
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
        | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg --yes
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
        > /etc/apt/sources.list.d/caddy-stable.list
    apt-get update -qq
    apt-get install -y -qq caddy > /dev/null
    log_ok "Caddy installed"
}

# ── Write Caddyfile ────────────────────────────────────────
write_caddyfile() {
    log_step "  Writing Caddyfile..."

    local caddyfile="/etc/caddy/Caddyfile"

    if [[ -n "$DOMAIN" ]]; then
        # Domain mode: auto Let's Encrypt
        cat > "$caddyfile" << EOF
${DOMAIN} {
    reverse_proxy 127.0.0.1:18789
}
EOF
        log_ok "Caddyfile: ${DOMAIN} → auto Let's Encrypt"
    else
        # IP mode: self-signed TLS
        cat > "$caddyfile" << EOF
https://${PUBLIC_IP} {
    tls internal
    reverse_proxy 127.0.0.1:18789
}
EOF
        log_ok "Caddyfile: ${PUBLIC_IP} → self-signed TLS"
    fi
}

# ── Start services ─────────────────────────────────────────
start_services() {
    log_step "  Starting services..."

    systemctl restart caddy
    log_ok "Caddy started"
}

detect_public_ip
install_caddy
write_caddyfile
start_services

log_ok "Phase 3 complete — reverse proxy configured"

# ============================================================
# Summary
# ============================================================

ACCESS_URL=""
if [[ -n "$DOMAIN" ]]; then
    ACCESS_URL="https://${DOMAIN}"
else
    ACCESS_URL="https://${PUBLIC_IP}"
fi

OPENCLAW_DIR="${OPENCLAW_HOME}/.openclaw"

echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  Bootstrap Complete!                                  ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}What was done:${NC}"
echo -e "  ${GREEN}✓${NC} Server hardened (UFW, fail2ban, SSH)"
echo -e "  ${GREEN}✓${NC} Admin user created: ${BOLD}${ADMIN_USER}${NC}"
echo -e "  ${GREEN}✓${NC} Node.js $(node --version) installed"
echo -e "  ${GREEN}✓${NC} openclaw user created (with systemd lingering)"
echo -e "  ${GREEN}✓${NC} Caddy reverse proxy with TLS"
echo ""
echo -e "${BOLD}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│  Admin User: ${YELLOW}${ADMIN_USER}${NC}${BOLD}                              │${NC}"
echo -e "${BOLD}│  ${DIM}(save this — you need it to SSH in)${NC}${BOLD}             │${NC}"
echo -e "${BOLD}└─────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${BOLD}Access:${NC}"
echo -e "  ${GREEN}${ACCESS_URL}${NC}"
echo ""
echo -e "${BOLD}SSH:${NC}"
echo -e "  ssh ${ADMIN_USER}@${PUBLIC_IP}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  1. ${YELLOW}Install OpenClaw (as openclaw user):${NC}"
echo -e "     sudo -u openclaw -i"
echo -e "     curl -fsSL https://openclaw.ai/install.sh | bash"
echo -e "     openclaw onboard"
echo -e "     exit"
echo ""
echo -e "  2. ${YELLOW}Deploy a team:${NC}"
echo -e "     curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/install-team.sh \\"
echo -e "       | bash -s -- --team operator --api-key sk-ant-..."
echo ""
echo -e "  ${DIM}•${NC} Service management:"
echo -e "     sudo -u openclaw -i openclaw gateway status"
echo -e "     sudo -u openclaw -i openclaw gateway restart"
echo -e "     sudo -u openclaw -i openclaw gateway logs"
echo ""
