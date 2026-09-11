# Changelog

Kept in the shape of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), dated rather than numbered, and with no `Unreleased` section — a skill is read at whatever revision you have checked out, so whatever is on the default branch is what every reader already has, and a section for work that has landed but not shipped would never close. The rule lives in the [versioning](https://github.com/rokokol/versioning-skill) skill, which owns what has no version

## 2026-09-11

### Added

- the skill: one gate for everything published under the user's GitHub identity, taken over from the ai-commit-trailers skill and extended to the user's own repositories, with standing permissions per repository and per action in a private file
- `contrib.sh`, over `gh` and `jq`: `repo` for a project's contribution policy in one lookup, `dupes` for the duplicate search, `draft`, `drafts`, `drop` and `send` for the gate, `status` and `seen` for what changed on the user's own pull requests and issues, and `home` for where the private files live. Reviews and merges are bound to the head commit their card shows, and closing and reopening are drafted like everything else
- references on the private file, on composing an issue, a pull request, a discussion or a reply to a review, and on contributing to a repository too big to clone casually
