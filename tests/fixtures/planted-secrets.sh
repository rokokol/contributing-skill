#!/usr/bin/env bash
# check.sh plants each line where it has to be caught: in a tracked file, for
# tests/no-secrets.sh, and in the body of a draft, for contrib.sh's lint. The two gates
# keep their patterns apart, and this list is what holds them to the same shapes.
#
# Every body is GENERATED and every literal prefix is split by a format string: a
# key-shaped value committed here would be a real finding for the gate itself and for
# GitHub's push protection, and a fixture that cannot be pushed is not a fixture. What is
# committed matches nothing on its own.
#
# Needs bash 3.2 and POSIX tools only.
set -euo pipefail

usage() {
  cat <<'EOF'
planted-secrets.sh — one line per secret shape this repository refuses, for tests/check.sh.

  planted-secrets.sh print    the shapes, one per line
  planted-secrets.sh help     this text

Exit 0 printed, 2 on a usage error.
EOF
}

rep() { # rep CHAR COUNT
  printf "%${2}s" '' | tr ' ' "$1"
}

cmd_print() {
  printf -- '-----BEGIN %s PRIVATE %s-----\n' OPENSSH KEY
  printf 'ghp%s%s\n' _ "$(rep A 36)"
  printf 'gho%s%s\n' _ "$(rep A 36)"
  printf 'github%spat_%s\n' _ "$(rep A 82)"
  printf 'glpat%s%s\n' - "$(rep A 22)"
  printf 'npm%s%s\n' _ "$(rep A 36)"
  printf 'pypi%s%s\n' - "$(rep A 60)"
  printf 'hf%s%s\n' _ "$(rep A 34)"
  printf 'sk%sant-api03-%s\n' - "$(rep A 90)"
  printf 'sk%sproj-%s\n' - "$(rep A 24)"
  printf 'sk%s%s\n' - "$(rep A 48)"
  printf 'AIza%s\n' "$(rep A 35)"
  printf 'AKIA%s\n' "$(rep A 16)"
  printf 'xox%s-%s\n' b "$(rep 1 24)"
  printf 'eyJ%s.eyJ%s.%s\n' "$(rep A 20)" "$(rep A 20)" "$(rep A 20)"
}

cmd="${1:-}"
case "$cmd" in
  print) cmd_print ;;
  -h | --help | help) usage ;;
  '')
    usage >&2
    exit 2
    ;;
  *)
    printf 'planted-secrets.sh: no such subcommand: %s\n\n' "$cmd" >&2
    usage >&2
    exit 2
    ;;
esac
