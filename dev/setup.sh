#!/usr/bin/env bash
# ============================================================
# Thin shim — deploys this team via the shared generic deployer
# at lib/deploy-team.sh. The team is pure data (openclaw.json,
# agents/, shared/, skills/); this script just points the
# deployer at this directory.
#
# All flags pass through:
#   ./setup.sh                 # install / update
#   ./setup.sh --clean         # wipe this team, then reinstall
#   ./setup.sh --uninstall     # remove this team
#   ./setup.sh --vision "..."  # set the mission inline
#   ./setup.sh --help
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${SCRIPT_DIR}/../lib/deploy-team.sh" --team-dir "${SCRIPT_DIR}" "$@"
