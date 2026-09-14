# Changelog

Kept in the shape of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), dated rather than numbered, and with no `Unreleased` section — a skill is read at whatever revision you have checked out, so whatever is on the default branch is what every reader already has, and a section for work that has landed but not shipped would never close. The rule lives in the [versioning](https://github.com/rokokol/versioning-skill) skill, which owns what has no version

## 2026-09-15

### Fixed

- the big-repositories reference no longer feeds the push gate from a `--filter=blob:none` clone: the gate's tip scan (`git cat-file -e`) lazy-fetches a missing object from the promisor remote with no read timeout and hangs once GitHub is slow, so the push step now directs to a shallow clone of the fork that answers locally

## 2026-09-12

### Added

- a recovery reference for stale drafts, interrupted sends and proven false-positive secret lint, with the script now printing the safe next action when one occurs

### Changed

- a push counts, lists and lints every commit the destination does not have, including one another remote's tracking branch holds, instead of leaving such commits off the card
- a standing permission to close or reopen with a comment also needs `comment`, and one to edit covers only the user's own text
- a push whose address git would rewrite again is refused, and one that git or the lease turned down goes back to the drafts rather than being left as interrupted, the lease's refusal as stale
- a pull request's head has to live in a fork of the repository it is proposed to
- the card and `repo --show` show every C1 control as `<C1>`, and the lint warns on one

### Fixed

- an API commit builds its whole payload from files before anything is written, so a large commit no longer fails after its branch was created, and a failed encoding can no longer commit empty files
- a secret on an added line whose text starts with `++` was not linted, nor one in a file `.gitattributes` calls binary
- a branch name with a `#` or a `?` in an API commit read the wrong ref, and one git refuses is now refused before anything is sent
- after a push, `git status` no longer calls the branch ahead of a remote that has it: the remote's tracking branch follows the pushed commit, where the remote's stock fetch refspec mirrors the very address the push went to

## 2026-09-11

### Added

- the skill: one gate for everything published under the user's GitHub identity, taken over from the ai-commit-trailers skill and extended to the user's own repositories, with standing permissions per repository and per action in a private file
- `contrib.sh`, over `gh` and `jq`: `repo` for a project's contribution policy in one lookup, `dupes` for the duplicate search, `draft`, `drafts`, `drop` and `send` for the gate, `status` and `seen` for what changed on the user's own pull requests and issues, and `home` for where the private files live. Reviews and merges are bound to the head commit their card shows, and closing and reopening are drafted like everything else
- references on the private file, on composing an issue, a pull request, a discussion or a reply to a review, and on contributing to a repository too big to clone casually
