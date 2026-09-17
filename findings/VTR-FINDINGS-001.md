# VTR-FINDINGS-001
## Machine-Readable Evidence and Finding Contract for OT/ICS Security

| Field | Value |
|---|---|
| Identifier | VTR-FINDINGS-001 |
| Version | 0.1.0 |
| Status | DRAFT |
| Normative status | Proposed |
| Parent methodology | VTR-METH-001 |
| Date | 2026-09-16 |

---

## 1. Purpose

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

This contract is not a vulnerability taxonomy and does not replace existing standards for CTI exchange or attack classification (STIX 2.1, MITRE ATT&CK for ICS). Its scope is the epistemological traceability of a finding and its validation process: making machine-checkable what a finding claims, what evidence supports it, under what conditions, and how that claim may be confirmed or falsified.

---

## 2. Normative Principle

> **The schema validates the contract; evidence validates the claim.**

> **A structurally valid finding is not, by itself, a validated security finding.**

These two statements define the boundary between syntactic and factual validity. Schema validation determines whether a finding satisfies the structural and semantic constraints declared in this specification. It does not determine whether the finding is true.

---

## 3. Epistemic Model — The Evidence Helix

VTR-METH-001 defines the Evidence Helix as four epistemic states with a distinct falsification branch:

```
E0  OBSERVED
        ↓
E1  CANDIDATE
        ↓
E2  PROBABLE
        ↓
E3  CONFIRMED

        ↘
         REFUTED
```

**Normative clarification:** `refuted` is not an additional level in the Evidence Helix. It is a falsification branch reachable from any existing epistemic state. The sequence is not linear from `observed` to `refuted`.

**On epistemic history:** When a finding transitions to `refuted`, the prior epistemic state is lost from `epistemic_state` alone. The epistemological trajectory is evidence. Implementations SHOULD preserve it via an `epistemic_history` field:

```json
"epistemic_history": [
  { "state": "observed",  "timestamp": "...", "basis": ["EV-001"] },
  { "state": "candidate", "timestamp": "...", "basis": ["EV-003"] },
  { "state": "refuted",   "timestamp": "...", "basis": ["REF-001"] }
]
```

This field is optional in v0.1.0 and deferred to OI-002 for normative definition. Its absence does not invalidate a finding; its presence adds lifecycle traceability.

Transition between states requires satisfaction of evidence preconditions defined in VTR-METH-001, not completion of a validation activity alone. A validation activity may produce evidence that satisfies preconditions; it does not automatically advance epistemic state.

---

## 4. Validation Model

Six validation states are defined:

| State | Meaning |
|---|---|
| `pending` | No validation activity has begun. |
| `in_progress` | A validation procedure is currently being executed. |
| `blocked` | Validation cannot proceed; a specific blocker exists. |
| `validated` | The defined validation procedure was executed and produced an interpretable result. |
| `independently_reproduced` | The phenomenon was reproduced by an independent actor under the specified conditions. |
| `falsified` | The claim was refuted by the defined falsification criterion. |

**Normative clarifications:**

- `validated` ≠ `confirmed`. Completion of a validation procedure provides evidence; whether that evidence satisfies `confirmation_criteria` determines epistemic state.
- `independently_reproduced` ≠ `confirmed`. Independent reproduction of a phenomenon does not automatically confirm the complete claim.
- `independently_reproduced` records a validation result that includes independent reproduction under specified conditions. It is not an epistemic level and does not, by itself, determine epistemic state.

---

## 5. Audit Disposition

Audit disposition represents the operational state of a finding within an audit workflow. It is distinct from epistemic state.

| Disposition | Normative meaning |
|---|---|
| `open` | Investigation continues; no blocking condition has been declared. |
| `needs_validation` | A specific blocker prevents completion; a `validation_plan` exists for resolution. |
| `confirmed` | The finding satisfies E3 and all mandatory confirmation conditions. |
| `rejected` | The claim was falsified; the finding is closed as refuted. |

**Normative clarifications:**

- `needs_validation` ≠ `probable`. A finding at any epistemic state may require validation.
- `rejected` requires explicit falsification evidence, not absence of sufficient evidence.
- `confirmed` ≠ "the auditor found sufficient evidence." It requires satisfaction of declared `confirmation_criteria`.

---

## 6. Confirmation Basis

When `audit_disposition = confirmed`, a `confirmation_basis` record is mandatory. This is not an escape hatch for declaring confirmation without validation; it is the formal record of how E3 was satisfied.

```
confirmation_basis
├── method             # how confirmation evidence was obtained
├── criteria_satisfied # list of confirmation_criteria identifiers met
├── evidence           # evidence identifiers supporting confirmation
├── limitations        # explicit scope limitations of this confirmation
└── independent_reproduction
    ├── status         # performed | not_performed
    └── reason         # required when status = not_performed
```

**Confirmation methods:**

| Method | Description |
|---|---|
| `independent_reproduction` | Phenomenon reproduced by an independent actor. |
| `controlled_experiment` | Controlled test in a non-operational environment. |
| `operational_observation` | Direct observation in an operational environment. |
| `deterministic_static_verification` | Static analysis with deterministic, bounded result. |
| `formal_verification` | Formal proof or model checking. |
| `cross_implementation_validation` | Consistent result across multiple independent implementations. |
| `other` | Requires explicit justification in `method_justification`. |

**Normative constraint:** The method describes how evidence was obtained. Sufficiency for E3 is determined by `confirmation_criteria`, not by the method alone.

---

## 7. OT/ICS Evidence Taxonomy

OT/ICS findings do not reduce to `file:line` references. The following evidence types are defined:

| Type | Description |
|---|---|
| `packet_capture` | Network traffic capture (e.g., PCAP) |
| `protocol_trace` | Decoded protocol-level trace |
| `engineering_station_log` | Log from an engineering workstation |
| `controller_configuration` | Exported PLC/RTU/DCS configuration |
| `plc_program` | PLC program file |
| `ladder_logic` | Ladder diagram representation |
| `function_block` | Function block diagram |
| `structured_text` | Structured text program |
| `firmware_reference` | Firmware documentation or binary |
| `configuration_snapshot` | Point-in-time configuration state |
| `device_log` | Log from a field device |
| `historian_record` | Process historian data |
| `physical_observation` | Directly observed physical state or effect |
| `test_record` | Record of a controlled test procedure |
| `source_code` | Software source code |
| `binary_analysis` | Binary or firmware analysis artifact |
| `documentation` | Vendor manual, specification, or standard |
| `other` | Requires `type_description` field |

Each evidence item declares:

```
evidence item
├── id          # stable identifier within this finding (e.g., EV-001)
├── type        # from taxonomy above
├── artifact    # artifact name or reference
├── location    # type-specific locator (frame number, log line, register address, etc.)
└── description # what this evidence demonstrates
```

---

## 8. OT/ICS Trace Model

Software-centric trace models (`entrypoint → propagation → sink`) do not adequately represent OT/ICS attack paths. VTR-FINDINGS-001 uses a topology-based trace model:

```
asset
  ↓
interface
  ↓
protocol
  ↓
function / operation
  ↓
state transition
  ↓
security / control boundary
  ↓
observed effect
```

Each trace step declares:

```
trace step
├── kind         # asset | interface | protocol | function |
│                # state_transition | boundary | observed_effect
├── identifier   # stable identifier for the component or concept
├── description  # what occurs at this step
└── evidence     # list of evidence item ids supporting this step
```

This model supports PLC, RTU, HMI, historian, engineering workstation, and network device findings without requiring a source code reference.

---

## 9. Conditions

Claims in OT/ICS environments are almost always condition-dependent. VTR-FINDINGS-001 distinguishes:

> **"X causes Y"** is methodologically weaker than **"X causes Y under conditions C."**

The schema favors the second form. Conditions are **required** for `confirmed` findings (see I-009) and recommended for all others.

Condition kinds:

| Kind | Description |
|---|---|
| `platform` | Hardware or OS platform |
| `software_version` | Software or firmware version |
| `firmware_version` | Firmware version of a field device |
| `configuration` | Specific configuration state |
| `network_topology` | Network or zone layout |
| `protocol_parameters` | Protocol-level configuration |
| `device_state` | Operational mode or process state |
| `precondition` | Required prior state or action |
| `test_constraint` | Constraint applicable only in test/non-operational context |

---

## 10. Falsification

Falsification is a first-class component of VTR-FINDINGS-001. Every finding MUST declare `falsification_criteria` — explicit conditions under which the claim would be considered false. This is a structural requirement of the base finding object, not an optional field.

A finding without `falsification_criteria` cannot be distinguished from an unfalsifiable assertion. A system that records how a claim may be confirmed but not what would refute it violates the core principle of VTR-METH-001. `confirmation_criteria` and `falsification_criteria` are therefore both mandatory at the claim level.

When a finding is refuted, a `refutation` record is mandatory:

```
refutation
├── criterion      # which falsification_criterion was triggered
├── evidence       # evidence items supporting refutation
├── observed_result  # what was actually observed
└── reason         # why this refutes the claim
```

**Normative constraint:** Falsification criteria and confirmation criteria must not disappear during finding lifecycle transitions. A refuted finding retains its full claim, evidence, and refutation record.

---

## 11. Semantic Invariants

The following invariants are normative. Implementations of `vtr-findings.schema.json` MUST enforce them:

| ID | Invariant |
|---|---|
| I-001 | `audit_disposition = confirmed` ⇒ `epistemic_state = confirmed` |
| I-002 | `audit_disposition = confirmed` ⇒ `validation_state ∈ {validated, independently_reproduced}` |
| I-003 | `audit_disposition = confirmed` ⇒ `confirmation_basis` exists and is non-empty |
| I-004 | `audit_disposition = rejected` ⇒ `epistemic_state = refuted` |
| I-005 | `validation_state = falsified` ⇒ `epistemic_state = refuted` |
| I-006 | `validation_state = blocked` ⇒ `audit_disposition ≠ confirmed` |
| I-007 | `validation_state = independently_reproduced` ↛ `epistemic_state = confirmed` (non-implication) |
| I-008 | `audit_disposition = needs_validation` ⇒ `blockers` exists (non-empty) AND `validation_plan` exists |
| I-009 | `audit_disposition = confirmed` ⇒ `conditions` exists AND `conditions` is non-empty |

**On I-007:** This invariant documents a non-implication. `validation_state = independently_reproduced` does not imply `epistemic_state = confirmed`. Independent reproduction provides evidence toward E3; E3 additionally requires satisfaction of the declared `confirmation_criteria`. Whether independent reproduction is necessary, sufficient, or neither for a given claim depends on those criteria, not on the method itself.

---

## 12. Schema Boundary

```
JSON Schema MUST enforce structural constraints and declared semantic
invariants that are expressible in the schema language.

Factual truth, evidence authenticity, experimental correctness, and
adequacy of evidence to satisfy confirmation_criteria MUST NOT be
inferred from schema validation alone.
```

This boundary defines the division of responsibility:

| Responsibility | Owner |
|---|---|
| Structural validity | `vtr-findings.schema.json` |
| Semantic invariants (I-001 – I-009) | `vtr-findings.schema.json` |
| Factual validity of claims | Audit process and independent reviewer |
| Adequacy of evidence for E3 | VTR-METH-001 confirmation process |

---

## 13. Artifact Chain

```
VTR-METH-001
      ↓
VTR-FINDINGS-001.md       ← this document (normative specification)
      ↓
vtr-findings.schema.json  ← machine-readable implementation
      ↓
vtr-findings-validator.cjs ← structural and invariant enforcement
      ↓
vtr-findings.examples.json ← reference instances
      ↓
vtr-findings.adversarial.json ← falsification test cases
```

Each artifact in the chain is derived from the one above it. The `.md` specification takes precedence over the `.json` schema in cases of conflict. The schema is an implementation of the specification, not the specification itself.

---

## 14. Open Items (v0.1.0)

The following items are deferred to v0.2.0:

- OI-001: `impact` model — separation of `security_impact`, `process_impact`, `availability_impact`, `safety_impact`, `integrity_impact`
- OI-002: `fingerprint` stability rules across lifecycle transitions
- OI-003: Multi-finding relationships (prerequisite, compound, chain)
- OI-004: `confirmation_criteria` formal definition and identifier scheme
- OI-005: Mapping to STIX 2.1 objects and ATT&CK for ICS techniques
- OI-006: `audit_run` metadata structure

---

*VTR-FINDINGS-001 v0.1.0 — DRAFT — Vector Telemetry Research*
