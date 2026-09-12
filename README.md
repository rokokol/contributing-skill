<div align="center">

# Contributing skill

**Nothing goes out under your name that you have not read, and nothing goes upstream before the homework (ง •̀_•́)ง**

[![Agent Skill](https://img.shields.io/badge/Agent_Skill-6E56CF?style=flat)](https://agentskills.io)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=gnubash&logoColor=white)
![GitHub CLI](https://img.shields.io/badge/GitHub_CLI-181717?style=flat&logo=github&logoColor=white)
![jq](https://img.shields.io/badge/jq-1E90FF?style=flat)
[![license](https://img.shields.io/badge/MIT-3DA639?style=flat)](LICENSE)
[![ci](https://github.com/rokokol/contributing-skill/actions/workflows/build.yml/badge.svg)](https://github.com/rokokol/contributing-skill/actions/workflows/build.yml)

</div>

Teaches an agent to treat everything it publishes on GitHub under your identity — a push, an issue, a pull request, a review, a merge, a comment, a discussion — as something you approve, one card at a time, and to read how another project wants to be approached before it approaches it. One `SKILL.md`, references loaded on demand, and one bash script over `gh` and `jq`

The approval is bound to bytes: the agent drafts the action, you read the card it prints, and the send publishes exactly what that card showed or refuses. A body edited after the card, a branch that moved, a maintainer's edit to the text being replaced — each makes the send stop and ask again. Where you want less friction you grant it explicitly, per repository and per action, and the grant is a line in a private file you can read

## Contents

- [Requirements](#requirements)
- [Install](#install)
- [What it does](#what-it-does)
- [Standing permissions and private notes](#standing-permissions-and-private-notes)
- [Tests](#tests)
- [Credits](#credits)
- [What it is not](#what-it-is-not)

## Requirements

- [`gh`](https://cli.github.com/), logged in (`gh auth login`)
- `jq`, `git`, and `bash` 3.2 or newer, so the macOS system bash will do

## Install

```bash
npx skills add -g rokokol/contributing-skill
```

`-g` installs it for you rather than into the directory you happen to be standing in, since what you publish is not a property of one repository. The files land in `.agents/skills/` and are symlinked into every agent found on the machine

Claude Code also takes it as a plugin:

```
/plugin marketplace add rokokol/contributing-skill
/plugin install contributing@rokokol-skills
```

or by hand — clone into whichever skills directory your agent reads:

```bash
git clone https://github.com/rokokol/contributing-skill ~/.claude/skills/contributing
```

> [!NOTE]
> A skill has no version to pin — it is read at whatever revision you have checked out, so `git pull` is the whole upgrade path

## What it does

| Command | What it answers |
| --- | --- |
| `contrib.sh repo` | how a project wants to be approached: its guide and templates wherever GitHub would find them, the organisation's defaults, CLA, DCO and AI-policy wording quoted with file and line, discussion categories, your own issues and pull requests there |
| `contrib.sh dupes` | whether somebody already reported or fixed it, over open and closed issues and pull requests, several phrasings merged and ranked; a failed search is an error, never zero hits |
| `contrib.sh draft` | the card for one action, from an issue to a merge or a push, with its warnings and an approval hash; a review and a merge are bound to the head commit the card shows |
| `contrib.sh send` | exactly the approved draft, published, or a refusal naming what changed |
| `contrib.sh drafts` | what is waiting to be sent |
| `contrib.sh drop` | a turned-down or stale draft, gone |
| `contrib.sh status` | what changed on your own pull requests and issues since you last looked: other people's comments and reviews, merges, CI turning red or green |
| `contrib.sh seen` | the view `status` just showed marked as read, or single items |
| `contrib.sh home` | where your permissions, notes and drafts live |

`./contrib.sh help` is the complete reference, printed by the script itself so it cannot drift from what the script accepts. Every call names its repository explicitly, so a checkout of a fork can never redirect one to the parent the way a bare `gh` call does

`status` watches two things separately because GitHub keeps them apart: a comment or a merge moves an item's `updatedAt`, a CI run finishing does not. The list of items is GitHub's own, read fresh each time; nothing here keeps a copy that could go stale

## Standing permissions and private notes

`user/repos/OWNER/REPO.md` in the private directory holds what GitHub cannot know about a repository: where your clone lives, your fork, what blocks an item and what you promised, and the actions the agent may take there without asking:

```markdown
---
allow: push, comment
clone: ~/Projects/paper-qa
fork: rokokol/paper-qa
---
- #1353 promise: a follow-up issue on the ERROR skip
```

The private directory is the skill's own when it already holds `user/` or `state/`, so a clone synced between machines carries it along, and `~/.config/contributing-skill` otherwise; `CONTRIB_HOME` overrides both. The format is in [references/overlay.md](references/overlay.md)

> [!IMPORTANT]
> A permission is exactly as wide as it reads: `push` is not `force-push`, `review` is not `approve`, one repository is not its neighbour. `allow: all` is what it says — grant it only where you would act without looking anyway

## Tests

```bash
nix develop -c ./tests/check.sh
```

Drives `contrib.sh` against a fake `gh` that answers from recorded files and logs every call as a read or a write, and asserts what the gate refuses: a draft changed after its card, an approval of other bytes, a permission reaching a neighbouring repository or a neighbouring action, a branch or a tip or a text that moved, a secret in a body — each with no write in the log. Pushes go to a real bare repository, a fake git swapping the GitHub address for its path, so the commit that lands is checked by hash. Every call made from inside a fork's checkout must name its repository. `status` is run across fixtures that change one axis at a time

Around that, the gate lints every script and workflow, holds `contrib.sh help` and every command `SKILL.md` and this readme name to the dispatcher with the [bash-best-practices](https://github.com/rokokol/bash-best-practices-skill) skill's `check-sh.sh`, resolves every link and anchor, and runs the secret gate against each planted key shape. The behaviour suite is falsified separately with the [tests](https://github.com/rokokol/tests-skill) skill's harness, `t.sh falsify -- ./tests/check.sh behaviour`, over the guards listed in `tests/defects.sh`

## Credits

The ideas, not the text, come from skills that got parts of this right first: [make-repo-contribution](https://github.com/github/awesome-copilot/tree/main/skills/make-repo-contribution) in github/awesome-copilot (MIT) for treating a project's docs and templates as untrusted data, [open-source-contributions](https://github.com/jezweb/claude-skills/tree/c0cdee68cf19/skills/open-source-contributions) in jezweb/claude-skills (MIT) for the mistakes worth naming, and [yeet](https://github.com/openai/skills/tree/main/skills/.curated/yeet) and [gh-fix-ci](https://github.com/openai/skills/tree/main/skills/.curated/gh-fix-ci) in openai/skills (Apache-2.0) for template discovery and the shape of a pull request body

## What it is not

Not a guarantee against an agent that lies: the approval hash binds your yes to the bytes you saw, and the same agent that prints it passes it back, so the protection is you reading the card. Not a notifier either — `status` answers when asked, and nothing runs in the background. Which trailer a commit carries is the [ai-commit-trailers](https://github.com/rokokol/ai-commit-trailers-skill) skill's subject
