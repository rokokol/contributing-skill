#!/usr/bin/env bash
# The defect list for this repository, read by the tests skill's harness, vendored beside
# it, and run by .github/workflows/falsify.yml:
#
#   tests/t.sh falsify -- ./tests/check.sh behaviour
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

defect 'gate/approve-is-its-own-action' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$kind" != review ] || [ "$(meta_get "$d" event)" != approve ] || action=approve
EOF
  )" \
  '  true' \
  "allow: review lets the agent approve someone's code in the user's name"

defect 'gate/unknown-word' 'contrib.sh' \
  "$(
    cat <<'EOF'
        fail "$f: allow names '$w', which is no action — the words are: $ACTIONS all"
EOF
  )" \
  '        continue' \
  'a misspelt permission is silently ignored, and the user believes something is granted or refused that is not'

defect 'gate/kind-flags' 'contrib.sh' \
  "$(
    cat <<'EOF'
    grep -qxF -- "$f" <<<"$allowed_flags" || die "draft $kind takes no $f — contrib.sh help"
EOF
  )" \
  '    true' \
  'a body given to a push, or --to given to a comment, is shown on the card and then never sent'

defect 'gate/newline-flag' 'contrib.sh' \
  "$(
    cat <<'EOF'
        case $2 in *$'\n'*) die "$1 must be one line" ;; esac
EOF
  )" \
  '        true' \
  'a value spanning two lines reaches GitHub before anything refuses it'

defect 'gate/meta-one-line' 'contrib.sh' \
  "$(
    cat <<'EOF'
  case $2 in *$'\n'*) die "$1 must be one line" ;; esac
  printf '%s=%s\n' "$1" "$2" >>"$DRAFT_DIR/meta"
EOF
  )" \
  "$(
    cat <<'EOF'
  printf '%s=%s\n' "$1" "$2" >>"$DRAFT_DIR/meta"
EOF
  )" \
  "a value read from the API with a newline in it writes a second line into the draft's meta, which a later read takes for another field"

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

defect 'gate/claim' 'contrib.sh' \
  "$(
    cat <<'EOF'
  mv "$DRAFTS/$id" "$DRAFTS/.sending-$id" 2>/dev/null || fail "$id is being sent by another run"
EOF
  )" \
  "$(
    cat <<'EOF'
  cp -R "$DRAFTS/$id" "$DRAFTS/.sending-$id"
EOF
  )" \
  'a draft stays sendable while it is being sent, so a second send publishes it again'

defect 'gate/drafts-no-hash' 'contrib.sh' \
  "$(
    cat <<'EOF'
      *) printf '%s  %s  %s\n' "${d##*/}" "$(meta_get "$d" kind)" "$(meta_get "$d" repo)" ;;
EOF
  )" \
  "$(
    cat <<'EOF'
      *) printf '%s  %s  %s  %s\n' "${d##*/}" "$(meta_get "$d" kind)" "$(meta_get "$d" repo)" "$(draft_hash "$d")" ;;
EOF
  )" \
  'an agent reading the list of drafts holds an approval token without the user ever seeing a card'

defect 'gate/approved-commit-not-branch' 'contrib.sh' \
  "$(
    cat <<'EOF'
args+=("$effective" "$sha:refs/heads/$branch")
EOF
  )" \
  "$(
    cat <<'EOF'
args+=("$effective" "HEAD:refs/heads/$branch")
EOF
  )" \
  'a commit made after the card is pushed along with the approved one'

defect 'gate/no-follow-tags' 'contrib.sh' \
  '  args=(push --porcelain --no-follow-tags --recurse-submodules=no)' \
  '  args=(push --porcelain --recurse-submodules=no)' \
  "the user's push.followTags publishes tags nobody saw on the card"

defect 'gate/no-submodules' 'contrib.sh' \
  '  args=(push --porcelain --no-follow-tags --recurse-submodules=no)' \
  '  args=(push --porcelain --no-follow-tags)' \
  "the user's push.recurseSubmodules pushes submodule commits to other repositories"

defect 'push/tracking-follows' 'contrib.sh' \
  "$(
    cat <<'EOF'
    git -C "$dir" update-ref -m "contrib.sh: push" "refs/remotes/$remote/$branch" "$sha" ||
EOF
  )" \
  '    true ||' \
  'git status keeps calling a pushed branch ahead of the remote that already has it' \
  expect caught 'did not follow an approved push'

defect 'push/tracking-same-address' 'contrib.sh' \
  "$(
    cat <<'EOF'
    [ "$(git -C "$dir" remote get-url "$remote" 2>/dev/null)" = "$effective" ]; then
EOF
  )" \
  '    true; then' \
  'a push git sent to another address moves the tracking branch of a remote that never received it' \
  expect caught 'moved the tracking branch of a remote that never received it'

defect 'push/tracking-stock-refspec' 'contrib.sh' \
  "$(
    cat <<'EOF'
  if [ "$(git -C "$dir" config --get-all "remote.$remote.fetch" 2>/dev/null)" = "+refs/heads/*:refs/remotes/$remote/*" ] &&
EOF
  )" \
  '  if true &&' \
  "a push moves a tracking branch the remote's fetch refspec does not map" \
  expect caught 'fetch refspec does not map'

defect 'gate/hash-binds-id' 'contrib.sh' \
  "$(
    cat <<'EOF'
    printf '%s\0' "$2"
    cat "$d/meta"
EOF
  )" \
  "$(
    cat <<'EOF'
    cat "$d/meta"
EOF
  )" \
  'the approval of one card sends a later draft with the same bytes, whose card nobody saw'

defect 'gate/writing-marker' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if [ -e "$CLAIMED/.writing" ]; then
EOF
  )" \
  '    if false; then' \
  'a send that failed after GitHub took it is handed back, and the next send posts it twice'

defect 'recovery/interrupted-guidance' 'contrib.sh' \
  "$(
    cat <<'EOF'
  printf "contrib.sh: recovery: check GitHub for the card's destination; report whether it landed; only then run contrib.sh drop %s; never send this draft again\n" "$1" >&2
EOF
  )" \
  '  true' \
  'an interrupted send leaves the agent without the safe recovery procedure' \
  expect caught 'interrupted write says how to recover'

defect 'recovery/drafts-guidance' 'contrib.sh' \
  "$(
    cat <<'EOF'
        printf '%s  interrupted — check GitHub, report whether it landed, then contrib.sh drop %s; never send again\n' "$id" "$id"
EOF
  )" \
  "        printf '%s  interrupted\n' \"\$id\"" \
  'the draft list identifies an interrupted send but does not prevent a blind retry' \
  expect caught 'not listed as interrupted'

defect 'recovery/lint-guidance' 'contrib.sh' \
  "$(
    cat <<'EOF'
      printf 'contrib.sh: if this is a false positive, follow references/recovery.md#false-positive-secret-lint beside contrib.sh; never weaken the scanner\n' >&2
EOF
  )" \
  '      true' \
  'a false-positive secret lint has no safe exceptional path and invites weakening the scanner' \
  expect caught 'false-positive lint has one recovery procedure'

defect 'gate/multi-pushurl' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$(printf '%s\n' "$all" | wc -l | tr -d ' ')" = 1 ] || fail "$2 has several push addresses, and one card cannot name where the push goes"
EOF
  )" \
  '  true' \
  'the card names one repository while git pushes to several'

defect 'push/range-known' 'contrib.sh' \
  "$(
    cat <<'EOF'
      if git -C "$abs" cat-file -e "$adv^{commit}" 2>/dev/null; then known+=("$adv"); fi
EOF
  )" \
  '      true' \
  "a new branch's card lists, and its lint reads, commits the remote already has"

defect 'push/new-branch-said' 'contrib.sh' \
  "$(
    cat <<'EOF'
  elif [ "$cur" != "$branch" ] && [ "$new" = 0 ]; then
EOF
  )" \
  '  elif false; then' \
  'master typed for main creates a stray branch under a standing permission, and no person sees the card saying it is new'

defect 'push/new-only-creates' 'contrib.sh' \
  "$(
    cat <<'EOF'
    [ "$new" = 0 ] || fail "--new creates a branch, and $remote has $branch already"
EOF
  )" \
  '    true' \
  '--new passes on every push, and then says nothing when it is passed on the one that creates a branch by a slip'

defect 'push/default-detached' 'contrib.sh' \
  "$(
    cat <<'EOF'
    [ -n "$cur" ] || die "the checkout is on no branch, so name the BRANCH to push to"
EOF
  )" \
  '    true' \
  'a push with no branch from a detached checkout drafts a card for a branch with no name'

defect 'push/default-upstream-name' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if [ -n "$merge" ] && [ "$(git -C "$abs" config --get "branch.$cur.remote" || true)" = "$remote" ] && [ "$merge" != "refs/heads/$cur" ]; then
EOF
  )" \
  '    if false; then' \
  'a branch that pulls from another name on that remote is pushed under its own, beside the branch the user integrates'

defect 'push/default-upstream-remote' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if [ -n "$merge" ] && [ "$(git -C "$abs" config --get "branch.$cur.remote" || true)" = "$remote" ] && [ "$merge" != "refs/heads/$cur" ]; then
EOF
  )" \
  "$(
    cat <<'EOF'
    if [ -n "$merge" ] && [ "$merge" != "refs/heads/$cur" ]; then
EOF
  )" \
  "a branch that pulls from upstream's main is refused a push to the user's fork, which git push's default lets through"

defect 'repo/show-path' 'contrib.sh' \
  "$(
    cat <<'EOF'
    show=$(path_arg --show "$show") || exit $?
EOF
  )" \
  '    true' \
  "--show climbs out of the repository's contents into other endpoints under the user's token"

defect 'reply/thread' 'contrib.sh' \
  "$(
    cat <<'EOF'
    *) fail "review comment $to is not on $repo#$n" ;;
EOF
  )" \
  '    *) ;;' \
  'a reply goes into a thread of another pull request than the card names'

defect 'gate/lease' 'contrib.sh' \
  "$(
    cat <<'EOF'
args+=("--force-with-lease=refs/heads/$branch:$tip")
EOF
  )" \
  'args+=(--force)' \
  'a forced push lands over a commit pushed in the instant between the tip check and the push'

defect 'push/range-only-destination' 'contrib.sh' \
  "$(
    cat <<'EOF'
    range=("$sha" --not ${known[@]+"${known[@]}"})
EOF
  )" \
  "$(
    cat <<'EOF'
    range=("$sha" --not --remotes ${known[@]+"${known[@]}"})
EOF
  )" \
  "another remote's history, a private origin's, goes out to the destination without the card listing or the lint reading it"

defect 'push/refused-handback' 'contrib.sh' \
  "$(
    cat <<'EOF'
      rm -f "$CLAIMED/.writing"
EOF
  )" \
  '      true' \
  'a push git refused is left as interrupted, and the user is sent to look for something that never landed'

defect 'push/fixed-point' 'contrib.sh' \
  "$(
    cat <<'EOF'
    fail "git would rewrite $effective again, by $rule, so no card can name where this push goes — untangle the url.*.insteadOf rules"
EOF
  )" \
  '    true' \
  'a chained rewrite sends the push to a third address the card never named'

defect 'pr/fork-check' 'contrib.sh' \
  "$(
    cat <<'EOF'
      fail "$fork is not a fork of $repo — set fork: in the overlay to the fork $head lives in"
EOF
  )" \
  '      true' \
  'a same-named repository outside the network binds the card to a branch nobody proposes'

defect 'perm/close-comment' 'contrib.sh' \
  "$(
    cat <<'EOF'
  case $kind in close | reopen) [ ! -s "$d/body" ] || also=comment ;; esac
EOF
  )" \
  '  true' \
  'allow: close posts a comment the user never granted'

defect 'perm/edit-own' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$kind" != edit ] || [ "$(meta_get "$d" mine)" = 1 ] || permit=0
EOF
  )" \
  '  true' \
  "allow: edit rewrites somebody else's comment or description with the user's maintainer rights"

defect 'lint/header-only' 'contrib.sh' \
  "$(
    cat <<'EOF'
  awk '{ header = (prev ~ /^--- / && $0 ~ /^\+\+\+ /); prev = $0 } header { next } /^(\+|[ +]\+)/'
EOF
  )" \
  "$(
    cat <<'EOF'
  awk '/^\+\+\+ / { next } /^(\+|[ +]\+)/'
EOF
  )" \
  'a secret on an added line whose text starts with "++" is never read'

defect 'lint/c1' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if LC_ALL=C grep -q "$(printf '\302')[$(printf '\200')-$(printf '\237')]" "$f"; then
EOF
  )" \
  '    if false; then' \
  'a C1 control goes out unflagged'

defect 'show/visible' 'contrib.sh' \
  "$(
    cat <<'EOF'
    visible "$TMP/show"
EOF
  )" \
  "$(
    cat <<'EOF'
    cat "$TMP/show"
EOF
  )" \
  'an upstream file redraws the fence for the person watching the terminal'

defect 'commit/ref-format' 'contrib.sh' \
  "$(
    cat <<'EOF'
      git check-ref-format --branch "${pos[1]}" >/dev/null 2>&1 || die "not a branch name: ${pos[1]}"
EOF
  )" \
  '      true' \
  'a branch name GitHub refuses fails only after the write began, and the send is left interrupted'

defect 'gate/rewrite-no-permission' 'contrib.sh' \
  "$(
    cat <<'EOF'
  elif [ "$target" != "$repo" ]; then
EOF
  )" \
  '  elif false; then' \
  'a standing permission for one repository lets a push through that git rewrites to another'

defect 'gate/new-branch-created' 'contrib.sh' \
  "$(
    cat <<'EOF'
    api "$repo" git/refs -f "ref=refs/heads/$branch" -f "sha=$parent" >/dev/null || gh_fail $? "GitHub refused to create $branch"
EOF
  )" \
  '    true' \
  'an approved commit for a new branch fails after the approval, since the branch it goes on was never made'

defect 'gate/review-commit-id' 'contrib.sh' \
  "$(
    cat <<'EOF'
  args=("pulls/$n/reviews" -f "commit_id=$sha" -f "event=$event")
EOF
  )" \
  "$(
    cat <<'EOF'
  args=("pulls/$n/reviews" -f "event=$event")
EOF
  )" \
  'an approval lands on whatever the head is when GitHub receives it, not on the commit the user reviewed'

defect 'gate/merge-match-head' 'contrib.sh' \
  "$(
    cat <<'EOF'
--match-head-commit "$sha" >/dev/null ||
EOF
  )" \
  '>/dev/null ||' \
  'a merge takes in a commit that lands between the check and the merge'

# The world must not have moved between the card and the send
defect 'stale/push-tip' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$now" = "$tip" ] || stale "the tip of $branch"
EOF
  )" \
  '  true' \
  'a push lands over commits somebody else pushed after the card was shown'

defect 'stale/push-address' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$urls" = "$url"$'\n'"$effective" ] || stale "the address of $remote"
EOF
  )" \
  '  true' \
  'a remote pointed elsewhere after the card takes the approved commit to a repository nobody named'

defect 'stale/pr-head' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$now" = "$(meta_get "$1" head_sha)" ] || stale "the branch $head"
EOF
  )" \
  '  true' \
  'a pull request proposes commits the user never saw on the card'

defect 'stale/review-head' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$now" = "$sha" ] || stale "the head of $repo#$n, reviewed"
EOF
  )" \
  '  true' \
  'a review of commits the user saw goes out after the author pushed others'

defect 'stale/merge-head' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$now" = "$sha" ] || stale "the head of $repo#$n, to be merged"
EOF
  )" \
  '  true' \
  'a merge is attempted for a head nobody looked at, and fails only on GitHub instead of here'

defect 'stale/state' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ "$now" = "$(meta_get "$1" was)" ] || stale "the state of $repo#$n"
EOF
  )" \
  '  true' \
  'an issue somebody reopened is closed again over their decision'

defect 'stale/edit-text' 'contrib.sh' \
  "$(
    cat <<'EOF'
  cmp -s "$TMP/now" "$1/current" || stale "the text of $what $n"
EOF
  )" \
  '  true' \
  "an edit overwrites a maintainer's change made after the card"

defect 'stale/edit-title' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ -z "$title" ] || cmp -s "$TMP/now_title" "$1/current_title" || stale "the title of $what $n"
EOF
  )" \
  '  true' \
  "a title a maintainer changed after the card is overwritten unseen"

defect 'stale/commit-head' 'contrib.sh' \
  "$(
    cat <<'EOF'
    [ "$(jq -r '.object.sha' <<<"$head")" = "$parent" ] || stale "the head of $branch"
EOF
  )" \
  '    true' \
  'an API commit is attempted on a parent other than the one the diff was shown against'

# The lint and the card
defect 'lint/secret' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if grep -qaE -- "$SECRET_ERE" "$f"; then
EOF
  )" \
  '    if false; then' \
  "a token pasted into a body is published under the user's name"

defect 'lint/local-path-temporary' 'contrib.sh' \
  "$(
    cat <<'EOF'
LOCAL_PATH_ERE='(/home/|/Users/)[^[:space:]")]+|(/private)?/(tmp|var/tmp)/[^[:space:]")/]+/[^[:space:]")]+|(/private)?/var/folders/[^[:space:]")]+'
EOF
  )" \
  "$(
    cat <<'EOF'
LOCAL_PATH_ERE='(/home/|/Users/)[^[:space:]")]+'
EOF
  )" \
  'the rule sees only an agent that works under the home. A path in a temporary session directory goes out in a body, and no reader can follow it'

defect 'lint/local-path-over-matches' 'contrib.sh' \
  "$(
    cat <<'EOF'
LOCAL_PATH_ERE='(/home/|/Users/)[^[:space:]")]+|(/private)?/(tmp|var/tmp)/[^[:space:]")/]+/[^[:space:]")]+|(/private)?/var/folders/[^[:space:]")]+'
EOF
  )" \
  "$(
    cat <<'EOF'
LOCAL_PATH_ERE='(/home/|/Users/)[^[:space:]")]+|(/private)?/(tmp|var/tmp)/[^[:space:]")]+|(/private)?/var/folders/[^[:space:]")]+'
EOF
  )" \
  'every temporary path a reproduction tells the reader to write raises a warning. A warning that fires on correct text teaches the user to read past the whole block'

defect 'lint/push' 'contrib.sh' \
  "$(
    cat <<'EOF'
  lint "$TMP/pushed"
EOF
  )" \
  '  true' \
  'a token in a commit message is pushed'

defect 'lint/commit-files' 'contrib.sh' \
  "$(
    cat <<'EOF'
  lint "$DRAFT_DIR"/files/*
EOF
  )" \
  '  true' \
  'a token in a file an API commit writes is committed'

defect 'lint/patches' 'contrib.sh' \
  "$(
    cat <<'EOF'
  lint "$TMP/patches"
EOF
  )" \
  '  true' \
  "a token in a pull request's diff is proposed upstream"

defect 'lint/artifacts-pr' 'contrib.sh' \
  "$(
    cat <<'EOF'
jq -r '.files[].filename' <<<"$cmp" | RE=$ARTIFACT_ERE awk '$0 ~ ENVIRON["RE"]
EOF
  )" \
  "$(
    cat <<'EOF'
jq -r '.files[].filename' <<<"$cmp" | RE=$ARTIFACT_ERE awk '0
EOF
  )" \
  "an agent's session notes ride along in a pull request unflagged"

defect 'lint/artifacts-push' 'contrib.sh' \
  "$(
    cat <<'EOF'
  RE=$ARTIFACT_ERE awk '$0 ~ ENVIRON["RE"] { print "warning: a session artifact in the diff — " $0 }' "$TMP/names"
EOF
  )" \
  '  true' \
  "an agent's session notes are pushed to the user's own repository unflagged"

defect 'lint/control' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if LC_ALL=C grep -q "[$(printf '\001-\010\013-\037\177')]" "$f"; then
EOF
  )" \
  '    if false; then' \
  'an escape sequence makes the card read differently from what is sent, and nothing says so'

defect 'card/visible' 'contrib.sh' \
  "$(
    cat <<'EOF'
    script="${script}s/$(printf '%b' "\\0$(printf '%03o' "$i")")/<$(printf '%02X' "$i")>/g;"
EOF
  )" \
  "$(
    cat <<'EOF'
    script="$script"
EOF
  )" \
  'the terminal obeys an escape in the body, so the user reads something other than the bytes'

defect 'lint/bidi' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if LC_ALL=C grep -qE "$(printf '\342\200[\252-\256]|\342\201[\246-\251]')" "$f"; then
EOF
  )" \
  '    if false; then' \
  'text that displays in another order than it is stored goes out unflagged'

defect 'lint/invisible' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if LC_ALL=C grep -qE "$(printf '\342\200[\213-\217]|\342\201[\240-\244]|\357\273\277|\363\240[\200\201]')" "$f"; then
EOF
  )" \
  '    if false; then' \
  'text nobody can see rides along in a body the user approved'

defect 'lint/added-only-pr' 'contrib.sh' \
  "$(
    cat <<'EOF'
  jq -r '.files[].patch // empty' <<<"$cmp" | added_lines >"$TMP/patches"
EOF
  )" \
  "$(
    cat <<'EOF'
  jq -r '.files[].patch // empty' <<<"$cmp" >"$TMP/patches"
EOF
  )" \
  'a pull request that takes a leaked token out is refused as leaking it, and the fix cannot go through the gate'

defect 'lint/added-only-push' 'contrib.sh' \
  "$(
    cat <<'EOF'
"${range[@]}" | added_lines >>"$TMP/pushed"
EOF
  )" \
  "$(
    cat <<'EOF'
"${range[@]}" >>"$TMP/pushed"
EOF
  )" \
  'a push that takes a leaked token out is refused as leaking it'

defect 'push/diff-drivers' 'contrib.sh' '--no-ext-diff --no-textconv --text --no-color ' '' \
  "the user's diff driver or textconv decides what the lint reads, and a file .gitattributes calls binary is skipped"

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

# repo. The listing fixture holds CLAUDEXmd, which only a pattern that lost the backslash in
# claude\.md matches — and every awk but mawk drops it from a -v value, most of them without
# a warning, so the whole-line check on the agent files is what must notice
defect 'repo/regex-through-v' 'contrib.sh' \
  "$(
    cat <<'EOF'
  printf '%s\n' "$3" | RE="^($2)\$" awk -v t="$1" '
    $1 == t { n = substr($0, length(t) + 2); if (tolower(n) ~ ENVIRON["RE"]) printf
EOF
  )" \
  "$(
    cat <<'EOF'
  printf '%s\n' "$3" | awk -v re="^($2)\$" -v t="$1" '
    $1 == t { n = substr($0, length(t) + 2); if (tolower(n) ~ re) printf
EOF
  )" \
  "a file that merely resembles CLAUDE.md or AGENTS.md is presented as the project's instructions to agents" \
  expect caught 'agent instructions'

defect 'repo/fence-nonce' 'contrib.sh' \
  "$(
    cat <<'EOF'
    fence=$(nonce)
EOF
  )" \
  "    fence=''" \
  "an upstream file closes the untrusted fence itself, and what follows reads as the script's own output"

defect 'repo/unreadable' 'contrib.sh' \
  "$(
    cat <<'EOF'
  elif ! not_found; then
    unreadable "the listing of $1${2:+/$2}"
EOF
  )" \
  "$(
    cat <<'EOF'
  elif false; then
    unreadable "the listing of $1${2:+/$2}"
EOF
  )" \
  'a listing that failed reads as a project with no contributing guide, and its rules go unfollowed'

defect 'repo/org-default' 'contrib.sh' \
  "$(
    cat <<'EOF'
    [ -z "$n" ] || printf '%s/.github:%s\n' "$owner" "$n"
EOF
  )" \
  '    true' \
  "an organisation-wide contributing guide goes unread, and its rules — a DCO, an AI policy — unfollowed"

defect 'repo/org-templates' 'contrib.sh' \
  "$(
    cat <<'EOF'
  if [ -z "$tpls$legacy" ]; then
    org
EOF
  )" \
  "$(
    cat <<'EOF'
  if false; then
    org
EOF
  )" \
  "an organisation's issue forms go unused, and the issue is written in a shape its maintainers close"

defect 'repo/config-comment' 'contrib.sh' 'sub(/#.*/, "", v); ' '' \
  'a comment after blank_issues_enabled hides that the project takes no blank issues'

defect 'repo/rename' 'contrib.sh' \
  "$(
    cat <<'EOF'
[ "$full" = "$repo" ] || printf 'renamed: %s answers as %s — use the new name\n' "$repo" "$name"
EOF
  )" \
  'true' \
  'a renamed repository is worked on under its old name, and links in the payload point at a redirect'

defect 'commit/only-404-is-new' 'contrib.sh' \
  "$(
    cat <<'EOF'
    elif not_found; then
      extra "new file: $path"
EOF
  )" \
  "$(
    cat <<'EOF'
    elif true; then
      extra "new file: $path"
EOF
  )" \
  'a file whose read failed is shown as new, and the commit overwrites it unseen'

defect 'dupes/merge' 'contrib.sh' \
  'group_by(.url) | map(.[0] + {hits: length})' \
  'map(. + {hits: 1})' \
  'an item found by several phrasings is listed several times and ranked no higher than a stray hit'

# status: two independent axes, open items plus the ones that left, and the mark records
# what the server said and the user saw
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

defect 'status/missing-items' 'contrib.sh' \
  "$(
    cat <<'EOF'
    if item=$(item_json "${key%#*}" "${key##*#}"); then
EOF
  )" \
  '    if false; then' \
  'a merge or a close is never reported, since a closed item leaves the open lists'

defect 'status/own-activity' 'contrib.sh' \
  "$(
    cat <<'EOF'
add // [] | .[] | select(.user.login != $me and .updated_at > $s)
      | "  \(if .created_at
EOF
  )" \
  "$(
    cat <<'EOF'
add // [] | .[] | select(.updated_at > $s)
      | "  \(if .created_at
EOF
  )" \
  'the user is told about their own comments as if a maintainer had answered'

defect 'status/only' 'contrib.sh' \
  "$(
    cat <<'EOF'
  [ -z "$only" ] || items=$(jq -c --arg r "$only" 'map(select(.repo == $r))' <<<"$items")
EOF
  )" \
  '  true' \
  'status for one repository reports every other one too'

defect 'status/view' 'contrib.sh' \
  "$(
    cat <<'EOF'
    mark_items "$(cat "$VIEW")"
EOF
  )" \
  '    mark_items "[]"' \
  'marking what was read marks nothing, and the same news is reported again'

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
