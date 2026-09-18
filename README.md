# VTR-FINDINGS-001

**Structured Evidence and Validation Contract for OT/ICS Security Findings**

| Field | Value |
|---|---|
| Identifier | VTR-FINDINGS-001 |
| Version | 0.1.0 |
| Status | DRAFT — Proposed |
| Commit | 52d127e |
| Date | 2026-09-17 |

---

## Overview

VTR-FINDINGS-001 defines a structured contract for representing OT/ICS security findings that preserves the full epistemological chain:

- claim
- evidence
- inference
- conditions
- validation
- confirmation criteria
- falsification criteria
- epistemic state
- audit disposition

The schema validates the contract; evidence validates the claim.

**A structurally valid finding is not, by itself, a validated security finding.**

---

## Scope

This specification addresses epistemic and audit traceability of security findings in OT/ICS environments.

It is not:

- a vulnerability taxonomy
- a replacement for STIX 2.1
- a replacement for MITRE ATT&CK for ICS
- a mechanism for establishing factual truth
- a substitute for independent validation

---

## Repository Structure

    vtr-findings/
    ├── findings/
    │   └── VTR-FINDINGS-001.md                              — normative specification
    ├── schema/
    │   └── vtr-findings.schema.json                         — machine-readable contract
    ├── validator/
    │   └── src/main.rs                                      — structural and relational validator (Rust)
    └── adversarial/
        ├── VTR-FINDINGS-001-ADVERSARIAL-PROTOCOL-REVIEW.md  — pre-execution review notes
        ├── run_adversarial.sh                               — execution harness
        ├── vtr-findings.adversarial.json                    — execution record v0.2.0
        ├── cases/                                           — adversarial fixtures
        └── results/                                         — raw validator output

---

## Artifact Chain

    VTR-METH-001
          ↓
    VTR-FINDINGS-001.md           ← normative specification
          ↓
    vtr-findings.schema.json      ← machine-readable implementation
          ↓
    validator/src/main.rs         ← structural and relational enforcement
          ↓
    adversarial/cases/            ← falsification test cases
          ↓
    adversarial/results/          ← raw validator output
          ↓
    vtr-findings.adversarial.json ← interpreted execution record

The `.md` specification takes precedence over the `.json` schema in cases of conflict.

---

## Semantic Invariants

The following invariants are normative and enforced by the validator:

| ID | Invariant |
|---|---|
| I-001 | `audit_disposition = confirmed` ⇒ `epistemic_state = confirmed` |
| I-002 | `audit_disposition = confirmed` ⇒ `validation_state ∈ {validated, independently_reproduced}` |
| I-003 | `audit_disposition = confirmed` ⇒ `confirmation_basis` exists and is non-empty |
| I-004 | `audit_disposition = rejected` ⇒ `epistemic_state = refuted` |
| I-005 | `validation_state = falsified` ⇒ `epistemic_state = refuted` |
| I-006 | `validation_state = blocked` ⇒ `audit_disposition ≠ confirmed` |
| I-007 | `validation_state = independently_reproduced` does not imply `epistemic_state = confirmed` (non-implication) |
| I-008 | `audit_disposition = needs_validation` ⇒ `blockers` exists AND `validation_plan` exists |
| I-009 | `audit_disposition = confirmed` ⇒ `conditions` exists AND non-empty |

---

## Adversarial Testing

The repository contains an adversarial execution suite designed to test structural and relational constraints of the contract and validator.

Execution record at commit `826b119` (harness pinned at `52d127e`):

| Case | Phase | Expected | Observed | Classification |
|---|---|---|---|---|
| BASE-VALID | A | ACCEPT | ACCEPT | EXPECTED_ACCEPTANCE |
| I-001-violation | A | REJECT | REJECT | EXPECTED_REJECTION |
| I-007-control | A | ACCEPT | ACCEPT | EXPECTED_ACCEPTANCE |
| B-001-trace-missing-evidence | B | REJECT | REJECT | EXPECTED_REJECTION |
| B-002-trace-valid-evidence | B | ACCEPT | ACCEPT | EXPECTED_ACCEPTANCE |
| C-001-semantic-boundary | C | ACCEPT | ACCEPT | EXPECTED_ACCEPTANCE |

**6/6 expected outcomes. 0 not executed.**

The adversarial suite does not establish the factual validity of the underlying security findings.

### What the execution demonstrates

- **Phase A**: Normative invariants enforced (I-001); non-implication preserved (I-007).
- **Phase B**: Broken `trace → evidence` references detected (B-001); no false positives on valid references (B-002).
- **Family C**: Schema-valid does not imply claim-confirmed (C-001, per §12).

---

## Reproducibility

Validator: Rust — build with `cargo build` in `validator/`

Execution:

    git checkout 826b119
    cargo build --manifest-path validator/Cargo.toml
    bash adversarial/run_adversarial.sh

Raw output: `adversarial/results/`

Interpreted record: `adversarial/vtr-findings.adversarial.json`

---

## Schema Boundary

JSON Schema enforces structural constraints and declared semantic invariants
expressible in the schema language.

Factual truth, evidence authenticity, experimental correctness, and adequacy
of evidence to satisfy confirmation_criteria MUST NOT be inferred from
schema validation alone.

| Responsibility | Owner |
|---|---|
| Structural validity | `vtr-findings.schema.json` |
| Semantic invariants (I-001 – I-009) | `vtr-findings.schema.json` |
| Relational integrity (trace → evidence) | `validator/src/main.rs` |
| Factual validity of claims | Audit process and independent reviewer |
| Adequacy of evidence for E3 | VTR-METH-001 confirmation process |

---

## Open Items (v0.1.0)

Deferred to v0.2.0:

- OI-001: `impact` model
- OI-002: `fingerprint` stability rules
- OI-003: Multi-finding relationships
- OI-004: `confirmation_criteria` formal definition
- OI-005: Mapping to STIX 2.1 and ATT&CK for ICS
- OI-006: `audit_run` metadata structure

Phase B relational validators not yet implemented:

- `confirmation_basis.evidence` → `evidence[].id`
- `refutation.evidence` → `evidence[].id`
- Multi-finding relational constraints (OI-003)

---

## Limitations

- v0.1.0 is a DRAFT. The specification has not been independently reviewed.
- The adversarial suite covers a subset of the declared invariants.
- The validator is a development build (`target/debug`). No production hardening has been applied.
- VTR-METH-001 (parent methodology) is not published in this repository.

---

## Citation

DOI: [10.5281/zenodo.22821614](https://doi.org/10.5281/zenodo.22821614)

---

## License

MIT License — see LICENSE file.

---

*VTR-FINDINGS-001 v0.1.0 — Vector Telemetry Research — 2026-09-17*

---

## Related Research

- **VTR Architecture — State and Traceability Analysis (2026-09-17)**  
  Informational context document describing the emerging traceability
  relationship between VTR-METH-001, VTR-RES-004, and VTR-FINDINGS-001,
  including the provenance chain from specification through implementation,
  adversarial execution, versioned artifact, and archival record.  
  See: [vtr-research-future/VTR-ARCHITECTURE-2026-09-17.md](https://github.com/LuisCastellanos-dev/vtr-research-future/blob/main/VTR-ARCHITECTURE-2026-09-17.md)
