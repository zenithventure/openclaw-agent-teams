---
name: compliance-check
description: Cross-cutting skill for verifying SOC 2 Phase 2 and GDPR compliance at any point in the legacy modernization process. Can be invoked at phase gates, per migration step, or on demand.
requirements:
  - Read access to codebase, infrastructure config, and shared workspace
  - Compliance matrix (if Phase 2+ is complete)
  - Ability to spawn sub-agents for parallel checks
---

# Compliance Check Skill

This skill runs a structured compliance verification against SOC 2 Phase 2 Trust Service Criteria and GDPR requirements. It can be used at any phase of the legacy modernization process.

## When to Use

- **Phase 1 gate:** Assess the legacy system's current compliance posture
- **Phase 2 gate:** Verify the target architecture and migration plan address all compliance requirements
- **Per migration step:** Verify each code change maintains or improves compliance
- **On demand:** When a compliance concern is raised by any team member
- **Pre-customer delivery:** Before any deliverable is sent to the customer

## SOC 2 Phase 2 — Trust Service Criteria

### CC — Common Criteria (Security)

| Control | Check | How to Verify |
|---------|-------|---------------|
| CC6.1 | Logical access controls | Review auth mechanisms, RBAC implementation, session management |
| CC6.2 | Access provisioning | Verify user creation/deletion flows, principle of least privilege |
| CC6.3 | Access removal | Verify deprovisioning, token revocation, session invalidation |
| CC6.6 | Security boundaries | Review network segmentation, API gateway, firewall rules |
| CC6.7 | Data transmission security | Verify TLS everywhere, certificate management, no plaintext PII in transit |
| CC6.8 | Malicious software prevention | Review dependency scanning, input validation, output encoding |
| CC7.1 | Monitoring and detection | Verify logging, alerting, intrusion detection setup |
| CC7.2 | Incident response | Verify incident response procedures exist and are documented |
| CC7.3 | Recovery procedures | Verify backup, restore, and disaster recovery processes |
| CC8.1 | Change management | Verify CI/CD pipeline, code review requirements, deployment approval flow |

### A — Availability

| Control | Check | How to Verify |
|---------|-------|---------------|
| A1.1 | Capacity management | Verify auto-scaling, resource monitoring, capacity planning |
| A1.2 | Recovery objectives | Verify RPO/RTO definitions, backup frequency, failover mechanisms |

### PI — Processing Integrity

| Control | Check | How to Verify |
|---------|-------|---------------|
| PI1.1 | Data accuracy | Verify input validation, data transformation correctness, reconciliation |
| PI1.2 | Error detection | Verify error handling, monitoring, alerting for data integrity issues |

### C — Confidentiality

| Control | Check | How to Verify |
|---------|-------|---------------|
| C1.1 | Data classification | Verify PII identification, data classification scheme, handling procedures |
| C1.2 | Data disposal | Verify data retention policies, secure deletion procedures |

### P — Privacy (overlaps with GDPR)

| Control | Check | How to Verify |
|---------|-------|---------------|
| P1.1 | Privacy notice | Verify privacy policy exists, covers all data collection points |
| P3.1 | Consent collection | Verify consent mechanisms, opt-in/opt-out flows |
| P4.1 | Data use limitation | Verify data is only used for stated purposes |
| P6.1 | Data subject access | Verify ability to export individual's data on request |
| P6.7 | Data disposal on request | Verify ability to delete individual's data (GDPR right to erasure) |

## GDPR — Key Articles

| Article | Requirement | How to Verify |
|---------|-------------|---------------|
| Art. 5 | Data processing principles | Verify lawfulness, purpose limitation, data minimization, accuracy, storage limitation, integrity |
| Art. 6 | Lawful basis for processing | Verify documented legal basis for each data processing activity |
| Art. 7 | Conditions for consent | Verify consent is freely given, specific, informed, unambiguous; withdrawal is easy |
| Art. 13-14 | Information to data subjects | Verify privacy notices at all data collection points |
| Art. 17 | Right to erasure | Verify ability to delete all personal data for an individual across all systems |
| Art. 20 | Right to data portability | Verify ability to export personal data in machine-readable format |
| Art. 25 | Data protection by design | Verify privacy is built into architecture, not bolted on. Pseudonymization, encryption at rest |
| Art. 32 | Security of processing | Verify encryption, access controls, resilience, regular testing |
| Art. 33 | Breach notification | Verify incident detection, 72-hour notification process, breach documentation |
| Art. 35 | Data Protection Impact Assessment | Verify DPIA exists for high-risk processing activities |

## Compliance Check Protocol

### Quick Check (per migration step, ~15 minutes)

Used for every code change before it ships:

1. **Data handling:** Does this change create, modify, or delete PII? If yes, verify GDPR Art. 5, 25, 32.
2. **Access control:** Does this change modify authentication or authorization? If yes, verify CC6.1-6.3.
3. **Encryption:** Does this change handle data in transit or at rest? If yes, verify CC6.7, GDPR Art. 32.
4. **Logging:** Does this change affect audit trails? If yes, verify CC7.1, GDPR Art. 33.
5. **Secrets:** Does this change introduce any hardcoded credentials, API keys, or tokens? Must be zero.

Record result: `[COMPLIANCE-QUICK] step-N: PASS/FAIL — notes`

### Full Audit (per phase gate, ~2-4 hours)

Used at major milestones:

1. Blue Lens spawns **compliance-verifier** sub-agents to check each control category in parallel
2. Each sub-agent produces a structured report against the applicable controls above
3. Blue Lens synthesizes findings into a unified compliance report
4. Green Anchor updates the compliance matrix with results
5. Any FAIL items become blockers — migration cannot proceed until remediated

Record result: `[COMPLIANCE-FULL] phase-N: PASS/FAIL — gap count: N — report: compliance-audit-[date].md`

### Continuous Monitoring (during Phase 3 execution)

Between migration steps:
- Verify logging and monitoring is active for all migrated modules
- Check that access controls are consistent across old and new code
- Verify data flows between legacy and modern modules maintain encryption
- Ensure audit trail continuity across the migration boundary

## PII Detection Checklist

When analyzing any module, check for these PII categories:

- [ ] Names (full name, first/last)
- [ ] Email addresses
- [ ] Phone numbers
- [ ] Physical addresses
- [ ] National IDs (SSN, passport, driver's license)
- [ ] Financial data (credit card, bank account, tax ID)
- [ ] Health data
- [ ] Biometric data
- [ ] IP addresses and device identifiers
- [ ] Location data
- [ ] Authentication credentials

If any PII is found, it must be:
- Encrypted at rest (GDPR Art. 32)
- Encrypted in transit (CC6.7)
- Subject to access controls (CC6.1)
- Deletable on request (GDPR Art. 17)
- Exportable on request (GDPR Art. 20)
- Logged when accessed (CC7.1)

## Role Assignments

| Task | Primary Owner | Backup |
|------|--------------|--------|
| Run compliance checks | Blue Lens | Green Anchor |
| Update compliance matrix | Green Anchor | Blue Lens |
| Remediate findings | Red Commander (assigns to appropriate agent) | — |
| Customer compliance reporting | Green Anchor (assembles), Red Commander (presents) | — |
| Compliance architecture decisions | Yellow Spark (designs), Blue Lens (validates) | — |

## Output Format

Every compliance check produces:

```markdown
# Compliance Check Report — [date] — [scope]

## Summary
- **Result:** PASS / FAIL
- **Scope:** [Phase gate / Migration step N / On-demand]
- **Controls checked:** [count]
- **Gaps found:** [count]

## Findings

### [PASS] Control-ID: Description
- Evidence: [reference to code, config, or document]

### [FAIL] Control-ID: Description
- Finding: [what's wrong]
- Risk: [impact if unaddressed]
- Remediation: [proposed fix]
- Owner: [assigned agent]
- Deadline: [by when]

## Next Actions
- [list of remediation items with owners]
```
