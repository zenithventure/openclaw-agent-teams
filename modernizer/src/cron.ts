import { join } from 'node:path';
import { homedir } from 'node:os';

export function buildCronPrompt(agentId: string): string {
  const cliPath = join(homedir(), '.openclaw', 'workspace', 'legacy-mod', 'dist', 'cli.js');
  return `You are a Legacy Modernization workflow agent. Check for pending work.

Step 1 — Check for work:
  node ${cliPath} step claim "${agentId}"

If output is "NO_WORK", reply HEARTBEAT_OK and stop.

Step 2 — If JSON is returned, read the "input" field. It contains your task.

Step 3 — Execute the task described in "input". Follow your SOUL.md and AGENTS.md.

Step 4 — MANDATORY: Report completion:
  Write your output to a temp file, then pipe it to step complete:

  cat <<'EOF' > /tmp/legacy-mod-output.txt
  STATUS: done
  KEY1: value1
  KEY2: value2
  EOF
  cat /tmp/legacy-mod-output.txt | node ${cliPath} step complete "<stepId>"

If the work FAILED:
  node ${cliPath} step fail "<stepId>" "description of failure"

IMPORTANT: You MUST call step complete or step fail before ending your session.`;
}
