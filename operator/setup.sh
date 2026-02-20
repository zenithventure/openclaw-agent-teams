#!/usr/bin/env bash

# =============================================================
# Environment Detection
# =============================================================
if [[ -f /opt/openclaw-cli.sh ]]; then
    echo "DigitalOcean OpenClaw detected."
    echo "For DO installation, use: sudo bash do-team-install.sh TEAM_NAME"
    exit 0
fi
if [[ "${1:-}" == "--help" ]]; then
    echo "Setup script for bare-metal / self-hosted OpenClaw"
    echo "On DigitalOcean: sudo bash do-team-install.sh TEAM_NAME"
    exit 0
fi

# ============================================================
# OpenClaw Team Setup — "Surrounded by Idiots" Edition
# ============================================================
# Deploys a team of 4 DISC-personality agents to ~/.openclaw/
#
# Usage:
#   ./setup.sh                    # Interactive setup
#   ./setup.sh --clean            # Wipe and reinstall
#   ./setup.sh --vision "text"    # Set the vision inline
#
# After running, configure:
#   1. Edit shared/VISION.md with your mission
#   2. Set your timezone in each agent's USER.md
#   3. Uncomment your channel in openclaw.json
#   4. Set API keys in ~/.openclaw/.env
# ============================================================

# =============================================================
# Environment Detection
# =============================================================
# Check if running on DigitalOcean OpenClaw droplet
if [[ -f /opt/openclaw-cli.sh ]]; then
    echo "DigitalOcean OpenClaw detected."
    echo ""
    echo "For DO installation, use the dedicated script:"
    echo "  sudo bash do-team-install.sh operator"
    echo ""
    echo "This setup.sh is for bare-metal / self-hosted OpenClaw installations."
    exit 0
fi

# Handle --help flag
if [[ "${1:-}" == "--help" ]]; then
    echo "Setup script for Operator team (bare-metal / self-hosted)"
    echo ""
    echo "If you're on DigitalOcean:"
    echo "  sudo bash do-team-install.sh operator"
    echo ""
    echo "If you're running OpenClaw on your own infrastructure:"
    echo "  ./setup.sh [options]"
    echo ""
    echo "Options:"
    echo "  --clean     Wipe and reinstall all agents"
    echo "  --uninstall Remove the team completely"
    exit 0
fi

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Configuration ──────────────────────────────────────────
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS=("red-commander" "yellow-spark" "green-anchor" "blue-lens")
AGENT_EMOJIS=("🔴" "🟡" "🟢" "🔵")
AGENT_NAMES=("Commander" "Spark" "Anchor" "Lens")

# ── Functions ──────────────────────────────────────────────

banner() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  ${RED}●${NC} ${YELLOW}●${NC} ${GREEN}●${NC} ${BLUE}●${NC}  ${BOLD}OpenClaw Team Setup              ║${NC}"
    echo -e "${BOLD}║        \"Surrounded by Idiots\" Edition            ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_step() {
    echo -e "${BOLD}[SETUP]${NC} $1"
}

log_agent() {
    local color=$1
    local name=$2
    local msg=$3
    echo -e "  ${color}●${NC} ${name}: ${msg}"
}

check_openclaw() {
    if ! command -v openclaw &> /dev/null; then
        echo -e "${YELLOW}[WARN]${NC} 'openclaw' command not found."
        echo "  Install it first: npm install -g openclaw"
        echo "  Continuing with file deployment anyway..."
        echo ""
    fi
}

clean_install() {
    if [[ "${1:-}" == "--clean" ]]; then
        echo -e "${RED}[WARN]${NC} This will remove ALL existing OpenClaw configuration!"
        read -p "Are you sure? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log_step "Removing existing configuration..."
            rm -rf "${OPENCLAW_DIR}/workspace-red-commander"
            rm -rf "${OPENCLAW_DIR}/workspace-yellow-spark"
            rm -rf "${OPENCLAW_DIR}/workspace-green-anchor"
            rm -rf "${OPENCLAW_DIR}/workspace-blue-lens"
            rm -rf "${OPENCLAW_DIR}/skills/team-standup"
            rm -rf "${OPENCLAW_DIR}/skills/daily-report"
            rm -rf "${OPENCLAW_DIR}/skills/vision-sync"
            echo "  Done."
        else
            echo "  Aborted."
            exit 0
        fi
    fi
}

create_directories() {
    log_step "Creating directory structure..."

    # Main openclaw dir
    mkdir -p "${OPENCLAW_DIR}"
    chmod 700 "${OPENCLAW_DIR}"

    # Agent workspaces
    for agent in "${AGENTS[@]}"; do
        mkdir -p "${OPENCLAW_DIR}/workspace-${agent}/memory"
        mkdir -p "${OPENCLAW_DIR}/workspace-${agent}/skills"
    done

    # Shared workspace (symlinked into each agent workspace)
    mkdir -p "${OPENCLAW_DIR}/shared"
    mkdir -p "${OPENCLAW_DIR}/shared/reports"

    # Global skills
    mkdir -p "${OPENCLAW_DIR}/skills"

    echo "  Done."
}

deploy_config() {
    log_step "Deploying openclaw.json..."

    if [[ -f "${OPENCLAW_DIR}/openclaw.json" ]]; then
        cp "${OPENCLAW_DIR}/openclaw.json" "${OPENCLAW_DIR}/openclaw.json.backup.$(date +%Y%m%d%H%M%S)"
        echo "  Backed up existing config."
    fi

    cp "${SCRIPT_DIR}/openclaw.json" "${OPENCLAW_DIR}/openclaw.json"
    chmod 600 "${OPENCLAW_DIR}/openclaw.json"
    echo "  Done."
}

deploy_agent_files() {
    log_step "Deploying agent workspace files..."

    for i in "${!AGENTS[@]}"; do
        local agent="${AGENTS[$i]}"
        local name="${AGENT_NAMES[$i]}"
        local emoji="${AGENT_EMOJIS[$i]}"
        local workspace="${OPENCLAW_DIR}/workspace-${agent}"

        log_agent "${RED}" "${name}" "Deploying SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md"

        # Copy agent files
        cp "${SCRIPT_DIR}/agents/${agent}/SOUL.md"      "${workspace}/SOUL.md"
        cp "${SCRIPT_DIR}/agents/${agent}/IDENTITY.md"   "${workspace}/IDENTITY.md"
        cp "${SCRIPT_DIR}/agents/${agent}/USER.md"       "${workspace}/USER.md"
        cp "${SCRIPT_DIR}/agents/${agent}/HEARTBEAT.md"  "${workspace}/HEARTBEAT.md"

        # Create symlink to shared workspace so each agent can access it
        ln -sfn "${OPENCLAW_DIR}/shared" "${workspace}/shared"
    done

    echo "  Done."
}

deploy_shared_files() {
    log_step "Deploying shared Vision and standup log..."

    cp "${SCRIPT_DIR}/shared/VISION.md"       "${OPENCLAW_DIR}/shared/VISION.md"
    cp "${SCRIPT_DIR}/shared/standup-log.md"   "${OPENCLAW_DIR}/shared/standup-log.md"

    echo "  Done."
}

deploy_skills() {
    log_step "Deploying shared skills..."

    # Team standup skill
    mkdir -p "${OPENCLAW_DIR}/skills/team-standup"
    cp "${SCRIPT_DIR}/shared/skills/team-standup/SKILL.md" \
       "${OPENCLAW_DIR}/skills/team-standup/SKILL.md"
    log_agent "${GREEN}" "team-standup" "Installed"

    # Daily report skill
    mkdir -p "${OPENCLAW_DIR}/skills/daily-report"
    cp "${SCRIPT_DIR}/shared/skills/daily-report/SKILL.md" \
       "${OPENCLAW_DIR}/skills/daily-report/SKILL.md"
    log_agent "${GREEN}" "daily-report" "Installed"

    # Vision sync skill
    mkdir -p "${OPENCLAW_DIR}/skills/vision-sync"
    cp "${SCRIPT_DIR}/shared/skills/vision-sync/SKILL.md" \
       "${OPENCLAW_DIR}/skills/vision-sync/SKILL.md"
    log_agent "${GREEN}" "vision-sync" "Installed"

    echo "  Done."
}

create_env_template() {
    if [[ ! -f "${OPENCLAW_DIR}/.env" ]]; then
        log_step "Creating .env template..."
        cat > "${OPENCLAW_DIR}/.env" << 'ENVEOF'
# ── OpenClaw API Keys ──────────────────────────────────────
# Uncomment and fill in the keys you need.

# Required: At least one AI provider
# ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# OPENROUTER_API_KEY=sk-or-...

# Optional: Messaging channels
# TELEGRAM_BOT_TOKEN=...
# DISCORD_BOT_TOKEN=...
# DISCORD_USER_ID=...
# SLACK_APP_TOKEN=xapp-...
# SLACK_BOT_TOKEN=xoxb-...
ENVEOF
        chmod 600 "${OPENCLAW_DIR}/.env"
        echo "  Created .env template at ${OPENCLAW_DIR}/.env"
    else
        echo "  .env already exists, skipping."
    fi
}

set_vision_inline() {
    if [[ -n "${VISION_TEXT:-}" ]]; then
        log_step "Setting Vision from command line..."
        # Replace the placeholder in VISION.md
        local vision_file="${OPENCLAW_DIR}/shared/VISION.md"
        # Use python for safe multiline replacement
        python3 -c "
import re
with open('${vision_file}', 'r') as f:
    content = f.read()
placeholder = r'> \*\*\[CONFIGURE YOUR VISION HERE\]\*\*.*?> strategy — delivered as a polished report within 48 hours\.\"'
replacement = '> **${VISION_TEXT}**'
content = re.sub(placeholder, replacement, content, flags=re.DOTALL)
with open('${vision_file}', 'w') as f:
    f.write(content)
"
        echo "  Vision set."
    fi
}

print_summary() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  Setup Complete!                                 ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Your team:${NC}"
    echo -e "  ${RED}● Commander${NC}  (Red)    — Team Lead & Execution Driver"
    echo -e "  ${YELLOW}● Spark${NC}      (Yellow) — Creative Lead & Idea Generator"
    echo -e "  ${GREEN}● Anchor${NC}     (Green)  — Operations Lead & Team Glue"
    echo -e "  ${BLUE}● Lens${NC}       (Blue)   — Quality Lead & Analytical Engine"
    echo ""
    echo -e "${BOLD}Directory:${NC} ${OPENCLAW_DIR}/"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    echo "  1. Set your API key:"
    echo "     Edit ${OPENCLAW_DIR}/.env"
    echo ""
    echo "  2. Configure your Vision:"
    echo "     Edit ${OPENCLAW_DIR}/shared/VISION.md"
    echo ""
    echo "  3. Set your timezone in USER.md:"
    echo "     Edit any agent's workspace/USER.md"
    echo ""
    echo "  4. Enable a messaging channel:"
    echo "     Uncomment a channel block in ${OPENCLAW_DIR}/openclaw.json"
    echo ""
    echo "  5. Start the gateway:"
    echo "     openclaw start"
    echo ""
    echo -e "${BOLD}Quick Vision set:${NC}"
    echo "  ./setup.sh --vision \"Build a market analysis for...\""
    echo ""
    echo -e "${BOLD}Clean reinstall:${NC}"
    echo "  ./setup.sh --clean"
    echo ""
}

# ── Main ───────────────────────────────────────────────────

banner

# Parse arguments
VISION_TEXT=""
for arg in "$@"; do
    case "$arg" in
        --clean)
            clean_install "--clean"
            ;;
        --vision)
            shift
            VISION_TEXT="${1:-}"
            ;;
    esac
done

check_openclaw
create_directories
deploy_config
deploy_agent_files
deploy_shared_files
deploy_skills
create_env_template
set_vision_inline
print_summary
