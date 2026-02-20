# Accountant — AI Back-Office Accounting Team

An OpenClaw agent team that handles day-to-day bookkeeping, financial reporting, and tax prep for small businesses. Four agents work together to categorize transactions, generate reports, review everything for accuracy, and keep you on top of tax deadlines.

## What This Team Does

- Categorizes bank transactions from CSV exports or bank feeds
- Manages accounts payable and receivable
- Generates monthly P&L statements, balance sheets, and cash flow reports
- Tracks KPIs like burn rate, gross margin, and runway
- Flags tax deductions and estimates quarterly tax payments
- Reconciles bank statements against your books
- Catches errors before they compound

## Who It's For

- Freelancers and solo consultants
- Small business owners (1-20 employees)
- Startups without a CFO
- Side project operators tracking revenue
- Anyone currently paying for bookkeeping they could automate

## What It Replaces

- **$500/month bookkeeper** — Bookkeeper agent handles daily categorization and entries
- **$2,000/month fractional controller** — Controller agent reviews and approves everything
- **$300/month reporting tools** — Reporter generates standard financial statements on demand
- **$1,500+ quarterly tax prep** — Tax Prep agent tracks deductions and estimates year-round

## The Team

| Agent | Color | DISC | Role |
|-------|-------|------|------|
| **Controller** | 🔴 Red | Dominant | Reviews and approves. Final sign-off on reports. Read-only — cannot modify books. |
| **Bookkeeper** | 🟡 Yellow | Influencer | Categorizes transactions, manages AP/AR, day-to-day entries. Explains in plain English. |
| **Reporter** | 🟢 Green | Steady | Generates P&L, balance sheet, cash flow. Tracks KPIs. Consistent and on-schedule. |
| **Tax Prep** | 🔵 Blue | Conscientious | Flags deductions, tracks quarterly estimates, monitors compliance deadlines. Cites tax code. |

## Example Workflow

1. You export your bank transactions as a CSV (or connect a feed)
2. **Bookkeeper** categorizes each transaction (revenue, COGS, operating expense, etc.)
3. **Controller** reviews the categorizations, flags anything that looks wrong
4. **Reporter** generates your monthly P&L, balance sheet, and cash flow statement
5. **Tax Prep** reviews the quarter's numbers, flags deductible expenses, and estimates your quarterly tax payment
6. You review the reports, file what needs filing, and move on with your life

## Skills

| Skill | What It Does |
|-------|-------------|
| `transaction-categorization` | Rules for categorizing bank transactions consistently |
| `financial-reporting` | Standards for P&L, balance sheet, and cash flow generation |
| `tax-compliance` | Quarterly estimate tracking, deduction identification, deadline monitoring |
| `reconciliation` | Bank reconciliation process and discrepancy resolution |
| `team-standup` | Coordinated team check-ins |
| `daily-report` | End-of-day summary generation |
| `vision-sync` | Alignment with the shared VISION.md |

## Setup

```bash
# Clone the repo
git clone https://github.com/zenithventure/openclaw-agent-teams.git
cd openclaw-agent-teams/accountant

# Run setup
./setup.sh

# Configure your vision
# Edit ~/.openclaw/shared/VISION.md with your business details

# Set your info
# Edit USER.md in each agent workspace

# Start
openclaw start
```

### Quick Start with Vision

```bash
./setup.sh --vision "Manage bookkeeping for my freelance consulting business. Track income from 3 clients, categorize expenses, generate monthly P&L, estimate quarterly taxes."
```

## Installation

### Quick Start (DigitalOcean)

The fastest way to get running:

1. **Deploy a DO OpenClaw droplet** from the [DigitalOcean Marketplace](https://marketplace.digitalocean.com/apps/openclaw)
2. **SSH into your droplet:**
   ```bash
   ssh root@your-droplet-ip
   ```
3. **Download and run the team installer:**
   ```bash
   curl -sL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/accountant/do-team-install.sh | bash -s -- accountant
   ```
4. **Open your OpenClaw dashboard** at `https://your-droplet-ip`
5. **Connect your messaging platform** (Telegram, WhatsApp, Discord, etc.)
6. **Edit `shared/VISION.md`** with your accounting context
7. **Start sending messages** to your agents!

**What the installer does:**
- Unlocks execution policies (enables agents to actually run tools)
- Injects team configuration into the sandbox
- Deploys 4 agents with DISC personalities
- Restarts OpenClaw to load everything

### Advanced (Bare Metal / Self-Hosted)

If you're running OpenClaw on your own infrastructure:

```bash
./setup.sh                    # Interactive setup
./setup.sh --clean            # Wipe and reinstall
./setup.sh --uninstall        # Remove everything
./setup.sh --vision "TEXT"    # Set VISION inline
./setup.sh --help             # Show help
```

See the [OpenClaw documentation](https://docs.openclaw.ai) for installation steps.

## Security Model

### How the Agents Run

**On DigitalOcean (Recommended):**
- Agents run under a dedicated `openclaw` user (not root)
- Execution happens inside a Docker container sandbox
- Network and filesystem access are restricted by default
- Execution policies must be explicitly unlocked (with full transparency about what each does)
- This is intentional — agents have guardrails

**Benefits:**
- Agents cannot escalate to root or modify system config
- Cannot access files outside their workspace
- Cannot bypass network restrictions
- Governance is enforced at the system level, not just by promises

**On Bare Metal:**
- Agents run with permissions you explicitly grant
- More control, but also more responsibility
- We recommend applying the same security principles: run as non-root, use process isolation, restrict network access

### Why This Matters

"Trusting the AI to be good" is not security. Trusting OpenClaw's execution model is.

When you see "tools.exec.security full" in the setup, you're saying: "I trust the agents to make network calls and write files, within the sandbox." You're not saying "agents can do anything." The sandbox is the boundary.

If you need a different security posture (more restrictive or less), you control it.

## Examples

See the `examples/` folder for sample VISION files:

- **VISION-freelancer.md** — Solo consultant tracking income, expenses, quarterly taxes
- **VISION-ecommerce.md** — Small e-commerce store with inventory, sales tax, COGS
- **VISION-agency.md** — Service agency with multiple clients, project billing, payroll

## Limitations

- **Not a CPA.** This team is not a certified public accountant.
- **Not tax advice.** Tax Prep flags deductions and estimates payments, but a human tax professional should review filings.
- **Human review required for tax filings.** Never file taxes based solely on agent output.
- **No direct bank integrations.** You provide CSVs or data exports; agents don't connect to banks directly.
- **US-focused tax knowledge.** Tax compliance skills are primarily US-oriented. Adapt for other jurisdictions.

## License

MIT
