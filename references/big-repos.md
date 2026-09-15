# Big repositories

A full clone of nixpkgs, a kernel tree or a monorepo costs gigabytes and minutes for a change of one line. There are two ways around it, and which one fits is decided by a single question: does the change have to be built or tested here before it is proposed?

## No build needed: an API commit, with no clone

Documentation, a typo, a version string, a comment — anything whose correctness a reader sees in the diff. `contrib.sh draft commit` writes the change straight onto a branch of the user's fork through GitHub's GraphQL `createCommitOnBranch`:

```sh
contrib.sh draft commit rokokol/nixpkgs docs-fix --parent SHA --message msg.txt --put doc/manual/x.md=./x.md
```

The flags are in `contrib.sh help`. What matters here is what the card and the send guarantee: the card shows each file's diff against the parent, the approval binds the bytes, so a file edited after the card changes nothing that is sent, and the send refuses when the branch moved since the card, since the commit would otherwise land on a parent nobody looked at. A branch that does not exist yet is created at the parent by the send, and the card says so

The fork itself comes first, once: `gh repo fork OWNER/REPO --clone=false` creates it under the user's account, which is a publishing action like any other and waits for the user's yes

The endpoint accepts ordinary file contents but has no field for an executable bit, a symlink or a submodule, and every file travels base64-encoded inside one request, so those objects and large binaries belong on the other path

## A build or a test needed: a blobless clone and a worktree per pull request

Everything that has to compile, evaluate or pass a test. Clone once, without the file contents and without a checkout, and give each pull request a worktree of its own:

```sh
git clone --filter=blob:none --no-checkout https://github.com/NixOS/nixpkgs.git ~/Projects/nixpkgs-prs
git -C ~/Projects/nixpkgs-prs remote add fork https://github.com/rokokol/nixpkgs.git
git -C ~/Projects/nixpkgs-prs worktree add -b fix-thing /tmp/nixpkgs-fix-thing origin/master
```

- **`--filter=blob:none`** fetches the history and the trees but not the files, which arrive on demand as a worktree needs them; the repository stays a fraction of its full size
- **The gate cannot be fed from a blobless clone.** `contrib.sh draft push` reads the fork's advertised tips with `git cat-file -e`; in a `blob:none` repository a missing object triggers a lazy fetch from the promisor remote — here GitHub, the origin — which has no read timeout and hangs about as long as GitHub is slow
- **`--no-checkout`** leaves the clone itself without a working tree, so it is only ever a store for worktrees
- **One worktree per pull request** keeps branches apart without re-cloning, and `git worktree remove` clears one when its pull request is merged
- **A build that reads the whole tree fetches the whole tree.** `nix build` on nixpkgs evaluates far beyond the file that changed, so the first build downloads most blobs anyway; the saving is in the clone that sits idle between pull requests, not in that build

For the push through the gate use a clone that can answer locally instead of the blobless store: `git clone --depth 1 --no-tags --no-checkout <fork-url> /tmp/fix-thing`, apply the change there, then `contrib.sh draft push fork fix-thing --dir /tmp/fix-thing --new`: the clone sits on the fork's default branch rather than on `fix-thing`, so the first push, the one that creates the branch, says so, and every later push goes without `--new`

## Neither

A sparse checkout (`git sparse-checkout set PATH`) narrows a working tree to a few directories. It helps an editor and a search, but a build that needs files outside those directories fails in ways that are slow to diagnose, so it is not a third path here
