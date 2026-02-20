#!/usr/bin/env bash
# ============================================================
# DigitalOcean OpenClaw Team Installer — Accountant Edition
# ============================================================
# Install the Accountant team on a DigitalOcean OpenClaw droplet
#
# Usage:
#   sudo bash do-team-install.sh accountant
#
# This script:
# 1. Verifies you're on a DO OpenClaw droplet
# 2. Unlocks execution policies (governance + capability)
# 3. Injects multi-agent config into the sandbox
# 4. Deploys 4 agents with DISC personalities
# 5. Restarts the OpenClaw service

set -euo pipefail

TEAM_NAME="accountant"
REPO_URL="https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================
# STEP 1: Verify DO OpenClaw droplet
# =============================================================
echo -e "${YELLOW}[1/5] Verifying DigitalOcean OpenClaw environment...${NC}"

if [[ ! -f /opt/openclaw-cli.sh ]]; then
    echo -e "${RED}ERROR: /opt/openclaw-cli.sh not found.${NC}"
    echo "This script must run on a DigitalOcean OpenClaw droplet."
    echo "Deploy one from: https://marketplace.digitalocean.com/apps/openclaw"
    exit 1
fi

if [[ ! -f /opt/openclaw.env ]]; then
    echo -e "${RED}ERROR: /opt/openclaw.env not found.${NC}"
    echo "OpenClaw may not be properly initialized. Try running the setup wizard first."
    exit 1
fi

echo -e "${GREEN}✓ DO OpenClaw droplet detected${NC}"

# =============================================================
# STEP 2: Unlock execution policies
# =============================================================
echo -e "${YELLOW}[2/5] Unlocking execution policies...${NC}"

# These unlock the sandbox to allow agents to actually work
# Read more: https://docs.digitalocean.com/products/marketplace/catalog/openclaw/

echo "  Setting tools.exec.host → gateway (agents need somewhere to execute)"
/opt/openclaw-cli.sh config set tools.exec.host gateway

echo "  Setting tools.exec.ask → off (no human interaction needed on headless)"
/opt/openclaw-cli.sh config set tools.exec.ask off

echo "  Setting tools.exec.security → full (enable network, filesystem within sandbox)"
/opt/openclaw-cli.sh config set tools.exec.security full

echo -e "${GREEN}✓ Execution policies unlocked${NC}"

# =============================================================
# STEP 3: Get the agent config and inject into sandbox
# =============================================================
echo -e "${YELLOW}[3/5] Injecting team configuration into sandbox...${NC}"

# Find the running OpenClaw container
CONTAINER_ID=$(docker ps -q -f "name=openclaw-sbx" | head -1)
if [[ -z "$CONTAINER_ID" ]]; then
    echo -e "${RED}ERROR: No OpenClaw sandbox container found.${NC}"
    echo "Try restarting: systemctl restart openclaw"
    exit 1
fi

echo "  Container: $CONTAINER_ID"

# Download team files from repo (needed when script is piped from curl)
WORK_DIR=$(mktemp -d)
trap "rm -rf '$WORK_DIR'" EXIT
echo "  Downloading team files..."
git clone --depth 1 -q https://github.com/zenithventure/openclaw-agent-teams.git "$WORK_DIR/repo"
TEAM_DIR="$WORK_DIR/repo/$TEAM_NAME"

if [[ ! -d "$TEAM_DIR" ]]; then
    echo -e "${RED}ERROR: Team directory '$TEAM_NAME' not found in repo.${NC}"
    exit 1
fi

# Copy the team's openclaw.json into the sandbox workspace
echo "  Copying team configuration..."
docker cp "$TEAM_DIR/openclaw.json" "$CONTAINER_ID:/workspace/openclaw.json"

# Copy team skills
echo "  Copying team skills..."
docker cp "$TEAM_DIR/shared/skills" "$CONTAINER_ID:/workspace/shared/"

# Copy agent definitions
echo "  Copying agent definitions..."
for agent_dir in "$TEAM_DIR"/agents/*/; do
    agent_name=$(basename "$agent_dir")
    docker cp "$agent_dir" "$CONTAINER_ID:/workspace/agents/$agent_name"
done

# Copy shared context
echo "  Copying shared context..."
docker cp "$TEAM_DIR/shared/VISION.md" "$CONTAINER_ID:/workspace/shared/VISION.md"
docker cp "$TEAM_DIR/shared/standup-log.md" "$CONTAINER_ID:/workspace/shared/standup-log.md" 2>/dev/null || true

echo -e "${GREEN}✓ Team configuration injected${NC}"

# =============================================================
# STEP 4: Restart OpenClaw to load new config
# =============================================================
echo -e "${YELLOW}[4/5] Restarting OpenClaw service...${NC}"

systemctl restart openclaw

# Wait for service to be ready
sleep 3

if ! systemctl is-active --quiet openclaw; then
    echo -e "${RED}ERROR: OpenClaw service failed to restart.${NC}"
    echo "Check logs: journalctl -u openclaw -n 50"
    exit 1
fi

echo -e "${GREEN}✓ OpenClaw restarted${NC}"

# =============================================================
# STEP 5: Verify setup
# =============================================================
echo -e "${YELLOW}[5/5] Verifying installation...${NC}"

# Check that agents are configured
AGENT_COUNT=$(grep -c '"name"' "./openclaw.json" || echo "0")
echo "  Agents configured: $AGENT_COUNT"

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "============================================================"
echo "Next steps:"
echo "============================================================"
echo "1. Open your OpenClaw dashboard:"
echo "   https://your-droplet-ip or via the DigitalOcean console"
echo ""
echo "2. Connect to your messaging platform (Telegram, WhatsApp, etc.)"
echo ""
echo "3. Define your business context in shared/VISION.md"
echo ""
echo "4. Send a message to your OpenClaw bot to start!"
echo ""
echo "Questions? Read the $TEAM_NAME README:"
echo "  $REPO_URL/$TEAM_NAME/README.md"
echo "============================================================"
