# VTR-FINDINGS-001 — Sesión de trabajo 2026-09-16
## Estado al cierre de sesión

---

## Artefactos producidos hoy

| Artefacto | Estado | Ubicación |
|---|---|---|
| `VTR-FINDINGS-001.md` | v0.1.0 CONGELADO | artifact + outputs |
| `vtr-findings.schema.json` | v0.1.0 CONGELADO | outputs |
| `vtr-findings-validator.cjs` | PENDIENTE | — |
| `vtr-findings.examples.json` | PENDIENTE | — |
| `vtr-findings.adversarial.json` | PENDIENTE | — |

---

## Cadena de artefactos (orden de derivación)

```
VTR-METH-001
      ↓
VTR-FINDINGS-001.md       ← CONGELADO v0.1.0
      ↓
vtr-findings.schema.json  ← CONGELADO v0.1.0
      ↓
vtr-findings.examples.json     ← SIGUIENTE (recomendado antes del validator)
      ↓
vtr-findings-validator.cjs     ← validator relacional externo
      ↓
vtr-findings.adversarial.json  ← casos diseñados para romper invariantes
```

---

## Invariantes implementados en el schema

| ID | Invariante |
|---|---|
| I-001 | `audit_disposition=confirmed` ⇒ `epistemic_state=confirmed` |
| I-002 | `audit_disposition=confirmed` ⇒ `validation_state ∈ {validated, independently_reproduced}` |
| I-003 | `audit_disposition=confirmed` ⇒ `confirmation_basis` existe |
| I-004 | `audit_disposition=rejected` ⇒ `epistemic_state=refuted` |
| I-005 | `validation_state=falsified` ⇒ `epistemic_state=refuted` |
| I-006 | `validation_state=blocked` ⇒ `audit_disposition ≠ confirmed` |
| I-007 | `validation_state=independently_reproduced` ↛ `epistemic_state=confirmed` (no-implicación, no genera if/then) |
| I-008 | `audit_disposition=needs_validation` ⇒ `blockers` no-vacío AND `validation_plan` existe |
| I-009 | `audit_disposition=confirmed` ⇒ `conditions` no-vacía |

---

## Frontera explícita del schema

**JSON Schema resuelve:**
- Estructura, tipos, cardinalidad
- Invariantes locales I-001 a I-009

**`vtr-findings-validator.cjs` resolverá:**
- Referencias `EV-NNN` que existan realmente en `evidence`
- `criteria_satisfied` que referencien criterios declarados en `confirmation_criteria`
- Coherencia `trace[*].evidence` → `evidence[*].id`
- Invariantes relacionales entre secciones

**Fuera del scope de ambos:**
- Autenticidad de la evidencia
- Corrección del experimento
- Suficiencia de la evidencia para E3
- Si el fenómeno realmente ocurrió

Principio: *The schema validates the contract; evidence validates the claim.*

---

## Open Items diferidos (v0.2.0)

| ID | Descripción |
|---|---|
| OI-001 | Modelo de impacto — separar `security_impact`, `process_impact`, `availability_impact`, `safety_impact`, `integrity_impact` |
| OI-002 | `epistemic_history` — definición normativa y reglas de transición |
| OI-003 | Relaciones entre findings (prerequisite, compound, chain) |
| OI-004 | `confirmation_criteria` con identificadores formales (`CONF-001`) para trazabilidad relacional |
| OI-005 | Mapping a STIX 2.1 y ATT&CK for ICS |
| OI-006 | `audit_run` metadata |

### Nota sobre OI-004
Actualmente `confirmation_criteria` es un array de strings. La evolución hacia:
```json
"confirmation_criteria": [
  { "id": "CONF-001", "description": "..." }
]
```
permitiría al validator verificar la cadena completa:
`confirmation_criteria → criteria_satisfied → evidence`

Esto requiere actualizar VTR-FINDINGS-001.md antes de modificar el schema.

---

## Decisiones de diseño congeladas

1. **`REF-*` no existe en v0.1.0.** `refutation.evidence` acepta solo `EV-NNN`. REF-* diferido hasta que exista definición normativa.

2. **`independently_reproduced` no genera if/then para I-007.** JSON Schema no puede expresar no-implicaciones como restricción activa. I-007 está documentado en `$comment`.

3. **`falsification_criteria` es campo obligatorio** en el objeto base — no opcional. Un finding sin criterios de falsificación es una afirmación infalsificable.

4. **`epistemic_history` es opcional** en v0.1.0, diferido a OI-002. Su presencia añade trazabilidad; su ausencia no invalida el finding.

5. **`confirmation_basis.method` describe cómo se obtuvo la evidencia**, no determina suficiencia para E3. La suficiencia la determinan `confirmation_criteria`.

---

## Próxima sesión — orden recomendado

### Paso 1: `vtr-findings.examples.json`
Casos válidos que cubran las combinaciones principales:
- `open` / `observed`
- `needs_validation` con blocker explícito
- `confirmed` con `controlled_experiment`
- `confirmed` con `independent_reproduction`
- `confirmed` donde `independently_reproduced` pero con criterio adicional pendiente (demuestra I-007)
- `rejected` / `refuted`

### Paso 2: `vtr-findings-validator.cjs`
Escribir contra los ejemplos del paso 1.
Verificaciones relacionales:
```
- EV-NNN en trace.evidence existe en evidence[]
- EV-NNN en confirmation_basis.evidence existe en evidence[]
- EV-NNN en refutation.evidence existe en evidence[]
- criteria_satisfied strings presentes en confirmation_criteria strings (v0.1.0)
```

### Paso 3: `vtr-findings.adversarial.json`
Casos diseñados para disparar cada invariante:
- `confirmed` + `pending` → debe fallar I-002
- `confirmed` + `blocked` → debe fallar I-006
- `confirmed` sin `conditions` → debe fallar I-009
- `confirmed` sin `confirmation_basis` → debe fallar I-003
- `rejected` + `confirmed` epistemic → debe fallar I-004
- `falsified` + `probable` epistemic → debe fallar I-005
- `needs_validation` sin `blockers` → debe fallar I-008
- `refuted` sin `refutation` → debe fallar estructura
- `independently_reproduced` + `open` → debe ser VÁLIDO (demuestra I-007)

---

## Contexto de origen

Este contrato surgió del análisis de `cloudflare/security-audit-skill` (7.1k stars),
específicamente de su `report-schema.json` y `SKILL.md`.

La diferencia arquitectónica respecto a Cloudflare:

```
Cloudflare:    evidence → verdict
VTR:           evidence → validation → epistemic_state → audit_disposition
```

La separación adicional de VTR no es una afirmación de superioridad;
es una consecuencia de formalizar explícitamente la distinción entre
evidencia, validación, conocimiento epistémico y decisión de auditoría.

Contexto de estándares existentes:
- STIX 2.1: intercambio estructurado de CTI (no reemplazado por VTR-FINDINGS-001)
- MITRE ATT&CK for ICS: taxonomía de técnicas (no reemplazado)
- VTR-FINDINGS-001: trazabilidad epistemológica del finding y su proceso de validación

Formulación defendible:
> "VTR-FINDINGS-001 propone un contrato machine-readable orientado a representar
> estados epistemológicos, evidencia, condiciones de ejecución, validación y
> falsificación de hallazgos en entornos OT/ICS, complementando estándares
> existentes de intercambio y clasificación como STIX/ATT&CK."

---

*Generado al cierre de sesión 2026-09-16 — Vector Telemetry Research*
