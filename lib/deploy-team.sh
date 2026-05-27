#!/usr/bin/env bash

# ============================================================
# OpenClaw Team Deployer (generic, data-driven)
# ============================================================
# Deploys any team directory into ~/.openclaw. A team is just
# data — no per-team script required:
#
#   <team>/
#     openclaw.json        # agent definitions, tool perms, skills
#     agents/<id>/         # one dir per agent (1..N agents)
#       SOUL.md IDENTITY.md AGENTS.md HEARTBEAT.md USER.md
#     shared/              # VISION.md STANDARDS.md BOOTSTRAP.md standup-log.md
#       skills/<name>/SKILL.md   # optional team skills
#
# Convention (clean teams): each agents/<id>/ maps to an agent
# whose openclaw.json id is "<id>" and whose workspace is
# ~/.openclaw/workspace-<id>. JSON-level operations derive agent
# ids from openclaw.json, so teams that diverge from this naming
# still merge correctly.
#
# Usage:
#   bash lib/deploy-team.sh --team-dir /path/to/<team> [flags]
#
# Flags:
#   --team-dir <path>   Source team directory (required)
#   --clean             Wipe this team's data, then reinstall
#   --uninstall         Remove this team's data and exit
#   --vision "text"     Set the mission statement inline
#   --help              Show this help
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
log_step() { echo -e "\n${BOLD}[SETUP]${NC} $1"; }
log_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
log_warn() { echo -e "  ${YELLOW}!${NC} $1"; }
log_err()  { echo -e "  ${RED}✗${NC} $1"; }

# ── Parse Arguments ────────────────────────────────────────
TEAM_DIR=""
VISION_TEXT=""
DO_CLEAN=false
DO_UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --team-dir) shift; TEAM_DIR="${1:-}" ;;
        --clean)    DO_CLEAN=true ;;
        --uninstall) DO_UNINSTALL=true ;;
        --vision)   shift; VISION_TEXT="${1:-}" ;;
        --help)     sed -n '/^# Usage:/,/^# ====/p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) log_err "Unknown flag: $1"; exit 1 ;;
    esac
    shift
done

# ── Resolve & validate the team directory ──────────────────
if [[ -z "$TEAM_DIR" ]]; then
    log_err "--team-dir is required"
    exit 1
fi
TEAM_DIR="$(cd "$TEAM_DIR" 2>/dev/null && pwd || true)"
if [[ -z "$TEAM_DIR" || ! -d "$TEAM_DIR" ]]; then
    log_err "Team directory not found"
    exit 1
fi
if [[ ! -d "${TEAM_DIR}/agents" ]]; then
    log_err "Not a team directory (missing agents/): ${TEAM_DIR}"
    exit 1
fi
# openclaw.json is optional — synthesized from agents/ below when absent.

TEAM_NAME="$(basename "$TEAM_DIR")"
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"

# Canonical files (STANDARDS.md, BOOTSTRAP.md) live once in _template/shared and
# are sourced from there unless a team ships its own override. _template sits
# beside this script's repo (lib/../_template), and is present in every deploy
# context (local checkout, the rsync'd repo on a target, the install-team clone).
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_SHARED="$(cd "${LIB_DIR}/../_template/shared" 2>/dev/null && pwd || true)"

# Echo the source path for a canonical shared file: the team's own copy if it
# ships one, else the _template copy. Empty if neither exists.
canonical_src() {
    local f="$1"
    if [[ -f "${TEAM_DIR}/shared/${f}" ]]; then
        echo "${TEAM_DIR}/shared/${f}"
    elif [[ -n "$TEMPLATE_SHARED" && -f "${TEMPLATE_SHARED}/${f}" ]]; then
        echo "${TEMPLATE_SHARED}/${f}"
    fi
}

# ── Discover agents, ids, and skills from the team data ────
# Agent directories drive workspace deployment.
AGENT_DIRS=()
while IFS= read -r d; do
    [[ -n "$d" ]] && AGENT_DIRS+=("$(basename "$d")")
done < <(find "${TEAM_DIR}/agents" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ ${#AGENT_DIRS[@]} -eq 0 ]]; then
    log_err "No agents found under ${TEAM_DIR}/agents/"
    exit 1
fi

have_node=false
command -v node &>/dev/null && have_node=true

# openclaw.json is optional: a "uniform" team (config fully implied by its
# agents/ dirs) can omit it and the deployer synthesizes a default — each
# agents/<id>/ becomes an agent { id, name, workspace, subagents:["*"] }, with
# agent-to-agent enabled for all ids and the standard skills dir. Ship an
# explicit openclaw.json only for custom names, tools, or permissions.
TMP_JSON_DIR=""
cleanup_tmp() { [[ -n "$TMP_JSON_DIR" && -d "$TMP_JSON_DIR" ]] && rm -rf "$TMP_JSON_DIR"; return 0; }
trap cleanup_tmp EXIT

INCOMING_JSON="${TEAM_DIR}/openclaw.json"
if [[ ! -f "$INCOMING_JSON" ]]; then
    if [[ "$have_node" != true ]]; then
        log_err "openclaw.json is missing and node is unavailable to synthesize one"
        exit 1
    fi
    # Write to <tmpdir>/openclaw.json so require() resolves it by extension.
    TMP_JSON_DIR="$(mktemp -d)"
    INCOMING_JSON="${TMP_JSON_DIR}/openclaw.json"
    local_ids_csv="$(printf '"%s",' "${AGENT_DIRS[@]}")"; local_ids_csv="[${local_ids_csv%,}]"
    # name: strip a leading DISC color, split on -/_ , Title Case (red-strategist → "Strategist").
    IDS_CSV="$local_ids_csv" node -e '
const fs=require("fs");
const ids=JSON.parse(process.env.IDS_CSV);
const title=s=>s.replace(/^(red|yellow|green|blue)-/,"").split(/[-_]/).filter(Boolean)
  .map(w=>w[0].toUpperCase()+w.slice(1)).join(" ")||s;
const list=ids.map(id=>({id,name:title(id),workspace:"~/.openclaw/workspace-"+id,subagents:{allowAgents:["*"]}}));
const cfg={agents:{defaults:{compaction:{mode:"safeguard"},maxConcurrent:4,subagents:{maxConcurrent:8}},list},
  tools:{agentToAgent:{enabled:true,allow:ids}},skills:{load:{extraDirs:["~/.openclaw/skills"]}}};
fs.writeFileSync(process.argv[1],JSON.stringify(cfg,null,2)+"\n");
' "$INCOMING_JSON"
    log_warn "openclaw.json synthesized from agents/ (${#AGENT_DIRS[@]} agents) — ship one to customize"
fi

# Agent ids (for JSON merge / removal) come from the config so teams whose ids
# differ from their dir names still work.
agent_ids_json() {
    node -e "const c=require('${INCOMING_JSON}'); (c.agents?.list||[]).forEach(a=>console.log(a.id))"
}

AGENT_IDS=()
if [[ "$have_node" == true ]]; then
    while IFS= read -r id; do
        [[ -n "$id" ]] && AGENT_IDS+=("$id")
    done < <(agent_ids_json)
fi
# Fallback: assume id == dir name.
if [[ ${#AGENT_IDS[@]} -eq 0 ]]; then
    AGENT_IDS=("${AGENT_DIRS[@]}")
fi

# Skills: scan both shared/skills/<name>/SKILL.md and skills/<name>/SKILL.md
SKILL_SRCS=()
while IFS= read -r s; do
    [[ -n "$s" ]] && SKILL_SRCS+=("$s")
done < <(find "${TEAM_DIR}/shared/skills" "${TEAM_DIR}/skills" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | sort)

# ── Banner ─────────────────────────────────────────────────
banner() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  ${RED}●${NC} ${YELLOW}●${NC} ${GREEN}●${NC} ${BLUE}●${NC}  ${BOLD}OpenClaw Team Deployer            ${NC}${BOLD}║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo -e "  Team:   ${GREEN}${TEAM_NAME}${NC}"
    echo -e "  Agents: ${GREEN}${#AGENT_DIRS[@]}${NC}    Skills: ${GREEN}${#SKILL_SRCS[@]}${NC}"
    echo ""
}

# ── Preflight ──────────────────────────────────────────────
check_openclaw() {
    log_step "Checking prerequisites..."
    if command -v openclaw &>/dev/null; then
        log_ok "openclaw found: $(command -v openclaw)"
    else
        log_warn "'openclaw' not found — deploying files only"
    fi
    if [[ "$have_node" == true ]]; then
        log_ok "node found: $(node --version)"
    else
        log_warn "node not found — openclaw.json will be replaced, not merged"
    fi
}

# ── Clean / Uninstall ──────────────────────────────────────
remove_team_data() {
    for agent in "${AGENT_DIRS[@]}"; do
        rm -rf "${OPENCLAW_DIR}/workspace-${agent}"
    done
    for src in "${SKILL_SRCS[@]}"; do
        local name; name="$(basename "$(dirname "$src")")"
        rm -rf "${OPENCLAW_DIR}/skills/${name}"
    done
    rm -rf "${OPENCLAW_DIR}/shared"
}

remove_agents_from_config() {
    [[ "$have_node" == true && -f "${OPENCLAW_DIR}/openclaw.json" ]] || return 0
    local ids_csv; ids_csv="$(printf '"%s",' "${AGENT_IDS[@]}")"; ids_csv="[${ids_csv%,}]"
    node -e "
const fs=require('fs');
const p='${OPENCLAW_DIR}/openclaw.json';
const c=JSON.parse(fs.readFileSync(p,'utf8'));
const ids=${ids_csv};
if(c.agents?.list) c.agents.list=c.agents.list.filter(a=>!ids.includes(a.id));
if(c.tools?.agentToAgent?.allow) c.tools.agentToAgent.allow=c.tools.agentToAgent.allow.filter(x=>!ids.includes(x));
fs.writeFileSync(p, JSON.stringify(c,null,2)+'\n');
"
}

clean_install() {
    echo -e "${RED}[WARN]${NC} This will remove all '${TEAM_NAME}' agent data!"
    echo "       (Existing openclaw.json will be backed up)"
    read -p "  Are you sure? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_step "Cleaning existing installation..."
        remove_team_data
        log_ok "Removed workspaces, skills, and shared"
    else
        echo "  Aborted."; exit 0
    fi
}

uninstall() {
    log_step "Uninstalling '${TEAM_NAME}'..."
    remove_team_data
    log_ok "Removed agent workspaces, skills, and shared"
    remove_agents_from_config
    log_ok "Removed agents from openclaw.json"
    echo ""
    echo -e "${GREEN}Uninstall complete.${NC}"
    exit 0
}

# ── Deploy ─────────────────────────────────────────────────
create_directories() {
    log_step "Creating directory structure..."
    mkdir -p "${OPENCLAW_DIR}"
    chmod 700 "${OPENCLAW_DIR}"
    for agent in "${AGENT_DIRS[@]}"; do
        mkdir -p "${OPENCLAW_DIR}/workspace-${agent}/memory"
    done
    mkdir -p "${OPENCLAW_DIR}/shared/reports"
    mkdir -p "${OPENCLAW_DIR}/skills"
    log_ok "Directory structure created"
}

deploy_config() {
    log_step "Deploying openclaw.json..."
    local config_file="${OPENCLAW_DIR}/openclaw.json"
    local incoming="${INCOMING_JSON}"

    if [[ -f "${config_file}" ]]; then
        cp "${config_file}" "${config_file}.backup.$(date +%Y%m%d%H%M%S)"
        log_ok "Backed up existing config"
        if [[ "$have_node" == true ]]; then
            node -e "
const fs=require('fs');
const existing=JSON.parse(fs.readFileSync('${config_file}','utf8'));
const incoming=JSON.parse(fs.readFileSync('${incoming}','utf8'));

if(!existing.agents) existing.agents={};
if(!existing.agents.defaults && incoming.agents?.defaults) existing.agents.defaults=incoming.agents.defaults;
if(!existing.agents.list) existing.agents.list=[];

const ids=(incoming.agents?.list||[]).map(a=>a.id);
existing.agents.list=existing.agents.list.filter(a=>!ids.includes(a.id));
for(const a of (incoming.agents?.list||[])) existing.agents.list.push(a);

if(incoming.tools?.agentToAgent){
  if(!existing.tools) existing.tools={};
  if(!existing.tools.agentToAgent) existing.tools.agentToAgent={enabled:true,allow:[]};
  existing.tools.agentToAgent.enabled=true;
  const allow=existing.tools.agentToAgent.allow||[];
  for(const id of ids) if(!allow.includes(id)) allow.push(id);
  existing.tools.agentToAgent.allow=allow;
}

if(incoming.skills?.load?.extraDirs){
  if(!existing.skills) existing.skills={};
  if(!existing.skills.load) existing.skills.load={};
  if(!existing.skills.load.extraDirs) existing.skills.load.extraDirs=[];
  for(const d of incoming.skills.load.extraDirs)
    if(!existing.skills.load.extraDirs.includes(d)) existing.skills.load.extraDirs.push(d);
}

fs.writeFileSync('${config_file}', JSON.stringify(existing,null,2)+'\n');
"
            log_ok "Merged agents into existing openclaw.json"
        else
            cp "${incoming}" "${config_file}"
            log_warn "No node available — replaced openclaw.json (backup saved)"
        fi
    else
        cp "${incoming}" "${config_file}"
        log_ok "Created openclaw.json"
    fi
    chmod 600 "${config_file}"
}

deploy_agent_files() {
    log_step "Deploying agent workspaces..."
    for agent in "${AGENT_DIRS[@]}"; do
        local workspace="${OPENCLAW_DIR}/workspace-${agent}"
        local source="${TEAM_DIR}/agents/${agent}"
        # Declarative files: always refresh.
        for file in SOUL.md IDENTITY.md AGENTS.md HEARTBEAT.md; do
            [[ -f "${source}/${file}" ]] && cp "${source}/${file}" "${workspace}/${file}"
        done
        # USER.md: seed-once so operator customizations survive re-deploys.
        if [[ ! -f "${workspace}/USER.md" && -f "${source}/USER.md" ]]; then
            cp "${source}/USER.md" "${workspace}/USER.md"
        fi
        ln -sfn "${OPENCLAW_DIR}/shared" "${workspace}/shared"
        log_ok "workspace-${agent}"
    done
}

deploy_shared_files() {
    log_step "Deploying shared workspace..."
    [[ -d "${TEAM_DIR}/shared" ]] || return 0

    # Copy the entire shared/ tree EXCEPT skills/ (deployed separately into
    # ~/.openclaw/skills) and BOOTSTRAP.md (sentinel-gated below). This carries
    # any team-specific working dirs or reference data (e.g. accountant/tax/).
    shopt -s dotglob nullglob
    local entry base
    for entry in "${TEAM_DIR}/shared"/*; do
        base="$(basename "$entry")"
        # skills/ → ~/.openclaw/skills; STANDARDS.md/BOOTSTRAP.md are canonical
        # and deployed from _template (below); both handled outside this loop.
        [[ "$base" == "skills" || "$base" == "BOOTSTRAP.md" || "$base" == "STANDARDS.md" ]] && continue
        # VISION.md: seed-once so live mission edits survive re-deploys (the
        # operator owns it once seeded). Overwrite deliberately with --vision
        # (handled below) — not on every deploy.
        if [[ "$base" == "VISION.md" && -f "${OPENCLAW_DIR}/shared/VISION.md" ]]; then
            log_ok "VISION.md skipped (preserving live mission — use --vision to overwrite)"
            continue
        fi
        if [[ -d "$entry" ]]; then
            mkdir -p "${OPENCLAW_DIR}/shared/${base}"
            cp -R "${entry}/." "${OPENCLAW_DIR}/shared/${base}/"
        else
            cp "$entry" "${OPENCLAW_DIR}/shared/${base}"
        fi
        log_ok "${base}"
    done
    shopt -u dotglob nullglob

    # STANDARDS.md: canonical, always refresh so updates propagate. Sourced from
    # the team's own copy if it has one, else from _template (single source).
    local standards_src; standards_src="$(canonical_src STANDARDS.md)"
    if [[ -n "$standards_src" ]]; then
        cp "$standards_src" "${OPENCLAW_DIR}/shared/STANDARDS.md"
        log_ok "STANDARDS.md"
    else
        log_warn "STANDARDS.md not found (team or _template) — skipped"
    fi

    # BOOTSTRAP.md: canonical too, but seed-once. Drop only if neither the file
    # nor the sentinel exists; the agent self-deletes it on first run and the
    # sentinel prevents re-drop. Sourced from team copy, else _template.
    local sentinel="${OPENCLAW_DIR}/shared/.bootstrap-deployed"
    local bootstrap_src; bootstrap_src="$(canonical_src BOOTSTRAP.md)"
    if [[ -n "$bootstrap_src" ]]; then
        if [[ ! -f "${OPENCLAW_DIR}/shared/BOOTSTRAP.md" && ! -f "${sentinel}" ]]; then
            cp "$bootstrap_src" "${OPENCLAW_DIR}/shared/BOOTSTRAP.md"
            touch "${sentinel}"
            log_ok "BOOTSTRAP.md (first install)"
        else
            log_ok "BOOTSTRAP.md skipped (sentinel present)"
        fi
    fi
}

deploy_skills() {
    [[ ${#SKILL_SRCS[@]} -eq 0 ]] && return 0
    log_step "Installing skills..."
    for src in "${SKILL_SRCS[@]}"; do
        local name; name="$(basename "$(dirname "$src")")"
        local dest="${OPENCLAW_DIR}/skills/${name}"
        mkdir -p "${dest}"
        cp "${src}" "${dest}/SKILL.md"
        log_ok "${name}"
    done
}

create_env_template() {
    if [[ ! -f "${OPENCLAW_DIR}/.env" ]]; then
        log_step "Creating .env template..."
        # A team may ship its own env.template (extra provider/service keys).
        if [[ -f "${TEAM_DIR}/env.template" ]]; then
            cp "${TEAM_DIR}/env.template" "${OPENCLAW_DIR}/.env"
            chmod 600 "${OPENCLAW_DIR}/.env"
            log_ok "Created .env from team template"
            return
        fi
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
        log_ok "Created .env template"
    else
        log_ok ".env already exists — skipping"
    fi
}

set_vision_inline() {
    local vision_text="$1"
    [[ -z "$vision_text" ]] && return 0
    local vision_file="${OPENCLAW_DIR}/shared/VISION.md"
    [[ -f "$vision_file" ]] || return 0
    log_step "Setting Vision from command line..."
    if [[ "$have_node" == true ]]; then
        VISION_TEXT="$vision_text" node -e "
const fs=require('fs');
const f='${vision_file}';
let c=fs.readFileSync(f,'utf8');
const v=process.env.VISION_TEXT.trim();
// Replace the first markdown blockquote block (the mission statement).
if(/^>.*/m.test(c)){
  c=c.replace(/^>.*(?:\n>.*)*/m, '> **'+v+'**');
} else {
  c=c.replace(/(## Mission Statement\s*\n)/, '\$1\n> **'+v+'**\n');
}
fs.writeFileSync(f,c);
"
        log_ok "Vision set"
    else
        log_warn "node not available — edit shared/VISION.md manually"
    fi
}

print_summary() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  Setup Complete!                                 ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Team:${NC} ${TEAM_NAME}  (${#AGENT_DIRS[@]} agents, ${#SKILL_SRCS[@]} skills)"
    if [[ "$have_node" == true ]]; then
        echo -e "${BOLD}Agents:${NC}"
        node -e "const c=require('${INCOMING_JSON}'); (c.agents?.list||[]).forEach(a=>console.log('  ● '+(a.name||a.id)+'  ('+a.id+')'))"
    fi
    echo ""
    echo -e "${BOLD}Directory:${NC} ${OPENCLAW_DIR}/"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo -e "  1. Set your API key:   ${DIM}edit ${OPENCLAW_DIR}/.env${NC}"
    echo -e "  2. Configure Vision:   ${DIM}edit ${OPENCLAW_DIR}/shared/VISION.md${NC}"
    echo -e "  3. Start the gateway:  ${DIM}openclaw start${NC}"
    echo ""
}

# ── Main ───────────────────────────────────────────────────
banner

if [[ "$DO_UNINSTALL" == true ]]; then
    uninstall
fi
if [[ "$DO_CLEAN" == true ]]; then
    clean_install
fi

check_openclaw
create_directories
deploy_config
deploy_agent_files
deploy_shared_files
deploy_skills
create_env_template

if [[ -n "$VISION_TEXT" ]]; then
    set_vision_inline "$VISION_TEXT"
fi

print_summary
