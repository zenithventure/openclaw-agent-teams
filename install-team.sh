#!/usr/bin/env bash

# ============================================================
# OpenClaw Team Installer
# ============================================================
# Deploys an agent team into an existing OpenClaw installation.
# Run as the openclaw user after install + onboard.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/install-team.sh \
#     | bash -s -- --team operator
#
# Full:
#   curl -fsSL ... | bash -s -- \
#     --team operator \
#     --api-key sk-ant-...
#
# Flags:
#   --team <name>     Required. Team to deploy (operator, product-builder, etc.)
#   --api-key <key>   Anthropic API key (default: leave .env as template)
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

# ── Cleanup Trap ───────────────────────────────────────────
CLONE_DIR=""
cleanup() {
    if [[ -n "$CLONE_DIR" && -d "$CLONE_DIR" ]]; then
        rm -rf "$CLONE_DIR"
    fi
}
trap cleanup EXIT

# ── Banner ─────────────────────────────────────────────────

banner() {
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  ${RED}●${NC} ${YELLOW}●${NC} ${GREEN}●${NC} ${BLUE}●${NC}  ${BOLD}OpenClaw Team Installer               ║${NC}"
    echo -e "${BOLD}║        Deploy an agent team                           ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Parse Arguments ────────────────────────────────────────

TEAM=""
API_KEY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --team)
            shift; TEAM="${1:-}"
            ;;
        --api-key)
            shift; API_KEY="${1:-}"
            ;;
        *)
            log_err "Unknown flag: $1"
            exit 1
            ;;
    esac
    shift
done

# ── Validate ───────────────────────────────────────────────
# Teams are no longer hard-coded — any top-level directory in the repo
# that contains an openclaw.json and an agents/ folder is a deployable
# team. This includes teams you author yourself. The team directory is
# validated structurally after the repo is cloned (see run_team_deploy).

if [[ -z "$TEAM" ]]; then
    log_err "--team is required"
    echo ""
    echo "  --team is any team directory in the repo (built-in or your own)."
    echo ""
    echo "  Example:"
    echo "    curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/install-team.sh \\"
    echo "      | bash -s -- --team operator"
    exit 1
fi

# Verify OpenClaw is installed
if ! command -v openclaw &>/dev/null; then
    log_err "OpenClaw binary not found."
    echo "  Install it first:"
    echo "    curl -fsSL https://openclaw.ai/install.sh | bash"
    echo "    openclaw onboard"
    exit 1
fi

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"

# ── Preflight ──────────────────────────────────────────────

banner

echo -e "${BOLD}Configuration:${NC}"
echo -e "  Team:    ${GREEN}${TEAM}${NC}"
echo -e "  API key: ${GREEN}${API_KEY:+<provided>}${API_KEY:-<not set — configure later>}${NC}"
echo ""

# ============================================================
# Deploy Team
# ============================================================

log_step "Deploying team: ${TEAM}..."

REPO_URL="https://github.com/zenithventure/openclaw-agent-teams.git"

# ── Clone repo ─────────────────────────────────────────────
clone_repo() {
    log_step "  Cloning agent teams repo..."

    CLONE_DIR=$(mktemp -d)
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR" > /dev/null 2>&1
    log_ok "Cloned to ${CLONE_DIR}"
}

# ── List deployable teams discovered in the clone ──────────
list_available_teams() {
    local d
    for d in "${CLONE_DIR}"/*/; do
        if [[ -f "${d}openclaw.json" && -d "${d}agents" ]]; then
            echo "    - $(basename "$d")"
        fi
    done
}

# ── Deploy the team via the generic deployer ───────────────
run_team_deploy() {
    local team_dir="${CLONE_DIR}/${TEAM}"

    # Structural validation: a team is any dir with openclaw.json + agents/.
    if [[ ! -f "${team_dir}/openclaw.json" || ! -d "${team_dir}/agents" ]]; then
        log_err "Not a deployable team: ${TEAM}"
        echo "  (a team directory needs openclaw.json and agents/)"
        echo ""
        echo "  Available teams:"
        list_available_teams
        exit 1
    fi

    log_step "  Deploying ${TEAM}..."
    # Prefer the team's own setup.sh when present — for built-in teams this is a
    # thin shim over the generic deployer, but a team may ship bespoke logic
    # (e.g. modernizer). Pure-data teams with no setup.sh fall back to the
    # generic deployer directly.
    if [[ -f "${team_dir}/setup.sh" ]]; then
        bash "${team_dir}/setup.sh"
    elif [[ -f "${CLONE_DIR}/lib/deploy-team.sh" ]]; then
        bash "${CLONE_DIR}/lib/deploy-team.sh" --team-dir "${team_dir}"
    else
        log_err "No deployer found (${TEAM}/setup.sh or lib/deploy-team.sh)"
        exit 1
    fi
    log_ok "Team deploy complete"
}

# ── Patch OpenClaw 3.2 systemd / config quirks ─────────────
# Mirrors the deprecated service-patch.sh: ensures a user-mode
# openclaw-gateway.service exists, flips the Telegram groupPolicy
# default, then reloads the unit. Idempotent and safe to re-run.
patch_service() {
    log_step "  Applying OpenClaw 3.2 systemd workaround..."

    local config="${OPENCLAW_DIR}/openclaw.json"
    if [[ -f "$config" ]]; then
        if grep -q '"groupPolicy": "allowlist"' "$config"; then
            sed -i 's/"groupPolicy": "allowlist"/"groupPolicy": "open"/' "$config"
            log_ok "Patched groupPolicy → open in openclaw.json"
        fi
    fi

    local unit="${HOME}/.config/systemd/user/openclaw-gateway.service"
    local unit_existed=true
    if [[ ! -f "$unit" ]]; then
        unit_existed=false
        local openclaw_bin
        openclaw_bin="$(command -v openclaw || echo "${HOME}/.npm-global/bin/openclaw")"
        mkdir -p "$(dirname "$unit")"
        cat > "$unit" << EOF
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=${openclaw_bin} gateway start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
        log_ok "Wrote stub unit: ${unit}"
    fi

    XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export XDG_RUNTIME_DIR
    systemctl --user daemon-reload
    systemctl --user enable openclaw-gateway.service >/dev/null 2>&1 || true

    # Let openclaw rewrite the unit properly only on first install
    if [[ "$unit_existed" == false ]]; then
        systemctl --user start openclaw-gateway.service || true
        sleep 3
        openclaw gateway install --force >/dev/null 2>&1 || true
    fi

    systemctl --user reload-or-restart openclaw-gateway.service
    log_ok "Gateway reloaded"
}

# ── Configure API key ──────────────────────────────────────
configure_api_key() {
    if [[ -n "$API_KEY" ]]; then
        log_step "  Setting Anthropic API key..."

        local env_file="${OPENCLAW_DIR}/.env"
        if [[ -f "$env_file" ]]; then
            # Uncomment and set the key
            if grep -q "^# ANTHROPIC_API_KEY=" "$env_file"; then
                sed -i "s|^# ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=${API_KEY}|" "$env_file"
            elif grep -q "^ANTHROPIC_API_KEY=" "$env_file"; then
                sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=${API_KEY}|" "$env_file"
            else
                echo "ANTHROPIC_API_KEY=${API_KEY}" >> "$env_file"
            fi
        else
            mkdir -p "$(dirname "$env_file")"
            echo "ANTHROPIC_API_KEY=${API_KEY}" > "$env_file"
        fi

        chmod 600 "$env_file"
        log_ok "API key configured"
    else
        log_warn "No --api-key provided — edit ${OPENCLAW_DIR}/.env later"
    fi
}

clone_repo
run_team_deploy
# Write the API key before patch_service so the gateway picks it up
# on its first (re)start. Otherwise it would boot without the key and
# never be restarted again in this run.
configure_api_key
patch_service

# ============================================================
# Summary
# ============================================================

echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  Team Deployed!                                       ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}What was done:${NC}"
echo -e "  ${GREEN}✓${NC} Team deployed: ${BOLD}${TEAM}${NC}"
echo -e "  ${GREEN}✓${NC} OpenClaw 3.2 systemd workaround applied"
echo -e "  ${GREEN}✓${NC} Gateway reloaded"
if [[ -n "$API_KEY" ]]; then
    echo -e "  ${GREEN}✓${NC} API key configured"
else
    echo -e "  ${YELLOW}!${NC} API key not set — edit ${OPENCLAW_DIR}/.env"
fi
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  1. ${YELLOW}Edit your vision:${NC}"
echo -e "     nano ${OPENCLAW_DIR}/shared/VISION.md"
echo ""
echo -e "  ${DIM}•${NC} Service management:"
echo -e "     openclaw gateway status"
echo -e "     openclaw gateway restart"
echo -e "     openclaw gateway logs"
echo ""
