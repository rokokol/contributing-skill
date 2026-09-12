# The private overlay

GitHub already knows every pull request and issue the user opened, with its repository and its state, so no file here copies that. What the overlay keeps is what GitHub cannot know: where the work lives on this machine, what the user allowed, what blocks an item, and what was promised to whom. One file per repository, written by hand — by the agent with the file tools, so every change is a diff the user sees — and only ever read by `contrib.sh`

## Where it lives

`contrib.sh home` prints the private directory: `$CONTRIB_HOME` when set, the skill's own directory when it already holds `user/` or `state/`, and `$XDG_CONFIG_HOME/contributing-skill` otherwise. The skill's directory is the right home for a clone synced between machines, since the notes travel with it; the XDG directory is the right home for an install a plugin update replaces whole. The repository's `.gitignore` holds `user/` and `state/`, and its secret gate fails if either is ever tracked

## One repository's file

`user/repos/OWNER/REPO.md`, lowercase, since GitHub matches names without regard to case:

```markdown
---
allow: push, comment
clone: ~/Projects/paper-qa
fork: rokokol/paper-qa
---
- no CLA, no pull request template; the tests need LD_LIBRARY_PATH for pip wheels
- #1352 branch docs/ollama-chat-tool-calling
- #1353 promise: a follow-up issue on the ERROR skip in SearchIndex.filecheck
- #1354 blocked: waiting for the user to sign the CLA
```

- **The header** is flat `key: value` lines between `---` fences, read line by line rather than as YAML
- **`allow`** lists the actions `send` may take without an approval, separated by commas; the words are in `contrib.sh help`, and a word that is no action is an error rather than a silent miss
- **`clone`** is where the work lives, written with `~/` so the line holds on every host; `contrib.sh repo` says when it is absent on this one
- **`fork`** is the user's fork, where a pull request's head branch lives; it matters when the fork is not named after the upstream, since `contrib.sh draft pr` guesses that name otherwise. A push goes by the git remote, never by this line
- **The body** is free text, shown whole by `contrib.sh repo`. A line opening with `- #N ` belongs to item N, and one carrying `blocked:` or `promise:` is shown under that item by `contrib.sh status`

## What never goes in it

A state GitHub holds — open, merged, reviewed, green — goes stale the day after it is written, and GitHub is one call away. A token never goes in either: `gh` holds the login

## Machine state

`contrib.sh` writes its own files under `state/` and nowhere else: `state/drafts/ID/` for a draft waiting on its approval, `state/sent/ID/` for what was published, with the address it landed at, `state/seen/OWNER/REPO.tsv` for what `seen` or `status --mark` last recorded, and `state/view.json` for the last view `status` showed, which a bare `seen` marks. One file per repository keeps a Syncthing conflict small, and `status` says when one has left a conflict copy behind. A send in flight holds its draft as `state/drafts/.sending-ID/`, and one left there by a send that failed mid-write is an interrupted send, to be checked on GitHub before it is dropped. Send a draft from the host that drafted it: claiming a draft by renaming it is atomic on one filesystem, not across two that Syncthing keeps in step
