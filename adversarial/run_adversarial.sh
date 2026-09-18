#!/usr/bin/env bash
# VTR-FINDINGS-001 — Adversarial Test Harness
# Protocol: VTR-FINDINGS-001-ADVERSARIAL-PROTOCOL.md (FROZEN)
# Expected commit: 4ab4e53
# Usage: ./run_adversarial.sh [--phase A|B|C|all]
set -euo pipefail

EXPECTED_COMMIT="826b119"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEMA="$ROOT/schema/vtr-findings.schema.json"
VALIDATOR="$ROOT/validator/target/debug/vtr_findings_validator"
CASES_DIR="$(dirname "${BASH_SOURCE[0]}")/cases"
RESULTS_DIR="$(dirname "${BASH_SOURCE[0]}")/results"
PHASE_FILTER="${1:-all}"
if [[ "${1:-}" == "--phase" ]]; then
    PHASE_FILTER="${2:-all}"
fi

# ── Commit verification ────────────────────────────────────────────────────────
verify_commit() {
    if ! git -C "$ROOT" rev-parse --git-dir &>/dev/null; then
        echo "WARNING: not a git repository — commit verification skipped" >&2
        return
    fi
    local actual
    actual="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    if [[ "$actual" != "$EXPECTED_COMMIT" ]]; then
        echo "ERROR: expected commit $EXPECTED_COMMIT, found $actual" >&2
        echo "       The validator must be executed at the pinned commit." >&2
        echo "       Run: git checkout $EXPECTED_COMMIT" >&2
        exit 3
    fi
    echo "Commit verified: $actual"
}

# ── Preflight checks ───────────────────────────────────────────────────────────
preflight() {
    verify_commit

    if [[ ! -x "$VALIDATOR" ]]; then
        echo "ERROR: validator not built at $VALIDATOR" >&2
        echo "       Run: cd validator && cargo build" >&2
        exit 2
    fi

    if [[ ! -f "$SCHEMA" ]]; then
        echo "ERROR: schema not found at $SCHEMA" >&2
        exit 2
    fi

    if [[ ! -d "$CASES_DIR" ]]; then
        echo "ERROR: cases directory not found at $CASES_DIR" >&2
        exit 2
    fi

    mkdir -p "$RESULTS_DIR"
}

# ── Phase filter ───────────────────────────────────────────────────────────────
# Phase B cases (B-*.json) are executable at 826b119 — relational validator implemented.
phase_of() {
    local name="$1"
    if [[ "$name" == B-* ]]; then echo "B"
    elif [[ "$name" == C-* ]]; then echo "C"
    else echo "A"
    fi
}

should_run() {
    local phase="$1"
    [[ "$PHASE_FILTER" == "all" ]] || [[ "$PHASE_FILTER" == "$phase" ]]
}

# ── Execution ──────────────────────────────────────────────────────────────────
run_cases() {
    local total=0 accepted=0 rejected=0 skipped=0

    echo "========================================"
    echo "VTR-FINDINGS-001 Adversarial Harness"
    echo "Commit:  $EXPECTED_COMMIT"
    echo "Schema:  $SCHEMA"
    echo "Cases:   $CASES_DIR"
    echo "Phase:   $PHASE_FILTER"
    echo "========================================"
    echo

    for case_file in "$CASES_DIR"/*.json; do
        [[ -e "$case_file" ]] || continue

        name="$(basename "$case_file" .json)"
        phase="$(phase_of "$name")"
        output="$RESULTS_DIR/${name}.txt"

        if ! should_run "$phase"; then
            continue
        fi

        echo "----------------------------------------"
        echo "CASE:  $name"
        echo "PHASE: $phase"

        # Phase B: now executable — relational validator implemented

        # Phase A and C: execute against validator
        if "$VALIDATOR" "$SCHEMA" "$case_file" >"$output" 2>&1; then
            echo "Observed behavior: ACCEPT"
            accepted=$((accepted + 1))
        else
            echo "Observed behavior: REJECT"
            rejected=$((rejected + 1))
        fi

        cat "$output"
        total=$((total + 1))
        echo
    done

    echo "========================================"
    echo "EXECUTION SUMMARY"
    echo "========================================"
    echo "Total:        $total"
    echo "Accepted:     $accepted"
    echo "Rejected:     $rejected"
    echo "Not executed: $skipped"
    echo
    echo "Raw validator output: $RESULTS_DIR/"
    echo
    echo "Next step: executor interprets results and populates"
    echo "           vtr-findings.adversarial.json"
}

preflight
run_cases
