> **Baseline:** Read `shared/STANDARDS.md` first — it defines session startup, memory, safety, and communication rules that apply to every agent. This file covers your role-specific instructions.

# AGENTS.md — [Agent Role]'s Workspace

This folder is home. Treat it that way.

<!-- ─────────────────────────────────────────────────────────
  TEMPLATE INSTRUCTIONS (delete this comment block when done):

  The baseline reference above is REQUIRED. It tells the agent to load
  shared/STANDARDS.md before reading this file. STANDARDS.md handles:
    - Session startup sequence (read SOUL, USER, VISION, memory)
    - Memory management (daily notes, MEMORY.md, security)
    - Safety rules (trash not rm, no exfiltration, ask first)
    - Group chat behavior
    - Platform formatting
    - Heartbeat vs cron

  You do NOT need to repeat any of that here. This file is only for
  role-specific instructions that go beyond the baseline.

  The two required sections below are Core Workflow and Safety.
  You may add others if the role needs them (e.g., "## Tools" or
  "## Integration Points"), but these two are the minimum.
───────────────────────────────────────────────────────────── -->

## Core Workflow

<!-- Describe the step-by-step process this agent follows to do its job.
     Be specific. Use numbered steps. Each step should be a concrete action,
     not a vague goal.

     Example (for an Architect agent):
       1. Receive a product idea or feature request
       2. Create system specification — user stories, data models, design guidelines
       3. Create system architecture — three-tier design, tech stack, integration points
       4. Break into GitHub Issues — each issue is ~10 minutes of work
       5. Review Builder's implementation against specs
       6. Update specs when requirements evolve

     Example (for a QA agent):
       1. Read the spec and architecture docs for the feature under test
       2. Write test plan — what to test, edge cases, acceptance criteria
       3. Run existing test suite and report results
       4. Write new tests for untested paths
       5. File bugs as GitHub Issues with reproduction steps
       6. Verify fixes against original spec
-->

1. [First step — what triggers this agent's work?]
2. [Second step — what does the agent produce or do?]
3. [Third step — how does the output get used by the team?]
4. [Fourth step — ongoing maintenance or review cycle]

## Safety

<!-- Define what this agent must NOT do. These are role-specific guardrails
     that supplement the baseline safety rules in STANDARDS.md.

     Good safety rules are concrete and actionable:
       - "Don't implement code. That's Builder's job. You design."
       - "Don't skip the spec phase, no matter how simple the feature seems."
       - "Never merge a PR without passing tests."
       - "Don't approve your own work. Send it to Blue for review."

     Bad safety rules are vague:
       - "Be careful."
       - "Follow best practices."
       - "Don't make mistakes."
-->

- [What this agent must never do, even if asked]
- [What decisions this agent must escalate to the human]
- [What belongs to another agent's domain — hands off]
