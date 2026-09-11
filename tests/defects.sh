#!/usr/bin/env bash
# The defect list for this repository, read by the tests skill's harness:
#
#   t.sh falsify -- ./tests/check.sh behaviour
#
# Each entry breaks one guard of contrib.sh and requires the behaviour suite to notice. The
# CONSEQUENCE is what goes wrong in the world when that guard stops working; when an entry
# survives, that sentence is the report.
#
#   defect NAME FILE FIND REPLACE CONSEQUENCE [expect survived REASON | expect caught FRAGMENT]
#
# A FIND or REPLACE that holds a $ or a quote is a quoted heredoc: it keeps the line exactly
# as contrib.sh spells it, with no escaping to get wrong

# The gate itself: what is published is exactly what was approved, or what a standing
# permission names, and nothing else
defect 'gate/hash' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if [ "$approved" != "$h" ]; then
EOF
  )" \
  '    if false; then' \
  'a draft edited after the user approved its card is published anyway'

defect 'gate/permission-exact-action' 'contrib.sh' \
  "$(
    cat <<'EOF'
grep -qxE "all|$2"
EOF
  )" \
  "$(
    cat <<'EOF'
grep -qE "all|$2"
EOF
  )" \
  'a permission for dcomment also lets a comment through, and any action whose name is inside a granted one'

defect 'gate/force-push-is-its-own-action' 'contrib.sh' \
  "action='force-push'" \
  'action=push' \
  'allow: push lets a force-push rewrite the branch without anyone approving it'

defect 'gate/unknown-word' 'contrib.sh' \
  "$(
    cat <<'EOF'
        fail "$f: allow names '$w', which is no action — the words are: $ACTIONS all"
EOF
  )" \
  '        continue' \
  'a misspelt permission is silently ignored, and the user believes something is granted or refused that is not'

defect 'gate/refused-draft-removed' 'contrib.sh' \
  "$(
    cat <<'EOF'
  if [ -n "$DRAFT_DIR" ] && [ "$KEEP" = 0 ]; then rm -rf "$DRAFT_DIR"; fi
EOF
  )" \
  "$(
    cat <<'EOF'
  if false; then rm -rf "$DRAFT_DIR"; fi
EOF
  )" \
  'a draft the lint refused for carrying a secret stays on disk, ready for a later send'

defect 'gate/approved-commit-not-branch' 'contrib.sh' \
  "$(
    cat <<'EOF'
args+=("$remote" "$sha:refs/heads/$branch")
EOF
  )" \
  "$(
    cat <<'EOF'
args+=("$remote" "HEAD:refs/heads/$branch")
EOF
  )" \
  'a commit made after the card is pushed along with the approved one'

defect 'gate/new-branch-created' 'contrib.sh' \
  "$(
    cat <<'EOF'
    api "$repo" git/refs -f "ref=refs/heads/$branch" -f "sha=$parent" >/dev/null || gh_fail $? "GitHub refused to create $branch"
EOF
  )" \
  '    true' \
  'an approved commit for a new branch fails after the approval, since the branch it goes on was never made'

# The world must not have moved between the card and the send
defect 'stale/push-tip' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$now" = "$tip" ] || stale "the tip of $branch"
EOF
  )" \
  '  true' \
  'a push lands over commits somebody else pushed after the card was shown'

defect 'stale/pr-head' 'contrib.sh' \
  "$(
    cat <<'EOF'
|| stale "the branch $(meta_get "$1" head)"
EOF
  )" \
  '|| true' \
  'a pull request proposes commits the user never saw on the card'

defect 'stale/edit-text' 'contrib.sh' \
  "$(
    cat <<'EOF'
  cmp -s "$TMP/now" "$1/current" || stale "the text of $what $n"
EOF
  )" \
  '  true' \
  "an edit overwrites a maintainer's change made after the card"

defect 'stale/commit-head' 'contrib.sh' \
  "$(
    cat <<'EOF'
    [ "$(jq -r '.object.sha' <<<"$head")" = "$parent" ] || stale "the head of $branch"
EOF
  )" \
  '    true' \
  'an API commit is attempted on a parent other than the one the diff was shown against'

# The lint
defect 'lint/secret' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if grep -qaE -- "$SECRET_ERE" "$f"; then
EOF
  )" \
  '    if false; then' \
  "a token pasted into a body is published under the user's name"

defect 'lint/artifacts' 'contrib.sh' \
  "$(
    cat <<'EOF'
RE=$ARTIFACT_ERE awk '$0 ~ ENVIRON["RE"]
EOF
  )" \
  "$(
    cat <<'EOF'
RE=$ARTIFACT_ERE awk '0
EOF
  )" \
  "an agent's session notes ride along in a pull request unflagged"

# Every call names its repository
defect 'repo/dupes-scope' 'contrib.sh' \
  "$(
    cat <<'EOF'
    [ "$anywhere" = 1 ] || args+=(--repo "$repo")
EOF
  )" \
  '    true' \
  'a duplicate search runs across all of GitHub and reports hits from unrelated projects as duplicates'

defect 'repo/login-code' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$1" != 6 ] || exit 6
EOF
  )" \
  '  true' \
  'a gh that is not logged in reads as a missing repository, and the agent chases the wrong fix'

# repo and dupes
defect 'repo/org-default' 'contrib.sh' \
  "$(
    cat <<'EOF'
    [ -z "$n" ] || printf '%s/.github:%s\n' "$owner" "$n"
EOF
  )" \
  '    true' \
  "an organisation-wide contributing guide goes unread, and its rules — a DCO, an AI policy — unfollowed"

defect 'repo/rename' 'contrib.sh' \
  "$(
    cat <<'EOF'
[ "$full" = "$repo" ] || printf 'renamed: %s answers as %s — use the new name\n' "$repo" "$name"
EOF
  )" \
  'true' \
  'a renamed repository is worked on under its old name, and links in the payload point at a redirect'

defect 'dupes/merge' 'contrib.sh' \
  'group_by(.url) | map(.[0] + {hits: length})' \
  'map(. + {hits: 1})' \
  'an item found by several phrasings is listed several times and ranked no higher than a stray hit'

# status: two independent axes, and the mark records what the server said
defect 'status/ci-axis' 'contrib.sh' \
  "$(
    cat <<'EOF'
(.updatedAt > $s.updatedAt or .state != $s.state or .ci != $s.ci)
EOF
  )" \
  "$(
    cat <<'EOF'
(.updatedAt > $s.updatedAt or .state != $s.state)
EOF
  )" \
  'CI turning red or green goes unreported, since finishing a run does not move updatedAt'

defect 'status/own-activity' 'contrib.sh' \
  "$(
    cat <<'EOF'
.[] | select(.user.login != $me and .updated_at > $s)
      | "  \(if .created_at
EOF
  )" \
  "$(
    cat <<'EOF'
.[] | select(.updated_at > $s)
      | "  \(if .created_at
EOF
  )" \
  'the user is told about their own comments as if a maintainer had answered'

defect 'status/mark-server-time' 'contrib.sh' \
  "$(
    cat <<'EOF'
jq -r '.[] | [.repo, .kind, .number, .updatedAt, .state, .ci] | @tsv'
EOF
  )" \
  "$(
    cat <<'EOF'
jq -r '.[] | [.repo, .kind, .number, (now | todate), .state, .ci] | @tsv'
EOF
  )" \
  'a comment that lands while status runs is marked seen without ever being shown'
