#!/usr/bin/env bash

# ============================================================
# OpenClaw Team Validator
# ============================================================
# Mechanizes the authoring checklist in CLAUDE.md so a broken
# team is caught at commit/PR time instead of at deploy time.
#
# Checks (per team):
#   - structural: openclaw.json (valid JSON) + agents/ + >=1 agent
#   - agents/<id>/ dirs <-> openclaw.json ids match (generic teams)
#   - workspace path convention ~/.openclaw/workspace-<id>
#   - every agent has IDENTITY/SOUL/AGENTS/HEARTBEAT/USER.md
#   - every AGENTS.md has the baseline line + Core Workflow + Safety
#   - shared/ has VISION/STANDARDS/BOOTSTRAP/standup-log.md
#   - STANDARDS.md and BOOTSTRAP.md are byte-identical to _template
#   - setup.sh (if any) passes `bash -n`
#   - optional (--deploy): temp-dir deploy smoke test
#
# A "bespoke" team (setup.sh that does NOT forward to
# lib/deploy-team.sh, e.g. modernizer) is exempt from the
# id<->dir and workspace-convention checks, mirroring the
# Ansible playbook's `team_is_generic` gate.
#
# Usage:
#   bash lib/validate-team.sh --team-dir <path>   # one team
#   bash lib/validate-team.sh --all               # every team in the repo
#   bash lib/validate-team.sh --all --deploy      # also smoke-test deploys
#   bash lib/validate-team.sh --help
#
# Exit status: 0 if all validated teams pass, 1 otherwise.
# ============================================================

set -uo pipefail

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_SHARED="${REPO_ROOT}/_template/shared"

# ── Per-team check accounting ──────────────────────────────
ERRORS=0
WARNS=0
err()  { echo -e "    ${RED}✗${NC} $1"; ERRORS=$((ERRORS+1)); }
warn() { echo -e "    ${YELLOW}!${NC} $1"; WARNS=$((WARNS+1)); }
ok()   { echo -e "    ${GREEN}✓${NC} $1"; }

have_node=false
command -v node &>/dev/null && have_node=true

# ── Is this team deployed by the generic deployer? ─────────
# Mirrors openclaw-team.yml: generic iff no setup.sh, or setup.sh
# forwards to lib/deploy-team.sh. Bespoke teams (modernizer) are
# exempt from id<->dir / workspace-convention checks.
is_generic() {
    local dir="$1"
    [[ ! -f "${dir}/setup.sh" ]] && return 0
    grep -q "deploy-team.sh" "${dir}/setup.sh" && return 0
    return 1
}

# ── Validate one team ──────────────────────────────────────
# Returns 0 if the team passed (no errors), 1 otherwise.
validate_team() {
    local dir name generic
    dir="$(cd "$1" 2>/dev/null && pwd || true)"
    if [[ -z "$dir" || ! -d "$dir" ]]; then
        echo -e "  ${RED}✗ not a directory:${NC} $1"; return 1
    fi
    name="$(basename "$dir")"
    ERRORS=0; WARNS=0
    echo -e "\n${BOLD}▶ ${name}${NC} ${DIM}(${dir})${NC}"

    # 1. Structural ----------------------------------------------------------
    # agents/ is required; openclaw.json is optional (the deployer synthesizes
    # one from agents/ for uniform teams).
    [[ -d "${dir}/agents" ]] || err "missing agents/ directory"

    # Collect agent dirs.
    local agent_dirs=()
    if [[ -d "${dir}/agents" ]]; then
        while IFS= read -r d; do [[ -n "$d" ]] && agent_dirs+=("$(basename "$d")"); done \
            < <(find "${dir}/agents" -mindepth 1 -maxdepth 1 -type d | sort)
    fi
    [[ ${#agent_dirs[@]} -ge 1 ]] || err "no agent directories under agents/"

    # openclaw.json: if present, must be valid JSON; pull ids + workspaces. If
    # absent, the deployer synthesizes it from agents/ (ids = dir names), so
    # there's nothing to mismatch. has_json = file present; json_ok = parsed OK.
    local json_ids=() json_ws="" has_json=false json_ok=false
    if [[ -f "${dir}/openclaw.json" ]]; then
        has_json=true
        if [[ "$have_node" == true ]]; then
            if ! node -e "JSON.parse(require('fs').readFileSync('${dir}/openclaw.json','utf8'))" 2>/dev/null; then
                err "openclaw.json is not valid JSON"
            else
                ok "openclaw.json is valid JSON"
                json_ok=true
                while IFS= read -r id; do [[ -n "$id" ]] && json_ids+=("$id"); done \
                    < <(node -e "const c=require('${dir}/openclaw.json');(c.agents?.list||[]).forEach(a=>console.log(a.id))")
                json_ws="$(node -e "const c=require('${dir}/openclaw.json');(c.agents?.list||[]).forEach(a=>console.log((a.id||'')+'\t'+(a.workspace||'')))")"
            fi
        else
            warn "node not found — skipping JSON-level checks"
        fi
    else
        ok "openclaw.json omitted — deployer synthesizes it from agents/ (ids = dir names)"
        json_ids=("${agent_dirs[@]}")
    fi

    generic=true; is_generic "$dir" || generic=false

    # 2. agents/<id> ⇄ openclaw.json ids (generic teams that ship a json) ----
    if [[ "$generic" == true && "$has_json" == true && "$json_ok" == true ]]; then
        if [[ ${#json_ids[@]} -eq 0 ]]; then
            err "openclaw.json registers zero agents (agents.list is empty or missing) — a team must register at least one"
        else
            local only_dirs="" only_json="" d id found
            for d in "${agent_dirs[@]}"; do
                found=false; for id in "${json_ids[@]}"; do [[ "$d" == "$id" ]] && found=true; done
                [[ "$found" == false ]] && only_dirs+="${d} "
            done
            for id in "${json_ids[@]}"; do
                found=false; for d in "${agent_dirs[@]}"; do [[ "$d" == "$id" ]] && found=true; done
                [[ "$found" == false ]] && only_json+="${id} "
            done
            if [[ -n "$only_dirs" || -n "$only_json" ]]; then
                err "agents/<id> ⇄ openclaw.json mismatch — dirs only: [${only_dirs:-none}], json only: [${only_json:-none}]"
            else
                ok "agents/ dirs and openclaw.json ids match (${#json_ids[@]} agents)"
            fi
            # Workspace: must be present on every agent, and follow the convention.
            local wid wws
            while IFS=$'\t' read -r wid wws; do
                [[ -z "$wid" ]] && continue
                if [[ -z "$wws" ]]; then
                    err "agent '${wid}' has no 'workspace' in openclaw.json"
                elif [[ "$wws" != "~/.openclaw/workspace-${wid}" ]]; then
                    warn "agent '${wid}' workspace is '${wws}' (convention: ~/.openclaw/workspace-${wid})"
                fi
            done <<< "$json_ws"
        fi
    elif [[ "$generic" == false ]]; then
        ok "bespoke team (setup.sh) — skipping id⇄dir + workspace convention checks"
    fi

    # 3. Per-agent required files + AGENTS.md contract -----------------------
    local a f
    for a in "${agent_dirs[@]}"; do
        for f in IDENTITY.md SOUL.md AGENTS.md HEARTBEAT.md USER.md; do
            [[ -f "${dir}/agents/${a}/${f}" ]] || err "agents/${a}/ missing ${f}"
        done
        local ag="${dir}/agents/${a}/AGENTS.md"
        if [[ -f "$ag" ]]; then
            # Baseline reference is load-bearing (every team has it) → error.
            grep -q '^> \*\*Baseline:\*\*' "$ag" || err "agents/${a}/AGENTS.md missing the '> **Baseline:**' line"
            grep -q 'STANDARDS.md' "$ag"          || err "agents/${a}/AGENTS.md baseline must reference STANDARDS.md"
            # Section names are a recommendation; built-in teams (operator,
            # modernizer) use equivalent headings, so warn rather than fail.
            grep -q '^## Core Workflow' "$ag"      || warn "agents/${a}/AGENTS.md has no '## Core Workflow' (recommended by CLAUDE.md)"
            grep -q '^## Safety' "$ag"             || warn "agents/${a}/AGENTS.md has no '## Safety' (recommended by CLAUDE.md)"
        fi
    done
    [[ $ERRORS -eq 0 ]] && ok "required agent files present + baseline reference"

    # 4. shared/ required files ----------------------------------------------
    # Teams own VISION.md + standup-log.md. STANDARDS.md/BOOTSTRAP.md are
    # canonical and sourced from _template by the deployer — teams need not
    # vendor them (see check 5).
    for f in VISION.md standup-log.md; do
        [[ -f "${dir}/shared/${f}" ]] || err "shared/ missing ${f}"
    done

    # 5. Canonical files (STANDARDS.md, BOOTSTRAP.md) -------------------------
    # Single source of truth is _template/shared. A team should NOT vendor its
    # own copy; the deployer supplies it. _template itself must carry them, and
    # any team that does ship an override (e.g. bespoke modernizer) must keep it
    # byte-identical so there's no drift.
    if [[ "$name" == "_template" ]]; then
        for f in STANDARDS.md BOOTSTRAP.md; do
            [[ -f "${dir}/shared/${f}" ]] || err "_template/shared/${f} missing (canonical source for every team)"
        done
        ok "canonical source files present in _template"
    else
        local f drift=false
        for f in STANDARDS.md BOOTSTRAP.md; do
            if [[ -f "${dir}/shared/${f}" ]]; then
                # An override copy must never drift from canonical.
                if [[ -z "$TEMPLATE_SHARED" ]] || ! diff -q "${TEMPLATE_SHARED}/${f}" "${dir}/shared/${f}" >/dev/null 2>&1; then
                    err "shared/${f} differs from _template (canonical — make it byte-identical or remove it)"; drift=true
                elif [[ "$generic" == true ]]; then
                    # Generic teams don't need it — the deployer supplies it.
                    warn "shared/${f} is a redundant copy of _template (deployer supplies it) — consider removing"
                fi
                # Bespoke teams (modernizer) legitimately vendor their own copy.
            elif [[ "$generic" == true && ( -z "$TEMPLATE_SHARED" || ! -f "${TEMPLATE_SHARED}/${f}" ) ]]; then
                err "shared/${f} absent and no _template source — the deploy would skip it"; drift=true
            elif [[ "$generic" == false ]]; then
                warn "bespoke team has no shared/${f}; its setup.sh may expect one"
            fi
        done
        [[ "$drift" == false ]] && ok "canonical files resolve cleanly (no drift)"
    fi

    # 6. setup.sh syntax (if present) ----------------------------------------
    if [[ -f "${dir}/setup.sh" ]]; then
        if bash -n "${dir}/setup.sh" 2>/dev/null; then ok "setup.sh passes bash -n"
        else err "setup.sh has a bash syntax error (bash -n)"; fi
    fi

    # 7. Optional deploy smoke test ------------------------------------------
    if [[ "$DO_DEPLOY" == true ]]; then
        local tmp; tmp="$(mktemp -d)"
        if OPENCLAW_DIR="$tmp" bash "${REPO_ROOT}/lib/deploy-team.sh" --team-dir "$dir" >/dev/null 2>&1 \
           && [[ -n "$(find "$tmp" -maxdepth 1 -name 'workspace-*' -print -quit)" ]]; then
            ok "deploy smoke test (deployed to a temp dir)"
        else
            err "deploy smoke test failed"
        fi
        rm -rf "$tmp"
    fi

    # ── Verdict ──
    if [[ $ERRORS -eq 0 ]]; then
        echo -e "  ${GREEN}PASS${NC} ${name} ${DIM}(${WARNS} warning(s))${NC}"
        return 0
    fi
    echo -e "  ${RED}FAIL${NC} ${name} ${DIM}(${ERRORS} error(s), ${WARNS} warning(s))${NC}"
    return 1
}

# ── Discover teams (dir with openclaw.json + agents/) ──────
discover_teams() {
    local d
    for d in "${REPO_ROOT}"/*/; do
        [[ -d "${d}agents" ]] && echo "${d%/}"
    done
}

# ── Args ───────────────────────────────────────────────────
TEAM_DIR=""; DO_ALL=false; DO_DEPLOY=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --team-dir) shift; TEAM_DIR="${1:-}" ;;
        --all)      DO_ALL=true ;;
        --deploy)   DO_DEPLOY=true ;;
        --help|-h)  sed -n '/^# Usage:/,/^# ====/p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; exit 2 ;;
    esac
    shift
done

if [[ "$DO_DEPLOY" == true && "$have_node" != true ]]; then
    echo -e "${YELLOW}!${NC} --deploy needs node for the JSON merge; smoke test may be limited." >&2
fi

# ── Run ────────────────────────────────────────────────────
echo -e "${BOLD}OpenClaw team validator${NC}  ${DIM}(repo: ${REPO_ROOT})${NC}"
declare -a TARGETS=()
if [[ "$DO_ALL" == true ]]; then
    while IFS= read -r t; do TARGETS+=("$t"); done < <(discover_teams)
elif [[ -n "$TEAM_DIR" ]]; then
    TARGETS=("$TEAM_DIR")
else
    echo "Provide --team-dir <path> or --all" >&2; exit 2
fi

[[ ${#TARGETS[@]} -eq 0 ]] && { echo "No teams found to validate." >&2; exit 2; }

FAILED=()
for t in "${TARGETS[@]}"; do
    if ! validate_team "$t"; then FAILED+=("$(basename "$t")"); fi
done

echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
if [[ ${#FAILED[@]} -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All ${#TARGETS[@]} team(s) passed.${NC}"
    exit 0
fi
echo -e "${RED}${BOLD}${#FAILED[@]} of ${#TARGETS[@]} team(s) failed:${NC} ${FAILED[*]}"
exit 1
