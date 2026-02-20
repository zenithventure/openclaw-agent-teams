# Skill: Transaction Categorization

## Purpose
Consistently and accurately categorize bank transactions into the correct chart of accounts categories.

## Rules

1. **Match vendor first.** If you've seen this vendor before, use the same category as last time unless the amount or context suggests otherwise.
2. **Use the chart of accounts.** Every transaction maps to a specific account. Don't invent new categories without Controller approval.
3. **Ask when uncertain.** Flag the transaction with `[NEEDS REVIEW]` rather than guessing. Wrong categories are worse than uncategorized.
4. **One transaction, one category.** If a transaction spans multiple categories (e.g., a mixed purchase), split it with a journal entry.
5. **Revenue is not a deposit.** Owner contributions, refunds, and transfers are not revenue. Categorize them correctly.

## Common Categories

| Category | Examples |
|----------|----------|
| Revenue | Client payments, product sales, service fees |
| COGS | Direct materials, manufacturing costs, subcontractor payments for client work |
| Payroll | Salaries, wages, contractor payments (1099) |
| Rent & Occupancy | Office rent, coworking space, utilities |
| Software & SaaS | Subscriptions, hosting, domain names |
| Marketing | Ads, sponsorships, design services |
| Professional Services | Legal, accounting, consulting fees |
| Travel & Meals | Business travel, client meals (50% deductible) |
| Office Supplies | Equipment under $2,500, supplies, furniture |
| Insurance | Business insurance, health insurance (if business-paid) |
| Bank & Payment Fees | Stripe fees, bank charges, wire fees |
| Owner Draw / Distribution | Money taken out by owner (not an expense) |
| Transfer | Movement between accounts (not income or expense) |

## Red Flags to Watch

- **Large round numbers** — $5,000.00 exactly may be an estimate or transfer, not a real expense
- **New vendors** — flag for human confirmation on first appearance
- **Personal expenses** — gym memberships, groceries, personal subscriptions on business account
- **Duplicate transactions** — same amount, same vendor, same day
- **Refunds categorized as revenue** — refunds should reduce the original expense category

## Process

1. Import transactions from CSV or bank feed
2. Auto-match known vendors to established categories
3. Review unmatched transactions manually
4. Flag uncertain items with `[NEEDS REVIEW]` tag
5. Submit batch to Controller for approval
6. Apply Controller's corrections and update vendor-category mappings
