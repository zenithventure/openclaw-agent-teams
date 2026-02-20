# Skill: Financial Document Review

## Purpose
Review property financial documents (T12, rent rolls, historicals) for accuracy, consistency, and red flags.

## T12 (Trailing 12-Month Operating Statement) Review

### Income Verification
- Does gross potential rent match rent roll × 12?
- Are vacancy and concession deductions reasonable? (compare to market)
- Is other income (laundry, parking, fees) consistent with property type?
- Any one-time income items that should be excluded from normalized NOI?

### Expense Verification
- Do expense line items fall within market benchmarks for this property type?
- Any suspiciously low categories? (deferred maintenance hiding in low R&M)
- Any suspiciously high categories? (one-time capital items mixed with operating expenses)
- Is management fee included? At what rate? (typically 4-8% for multifamily)
- Are property taxes based on current assessment or projected post-sale reassessment?
- Is insurance adequate for the property?

### Common T12 Red Flags
| Red Flag | What It Means |
|----------|--------------|
| R&M under $300/unit | Likely deferred maintenance |
| No management fee | Owner-managed — add 5-6% for normalization |
| Property tax based on old assessment | Will increase on sale — re-estimate |
| Insurance well below market | May be underinsured or old quote |
| Utilities included in rent but no utility expense | Something is missing |
| Capital items in operating expenses | Inflated OpEx, understated NOI |

## Rent Roll Review

### Verify
- Unit count matches property records
- Current rent vs. market rent (above, at, or below?)
- Lease expiration schedule — concentration risk?
- Any month-to-month tenants (risk of vacancy)
- Concessions — are they one-time or ongoing?
- Tenant mix — any single tenant > 20% of revenue? (concentration risk)

## 3-Year Historical Review

### Trend Analysis
- Revenue trend: growing, flat, declining?
- Expense trend: growing faster than revenue?
- NOI trend: expanding or compressing margins?
- Occupancy trend: stable, improving, declining?
- Any anomalous years that need explanation?

## Cross-Document Verification

The most important step — do the documents tell a consistent story?

| Check | Compare |
|-------|---------|
| T12 revenue vs. rent roll × 12 | Should be close (within 5%) |
| T12 occupancy vs. rent roll vacancy | Should match |
| T12 expenses vs. historical average | Major deviations need explanation |
| Broker pro forma vs. T12 actuals | Pro forma is always higher — quantify the gap |

## Output Format

```
# Financial Review — [Property]

## Summary
- Reported NOI: $X
- Normalized NOI: $X (adjustments: [list])
- Risk Score: [1-5]

## Findings
### 🔴 Critical (deal-affecting)
- [finding with evidence]

### 🟡 Notable (investigate further)
- [finding with evidence]

### 🟢 Clean
- [areas that checked out]

## Recommended Adjustments
| Item | Reported | Adjusted | Reason |
|------|----------|----------|--------|

## Normalized NOI Calculation
[show the math]
```
