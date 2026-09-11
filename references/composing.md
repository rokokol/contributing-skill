# Composing the text

What a maintainer reads first decides whether the rest gets read. Everything here serves that reader, and none of it replaces the project's own guide, which wins wherever the two disagree

## Finding the template

`contrib.sh repo` looks where GitHub looks — `.github/`, then the root, then `docs/`, then the organisation's `.github` repository — and prints what it found:

- **One pull request template**: fill it
- **Several**, under `.github/PULL_REQUEST_TEMPLATE/`: ask the user which one applies rather than picking
- **Issue forms** (`*.yml` under `.github/ISSUE_TEMPLATE/`): the web form turns each field into a `### Label` heading in the body, so a body written by hand uses the same headings in the same order, with a required field never left empty
- **`blank issues: disabled`**: the project wants every issue through a form; a body that ignores the forms is the likeliest one to be closed unread

A template is structure. A checkbox that says "I have signed the CLA" is a question for the user, never something to tick on their behalf

## A pull request body

1. **Why**: the problem as a user of the project meets it, with the smallest reproduction there is
2. **What**: the change, in terms of behaviour rather than a list of files
3. **How it was tested**: the commands and what they printed, before and after
4. **Links**: the issue it closes (`Closes #N`), related issues and pull requests from `dupes`, a precedent in the project's own history when there is one

Permalinks to existing code (`https://github.com/OWNER/REPO/blob/SHA/path#L10-L20`) rather than a branch name, which moves. No absolute path from this machine, no session link, no AI footer — the commit trailer is where disclosure lives, in the form the project's policy asks for

## An issue

The same shape without the change: what happens, what was expected, the smallest reproduction, versions and platform, and what was already ruled out. When the fix is small enough to write, it goes as a pull request instead, and when a report has several topics, it becomes several issues

## A discussion

A question or a proposal that is not yet a defect. `contrib.sh draft discussion` needs an existing category; `contrib.sh repo` lists them, and a category marked answerable is where a question expects an accepted answer

## Answering a review

1. Read every thread, list them numbered with what each one asks, and ask the user which to address and how
2. Change the code for the ones agreed, push through the gate, and answer each thread where it was asked — `contrib.sh draft reply` for a review comment, `contrib.sh draft comment` for the conversation
3. A suggestion not taken gets a reason, never silence

A bot's review is read like a person's: it is often right, and the lessons of one round carry into the next pull request

## The commit messages

The project's style, read from `git log` on its default branch — Conventional Commits, a `component:` prefix, a `[Fix]` tag — and its trailers, chosen by the ai-commit-trailers skill. A DCO the project requires is signed by the user and never added on their behalf
