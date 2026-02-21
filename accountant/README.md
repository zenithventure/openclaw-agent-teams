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

## One-Line Install

```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/accountant/setup.sh
```

### After install

1. Edit `~/.openclaw/shared/VISION.md` with your business details
2. Update `USER.md` in each agent workspace with your info
3. Set your API key in `~/.openclaw/.env`
4. Run `openclaw start`

### Options

```bash
./setup.sh --vision "Manage bookkeeping for my freelance consulting business."
./setup.sh --clean                             # Wipe and reinstall
./setup.sh --uninstall                         # Remove everything
```

See the [OpenClaw documentation](https://docs.openclaw.ai) for full setup details.

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
