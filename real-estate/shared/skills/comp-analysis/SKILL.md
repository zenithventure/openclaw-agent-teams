# Skill: Comparable Property Analysis

## Purpose
Estimate property value by analyzing recent sales of similar properties, adjusted for differences.

## Comp Selection Criteria

A good comparable should be:
- **Recent:** Sold within the last 12 months (6 months preferred)
- **Proximate:** Within the same submarket (1-3 mile radius for urban, wider for suburban/rural)
- **Similar:** Same property type, similar size (±25% units/SF), similar age/condition
- **Arm's length:** Not distressed sales, foreclosures, or related-party transactions (unless market is distressed)

Minimum 3 comps, target 5+. Note when comps are thin and confidence is lower.

## Adjustment Categories

| Factor | Adjust For |
|--------|-----------|
| **Location** | Submarket quality, proximity to amenities, school district |
| **Size** | Per-unit or per-SF pricing varies with scale |
| **Age/Condition** | Renovated properties command premium over deferred maintenance |
| **Amenities** | Pool, gym, parking, laundry, in-unit W/D |
| **Timing** | Market appreciation/depreciation since sale date |
| **Occupancy** | Stabilized vs. lease-up or high vacancy |
| **Financing** | Seller financing or unusual terms that affect price |

## Analysis Format

```
# Comparable Sales Analysis — [Subject Property]

## Subject Property
Address, type, units/SF, year built, asking price, asking cap rate

## Comparable Sales

| # | Address | Sale Date | Price | $/Unit | $/SF | Cap Rate | Units | Year Built |
|---|---------|-----------|-------|--------|------|----------|-------|------------|
| 1 | ... | ... | ... | ... | ... | ... | ... | ... |

## Adjustments

| Comp | Base $/Unit | Location | Size | Condition | Timing | Adjusted $/Unit |
|------|------------|----------|------|-----------|--------|-----------------|

## Indicated Value
- Low: $X (based on comp [n])
- Mid: $X (average of adjusted comps)
- High: $X (based on comp [n])
- Asking price vs. indicated: X% premium/discount

## Confidence Level
- High / Medium / Low — based on comp quality and quantity
- Notes on data gaps or unusual market conditions
```

## Rules

1. Always show raw comp data AND adjustments separately
2. Note the source of each comp
3. Flag any comp that required significant adjustment (>15%)
4. Exclude outliers but note them separately with explanation
5. State confidence level explicitly
