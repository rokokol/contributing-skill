#!/usr/bin/env bash
# Refuse to ship a secret that slipped past .gitignore.
#
# .gitignore keeps a file out; this keeps a value out of a file that belongs
# here. Both are needed: the leak that matters is a token pasted into a config
# default, a doc or a fixture, not a stray file.
#
# Taken from the ci skill's templates/no-secrets.sh and made this repository's
# own: the last section knows what *its* private data looks like. tests/check.sh
# falsifies it on every run, planting each shape tests/fixtures/planted-secrets.sh
# prints and a tracked user/ file, and requiring red on every one — a gate that
# has only ever printed "clean" may simply be matching nothing.
#
# Every pattern is written so it cannot match its own source line — a literal
# prefix is always followed by a bracket expression, which the pattern text
# itself does not satisfy. Keep that property when adding one, or the gate
# reddens the repository on the commit that introduces it.
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
report() {
  printf 'secret-gate: %s\n' "$1" >&2
  fail=1
}

# Tracked files only — an untracked scratch file is not about to be pushed.
# -I skips binaries, so a matching byte sequence in an image is not a finding
mapfile -t tracked < <(git ls-files)
[[ ${#tracked[@]} -gt 0 ]] || {
  echo "secret-gate: nothing tracked yet" >&2
  exit 0
}

# --no-index makes check-ignore inspect tracked paths too; without it, Git skips
# the exact git add -f leak this gate must catch. NUL delimiters preserve every path
mapfile -d '' ignored < <(git ls-files -z | git check-ignore --no-index -z --stdin || true)
for path in "${ignored[@]}"; do
  report "tracked path is covered by .gitignore: $path"
done

scan() { # scan DESCRIPTION ERE
  if git grep -nIE "$2" -- "${tracked[@]}" >&2; then
    report "$1"
  fi
}

# Any PEM private key, whatever the algorithm label says
scan "private key material" \
  'BEGIN ([A-Z]+ )*PRIVATE KEY'

# Forges and package registries — the tokens that let someone push as you
scan "forge or registry token" \
  '(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{60,}|glpat-[A-Za-z0-9_-]{20,}|npm_[A-Za-z0-9]{36}|pypi-[A-Za-z0-9_-]{50,}|hf_[A-Za-z0-9]{30,}|dckr_pat_[A-Za-z0-9_-]{20,})'

# Model providers. Anthropic and OpenAI both start sk-, and both are billed per
# token by whoever holds the string
scan "model-provider API key" \
  '(sk-ant-[a-z0-9]+-[A-Za-z0-9_-]{80,}|sk-proj-[A-Za-z0-9_-]{20,}|sk-svcacct-[A-Za-z0-9_-]{20,}|sk-or-v1-[0-9a-f]{60,}|sk-[A-Za-z0-9]{48}|AIza[A-Za-z0-9_-]{35}|gsk_[A-Za-z0-9]{50,}|r8_[A-Za-z0-9]{35,})'

# Cloud and SaaS. An AWS key id is worth catching even alone: it names the
# account, and the matching secret is usually one line below
scan "cloud or SaaS credential" \
  '((AKIA|ASIA|ABIA|ACCA)[0-9A-Z]{16}|GOCSPX-[A-Za-z0-9_-]{28}|xox[abposr]-[0-9A-Za-z-]{10,}|hooks\.slack\.com/services/[A-Za-z0-9/]{20,}|(sk|rk)_live_[0-9A-Za-z]{20,}|SG\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{40,}|key-[0-9a-f]{32}|AC[0-9a-f]{32}|dop_v1_[0-9a-f]{60,}|dp\.pt\.[A-Za-z0-9]{40,}|lin_api_[A-Za-z0-9]{40,}|[0-9]{8,10}:AA[A-Za-z0-9_-]{33})'

# A signed token pasted whole — a Supabase service key, a session bearer, an
# identity assertion. Three base64url segments, the first two decoding to JSON
scan "JWT-shaped token" \
  'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'

# A real value assigned to a secret-shaped key, in either an assignment or a
# mapping — the catch-all for providers with no distinctive prefix. The
# allow-list is what keeps documented examples legal, and it is also the line
# to re-read when a real leak is reported as clean
if git grep -nIE '^[[:space:]]*"?(token|password|passwd|secret|api_key|apikey|auth_key|authkey|access_key|private_key|client_secret)"?[[:space:]]*[=:][[:space:]]*"?[^"[:space:]]{12,}' \
  -- "${tracked[@]}" | grep -vE '(replace-me|example|CHANGEME|changeme|placeholder|your-|test-|dummy|xxx|\$\{|\{\{|<[a-z-]+>)' >&2; then
  report "literal secret assignment"
fi

# This repository's own secrets are not a token shape but two directories: the
# user's overlay — standing permissions and private notes on other people's
# projects — and contrib.sh's state, which holds every draft and every sent
# payload. .gitignore keeps them out, and a git add -f is caught above; this
# catches a copy that .gitignore was edited to let through
if git ls-files | grep -qE '^(user|state)/'; then
  report "a file under user/ or state/ is tracked; those hold the private overlay and the drafts"
fi

[[ $fail -eq 0 ]] && echo "secret-gate: clean"
exit "$fail"
