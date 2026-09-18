# VTR-FINDINGS-001 — Adversarial Protocol: Pre-Execution Review Notes
**Version:** 0.1.0  
**Date:** 2026-09-17  
**Applies to:** `VTR-FINDINGS-001-ADVERSARIAL-PROTOCOL.md` (FROZEN)  
**Status:** INFORMATIONAL — do not incorporate into the frozen protocol

These notes document three inconsistencies identified before execution. They do not require modifying the protocol. They exist so the executor interprets results correctly and does not misclassify legitimate findings.

---

## N-001 — Phase B cases cannot produce an observed behavior

**The inconsistency:**

The protocol output format requires:

```
Observed behavior: REJECT | ACCEPT (what the validator actually did)
```

But Phase B specifies:

```
Tool: not yet implemented in main.rs
```

A Phase B case can be designed and its expected behavior determined. It cannot be honestly executed against the current validator.

**Operational rule for the executor:**

- Phase B cases: design them, record `Expected behavior`, set `Classification: OUT_OF_SCOPE`
- In `Notes`, state explicitly: *"Phase B validator not implemented at 4ab4e53 — observed behavior not available"*
- Do not write `"observed_behavior": "ACCEPT"` for Phase B as if execution occurred
- The gap itself is a finding: it specifies what the relational validator must implement

**What this does not change:** Phase A execution is unaffected. The format is correct for Phase A.

---

## N-002 — I-009 may differ between the protocol and VTR-FINDINGS-001.md

**The inconsistency:**

The protocol defines:

```
I-009 | audit_disposition = confirmed requires non-empty confirmation_criteria
```

The original specification formulated I-009 as:

```
confirmed ⇒ conditions exists/non-empty
```

These may refer to different fields (`confirmation_criteria` vs `conditions`). If VTR-FINDINGS-001.md still carries the original definition, the protocol is testing a different property under the same identifier.

**Operational rule for the executor:**

- Before designing the I-009 case, read VTR-FINDINGS-001.md and compare the I-009 definition there against the protocol table
- If they differ: design the case against the protocol definition (it is the frozen artifact), record the divergence in `Notes`, and classify as `SPECIFICATION_AMBIGUITY`
- Do not resolve the divergence during execution — surface it as a result

**Why this is not fixed in the protocol:** The adversarial is designed to reveal exactly this kind of documentary divergence. Correcting I-009 before execution would hide a real finding.

---

## N-003 — Family C results must not contaminate Phase A counts

**The inconsistency:**

Family C (semantic attacks) produces cases that are schema-valid by design. A case that passes is `EXPECTED_ACCEPTANCE`. If counted alongside Phase A rejections, it inflates the apparent failure rate.

**The architectural boundary this demonstrates:**

```
                    VTR-FINDINGS-001
                           │
             ┌─────────────┴─────────────┐
             │                           │
       Structural layer             Epistemic layer
             │                           │
       JSON Schema                  Audit process
       invariants                   evidence
       legal states                 validation
             │                       reviewer
             └──────────┬──────────────┘
                        │
                 factual adequacy
```

The validator establishes: *"this satisfies the structural contract."*  
It does not establish: *"the claim is true."*

This is not a deficiency. It is the correct scope of the schema.

**Operational rule for the executor:**

- In the summary, report Phase A, Phase B, and Family C counts separately
- A Family C `EXPECTED_ACCEPTANCE` is a **positive result** — it demonstrates an architectural boundary, not a failure
- Do not classify `EXPECTED_ACCEPTANCE` as `IMPLEMENTATION_FAILURE` because the case was designed to be adversarial

---

## Methodological note — I-007 as negative control

I-007 tests both directions of the adversarial simultaneously:

```
Reject illegal         Accept legal
      │                     │
enforcement of         absence of
  invariant            over-restriction
```

The case:

```json
"epistemic_state": "candidate",
"validation_state": "independently_reproduced"
```

must be accepted. If the validator rejects it, the implementation has introduced a normative inference that the specification does not authorize:

```
independently_reproduced → confirmed  [NOT in VTR-FINDINGS-001.md]
```

That would be an `IMPLEMENTATION_FAILURE`, not an `EXPECTED_REJECTION`.

This makes I-007 the most epistemologically precise test in the protocol.

---

## N-004 — I-008: `OR` vs `AND` in the requires clause

**The inconsistency:**

The protocol table defines:

```
I-008 | audit_disposition = needs_validation requires blockers OR validation_plan
```

The normative specification established for I-008 was:

```
needs_validation ⇒ blockers non-empty AND validation_plan
```

This produces two materially different cases:

```
Case A:
  blockers = [...]
  validation_plan = absent

Case B:
  blockers = absent
  validation_plan = {...}
```

Under `OR`: both are legally sufficient — validator must accept them.  
Under `AND`: both are insufficient — validator must reject them.

**Why this matters:**

The `OR` formulation allows a finding to be `needs_validation` with no documented plan for validation (only blockers) or with no documented blockers (only a plan). The `AND` formulation requires both to be present simultaneously. These are meaningfully different epistemic requirements.

**Operational rule for the executor:**

- Before designing I-008 cases, read VTR-FINDINGS-001.md and identify the normative definition of I-008
- Design cases for both Case A and Case B above
- If the normative definition is `AND` but the schema enforces `OR` (or vice versa): record both formulations verbatim in `Notes`, classify as `SPECIFICATION_AMBIGUITY`
- Do not resolve the divergence during execution — record what the validator actually does and what the specification actually says
- The adversarial is designed to surface this class of inter-layer divergence; resolving it before execution would destroy the finding

**Additional observation:**

N-004 demonstrates that the adversarial protocol is already producing a result before execution begins: it found a divergence between two normative layers. This is consistent with the protocol's central question — the process can reveal gaps not only in the implementation but between specification documents themselves.

---

## Provenance chain

The adversarial results must be interpretable against a specific implementation. The chain is:

```
VTR-FINDINGS-001.md
        │
        ▼
vtr-findings.schema.json
        │
        ▼
validator @ commit 4ab4e53
        │
        ▼
VTR-FINDINGS-001-ADVERSARIAL-PROTOCOL.md (FROZEN)
        │
        ▼
Adversarial Cases (vtr-findings.adversarial.json)
        │
        ▼
Observed Results
```

Any result that cannot be traced to a specific node in this chain is not a valid finding.
