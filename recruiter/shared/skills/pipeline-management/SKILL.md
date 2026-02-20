# Skill: Pipeline Management

## Purpose
Track candidates through hiring stages with clear SLAs, ensuring no one falls through the cracks.

## Pipeline Stages

| Stage | SLA | Owner | Exit Criteria |
|-------|-----|-------|--------------|
| Sourced | — | Headhunter | Candidate identified |
| Screening | 3 days | Headhunter | Score ≥60% → advance |
| Phone Screen | 5 days | Coordinator schedules | Headhunter approves advance |
| Interview | 5 days | Coordinator schedules | Rubric score ≥ threshold |
| Final Interview | 5 days | Human schedules | Human decision |
| Offer | 3 days | Human | Offer extended |
| Accepted / Rejected | — | — | Pipeline complete |

## SLA Monitoring

- **Green:** Candidate has been in stage < 50% of SLA
- **Yellow:** Candidate has been in stage 50-100% of SLA
- **Red:** Candidate has exceeded stage SLA — escalate

## Pipeline Report Format

```
# Pipeline Report — [Date]

## Summary
- Total candidates: X
- Active: X | Rejected: X | Hired: X
- Average time in pipeline: X days
- SLA violations: X

## By Stage
| Stage | Count | Avg Days | SLA Status |
|-------|-------|----------|------------|

## Action Items
- [candidate] needs [action] by [date]

## Bottlenecks
- [stage] has [N] candidates waiting — investigate
```

## Rules

1. Every candidate gets a status update within 48 hours of any stage change
2. Rejections are communicated within 3 business days of the decision
3. No candidate sits in any stage longer than its SLA without documented reason
4. Pipeline report generated weekly (every Monday)
5. Human is notified of any SLA violations immediately
